import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/lab_settings.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsArguments {
  SettingsArguments(this.account);

  final Account account;
}

class Settings extends StatefulWidget {
  static const routeName = "/settings";

  static Route buildRoute(SettingsArguments args) => MaterialPageRoute(
        builder: (context) => Settings.fromArgs(args),
      );

  Settings({
    Key? key,
    required this.account,
  }) : super(key: key);

  Settings.fromArgs(SettingsArguments args, {Key? key})
      : this(
          account: args.account,
        );

  @override
  createState() => _SettingsState();

  final Account account;
}

class _SettingsState extends State<Settings> {
  @override
  initState() {
    super.initState();
    _isEnableExif = Pref.inst().isEnableExifOr();
  }

  @override
  build(context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: (context) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final translator = L10n.of(context).translator;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.of(context).settingsWidgetTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              ListTile(
                title: Text(L10n.of(context).settingsLanguageTitle),
                subtitle: Text(language_util.getSelectedLanguageName(context)),
                onTap: () => _onLanguageTap(context),
              ),
              SwitchListTile(
                title: Text(L10n.of(context).settingsExifSupportTitle),
                subtitle: _isEnableExif
                    ? Text(L10n.of(context).settingsExifSupportTrueSubtitle)
                    : null,
                value: _isEnableExif,
                onChanged: (value) => _onExifSupportChanged(context, value),
              ),
              _buildCaption(
                  context, L10n.of(context).settingsAboutSectionTitle),
              ListTile(
                title: Text(L10n.of(context).settingsVersionTitle),
                subtitle: const Text(k.versionStr),
                onTap: () => _onVersionTap(context),
              ),
              ListTile(
                title: Text(L10n.of(context).settingsSourceCodeTitle),
                subtitle: Text(_sourceRepo),
                onTap: () async {
                  await launch(_sourceRepo);
                },
              ),
              ListTile(
                title: Text(L10n.of(context).settingsBugReportTitle),
                onTap: () {
                  launch(_bugReportUrl);
                },
              ),
              if (translator.isNotEmpty)
                ListTile(
                  title: Text(L10n.of(context).settingsTranslatorTitle),
                  subtitle: Text(translator),
                  onTap: () {
                    launch(_translationUrl);
                  },
                )
              else
                ListTile(
                  title: Text("Improve translation"),
                  subtitle: Text("Help translating to your language"),
                  onTap: () {
                    launch(_translationUrl);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaption(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).accentColor,
        ),
      ),
    );
  }

  void _onLanguageTap(BuildContext context) {
    final selected =
        Pref.inst().getLanguageOr(language_util.supportedLanguages[0]!.langId);
    showDialog(
      context: context,
      builder: (context) => FancyOptionPicker(
        items: language_util.supportedLanguages.values
            .map((lang) => FancyOptionPickerItem(
                  label: lang.nativeName,
                  isSelected: lang.langId == selected,
                  onSelect: () {
                    _log.info(
                        "[_onLanguageTap] Set language: ${lang.nativeName}");
                    Navigator.of(context).pop(lang.langId);
                  },
                  dense: true,
                ))
            .toList(),
      ),
    ).then((value) {
      if (value != null) {
        Pref.inst().setLanguage(value).then((_) {
          KiwiContainer().resolve<EventBus>().fire(LanguageChangedEvent());
        });
      }
    });
  }

  void _onExifSupportChanged(BuildContext context, bool value) {
    if (value) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).exifSupportConfirmationDialogTitle),
          content: Text(L10n.of(context).exifSupportDetails),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(L10n.of(context).enableButtonLabel),
            ),
          ],
        ),
      ).then((value) {
        if (value == true) {
          _setExifSupport(true);
        }
      });
    } else {
      _setExifSupport(false);
    }
  }

  void _onVersionTap(BuildContext context) {
    if (++_labUnlockCount >= 10) {
      Navigator.of(context).pushNamed(LabSettings.routeName);
      _labUnlockCount = 0;
    }
  }

  void _setExifSupport(bool value) {
    final oldValue = _isEnableExif;
    setState(() {
      _isEnableExif = value;
    });
    Pref.inst().setEnableExif(value).then((result) {
      if (result) {
        if (value) {
          KiwiContainer()
              .resolve<MetadataTaskManager>()
              .addTask(MetadataTask(widget.account));
        }
      } else {
        _log.severe("[_setExifSupport] Failed writing pref");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.of(context).writePreferenceFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
        setState(() {
          _isEnableExif = oldValue;
        });
      }
    });
  }

  static const String _sourceRepo = "https://gitlab.com/nkming2/nc-photos";
  static const String _bugReportUrl =
      "https://gitlab.com/nkming2/nc-photos/-/issues";
  static const String _translationUrl =
      "https://gitlab.com/nkming2/nc-photos/-/tree/master/lib/l10n";

  late bool _isEnableExif;
  int _labUnlockCount = 0;

  static final _log = Logger("widget.settings._SettingsState");
}
