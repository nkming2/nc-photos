import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsArguments {
  SettingsArguments(this.account);

  final Account account;
}

class Settings extends StatefulWidget {
  static const routeName = "/settings";

  Settings({
    Key key,
    @required this.account,
  }) : super(key: key);

  Settings.fromArgs(SettingsArguments args, {Key key})
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
    _isEnableExif = Pref.inst().isEnableExif();
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
    final translator = AppLocalizations.of(context).translator;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(AppLocalizations.of(context).settingsWidgetTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              SwitchListTile(
                title:
                    Text(AppLocalizations.of(context).settingsExifSupportTitle),
                subtitle: _isEnableExif
                    ? Text(AppLocalizations.of(context)
                        .settingsExifSupportTrueSubtitle)
                    : null,
                value: _isEnableExif,
                onChanged: (value) => _onExifSupportChanged(context, value),
              ),
              _buildCaption(context,
                  AppLocalizations.of(context).settingsAboutSectionTitle),
              ListTile(
                title: Text(AppLocalizations.of(context).settingsVersionTitle),
                subtitle: const Text(k.versionStr),
              ),
              ListTile(
                title:
                    Text(AppLocalizations.of(context).settingsSourceCodeTitle),
                subtitle: Text(_sourceRepo),
                onTap: () async {
                  await launch(_sourceRepo);
                },
              ),
              ListTile(
                title:
                    Text(AppLocalizations.of(context).settingsBugReportTitle),
                onTap: () {
                  launch(_bugReportUrl);
                },
              ),
              if (translator.isNotEmpty)
                ListTile(
                  title: Text(
                      AppLocalizations.of(context).settingsTranslatorTitle),
                  subtitle: Text(translator),
                ),
              ListTile(
                title: Text("Improve translation"),
                subtitle: Text("Help translating to your language"),
                onTap: () async {
                  await launch(_translationUrl);
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

  void _onExifSupportChanged(BuildContext context, bool value) {
    if (value) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
              AppLocalizations.of(context).exifSupportConfirmationDialogTitle),
          content: Text(AppLocalizations.of(context).exifSupportDetails),
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
              child: Text(AppLocalizations.of(context).enableButtonLabel),
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
          content: Text(
              AppLocalizations.of(context).writePreferenceFailureNotification),
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

  bool _isEnableExif;

  static final _log = Logger("widget.settings._SettingsState");
}
