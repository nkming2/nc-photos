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
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/lab_settings.dart';
import 'package:nc_photos/widget/stateful_slider.dart';
import 'package:screen_brightness/screen_brightness.dart';
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
    _screenBrightness = Pref.inst().getViewerScreenBrightnessOr(-1);
    _isForceRotation = Pref.inst().isViewerForceRotationOr(false);
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
    final translator = L10n.global().translator;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsWidgetTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              ListTile(
                title: Text(L10n.global().settingsLanguageTitle),
                subtitle: Text(language_util.getSelectedLanguageName()),
                onTap: () => _onLanguageTap(context),
              ),
              SwitchListTile(
                title: Text(L10n.global().settingsExifSupportTitle),
                subtitle: _isEnableExif
                    ? Text(L10n.global().settingsExifSupportTrueSubtitle)
                    : null,
                value: _isEnableExif,
                onChanged: (value) => _onExifSupportChanged(context, value),
              ),
              if (platform_k.isMobile) ...[
                _buildCaption(
                    context, L10n.global().settingsViewerSectionTitle),
                SwitchListTile(
                  title: Text(L10n.global().settingsScreenBrightnessTitle),
                  subtitle:
                      Text(L10n.global().settingsScreenBrightnessDescription),
                  value: _screenBrightness >= 0,
                  onChanged: (value) =>
                      _onScreenBrightnessChanged(context, value),
                ),
                SwitchListTile(
                  title: Text(L10n.global().settingsForceRotationTitle),
                  subtitle:
                      Text(L10n.global().settingsForceRotationDescription),
                  value: _isForceRotation,
                  onChanged: (value) => _onForceRotationChanged(value),
                ),
              ],
              _buildCaption(context, L10n.global().settingsAboutSectionTitle),
              ListTile(
                title: Text(L10n.global().settingsVersionTitle),
                subtitle: const Text(k.versionStr),
                onTap: () => _onVersionTap(context),
              ),
              ListTile(
                title: Text(L10n.global().settingsSourceCodeTitle),
                subtitle: Text(_sourceRepo),
                onTap: () async {
                  await launch(_sourceRepo);
                },
              ),
              ListTile(
                title: Text(L10n.global().settingsBugReportTitle),
                onTap: () {
                  launch(_bugReportUrl);
                },
              ),
              if (translator.isNotEmpty)
                ListTile(
                  title: Text(L10n.global().settingsTranslatorTitle),
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
                  description: lang.isoName,
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
        builder: (context) => AppTheme(
          child: AlertDialog(
            title: Text(L10n.global().exifSupportConfirmationDialogTitle),
            content: Text(L10n.global().exifSupportDetails),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child:
                    Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(L10n.global().enableButtonLabel),
              ),
            ],
          ),
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

  void _onScreenBrightnessChanged(BuildContext context, bool value) async {
    if (value) {
      var brightness = 0.5;
      try {
        await ScreenBrightness.setScreenBrightness(brightness);
        final value = await showDialog<int>(
          context: context,
          builder: (_) => AppTheme(
            child: AlertDialog(
              title: Text(L10n.global().settingsScreenBrightnessTitle),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(L10n.global().settingsScreenBrightnessDescription),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        Icons.brightness_low,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      Expanded(
                        child: StatefulSlider(
                          initialValue: brightness,
                          min: 0.01,
                          onChangeEnd: (value) async {
                            brightness = value;
                            try {
                              await ScreenBrightness.setScreenBrightness(value);
                            } catch (e, stackTrace) {
                              _log.severe("Failed while setScreenBrightness", e,
                                  stackTrace);
                            }
                          },
                        ),
                      ),
                      Icon(
                        Icons.brightness_high,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop((brightness * 100).round());
                  },
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            ),
          ),
        );

        if (value != null) {
          _setScreenBrightness(value);
        }
      } finally {
        ScreenBrightness.resetScreenBrightness();
      }
    } else {
      _setScreenBrightness(-1);
    }
  }

  void _onForceRotationChanged(bool value) => _setForceRotation(value);

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
          MetadataTaskManager().addTask(MetadataTask(widget.account));
        }
      } else {
        _log.severe("[_setExifSupport] Failed writing pref");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().writePreferenceFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
        setState(() {
          _isEnableExif = oldValue;
        });
      }
    });
  }

  void _setScreenBrightness(int value) {
    final oldValue = _screenBrightness;
    setState(() {
      _screenBrightness = value;
    });
    Pref.inst().setViewerScreenBrightness(value).then((result) {
      if (!result) {
        _log.severe("[_setScreenBrightness] Failed writing pref");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().writePreferenceFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
        setState(() {
          _screenBrightness = oldValue;
        });
      }
    });
  }

  void _setForceRotation(bool value) {
    final oldValue = _isForceRotation;
    setState(() {
      _isForceRotation = value;
    });
    Pref.inst().setViewerForceRotation(value).then((result) {
      if (!result) {
        _log.severe("[_setForceRotation] Failed writing pref");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().writePreferenceFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
        setState(() {
          _isForceRotation = oldValue;
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
  late int _screenBrightness;
  late bool _isForceRotation;
  int _labUnlockCount = 0;

  static final _log = Logger("widget.settings._SettingsState");
}
