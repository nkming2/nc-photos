import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/mobile/notification.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/root_picker.dart';
import 'package:nc_photos/widget/share_folder_picker.dart';
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

  const Settings({
    Key? key,
    required this.account,
  }) : super(key: key);

  Settings.fromArgs(SettingsArguments args, {Key? key})
      : this(
          key: key,
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
  build(BuildContext context) {
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
              _buildSubSettings(
                context,
                leading: Icon(
                  Icons.manage_accounts_outlined,
                  color: AppTheme.getUnfocusedIconColor(context),
                ),
                label: L10n.global().settingsAccountTitle,
                builder: () => AccountSettingsWidget(account: widget.account),
              ),
              if (platform_k.isMobile)
                _buildSubSettings(
                  context,
                  leading: Icon(
                    Icons.view_carousel_outlined,
                    color: AppTheme.getUnfocusedIconColor(context),
                  ),
                  label: L10n.global().settingsViewerTitle,
                  description: L10n.global().settingsViewerDescription,
                  builder: () => _ViewerSettings(),
                ),
              _buildSubSettings(
                context,
                leading: Icon(
                  Icons.photo_album_outlined,
                  color: AppTheme.getUnfocusedIconColor(context),
                ),
                label: L10n.global().settingsAlbumTitle,
                description: L10n.global().settingsAlbumDescription,
                builder: () => _AlbumSettings(),
              ),
              _buildSubSettings(
                context,
                leading: Icon(
                  Icons.palette_outlined,
                  color: AppTheme.getUnfocusedIconColor(context),
                ),
                label: L10n.global().settingsThemeTitle,
                description: L10n.global().settingsThemeDescription,
                builder: () => _ThemeSettings(),
              ),
              _buildSubSettings(
                context,
                leading: Icon(
                  Icons.science_outlined,
                  color: AppTheme.getUnfocusedIconColor(context),
                ),
                label: L10n.global().settingsExperimentalTitle,
                description: L10n.global().settingsExperimentalDescription,
                builder: () => _ExperimentalSettings(),
              ),
              _buildCaption(context, L10n.global().settingsAboutSectionTitle),
              ListTile(
                title: Text(L10n.global().settingsVersionTitle),
                subtitle: const Text(k.versionStr),
              ),
              ListTile(
                title: Text(L10n.global().settingsSourceCodeTitle),
                subtitle: const Text(_sourceRepo),
                onTap: () {
                  launch(_sourceRepo);
                },
              ),
              ListTile(
                title: Text(L10n.global().settingsBugReportTitle),
                onTap: () {
                  launch(_bugReportUrl);
                },
              ),
              SwitchListTile(
                title: Text(L10n.global().settingsCaptureLogsTitle),
                subtitle: Text(L10n.global().settingsCaptureLogsDescription),
                value: LogCapturer().isEnable,
                onChanged: (value) => _onCaptureLogChanged(context, value),
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
                  title: const Text("Improve translation"),
                  subtitle: const Text("Help translating to your language"),
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

  Widget _buildSubSettings(
    BuildContext context, {
    Widget? leading,
    required String label,
    String? description,
    required Widget Function() builder,
  }) {
    return ListTile(
      leading: leading == null
          ? null
          : SizedBox(
              height: double.infinity,
              child: leading,
            ),
      title: Text(label),
      subtitle: description == null ? null : Text(description),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => builder(),
          ),
        );
      },
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

  void _onCaptureLogChanged(BuildContext context, bool value) async {
    if (value) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AppTheme(
          child: AlertDialog(
            content: Text(L10n.global().captureLogDetails),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(L10n.global().enableButtonLabel),
              ),
            ],
          ),
        ),
      );
      if (result == true) {
        setState(() {
          LogCapturer().start();
        });
      }
    } else {
      if (LogCapturer().isEnable) {
        setState(() {
          LogCapturer().stop().then((result) {
            _onLogSaveSuccessful(result);
          });
        });
      }
    }
  }

  void _onLogSaveSuccessful(dynamic result) {
    dynamic notif;
    if (platform_k.isAndroid) {
      notif = AndroidLogSaveSuccessfulNotification(result);
    }
    if (notif != null) {
      try {
        notif.notify();
        return;
      } catch (e, stacktrace) {
        _log.shout(
            "[_onLogSaveSuccessful] Failed showing platform notification",
            e,
            stacktrace);
      }
    }

    // fallback
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().downloadSuccessNotification),
      duration: k.snackBarDurationShort,
    ));
  }

  Future<void> _setExifSupport(bool value) async {
    final oldValue = _isEnableExif;
    setState(() {
      _isEnableExif = value;
    });
    if (!await Pref.inst().setEnableExif(value)) {
      _log.severe("[_setExifSupport] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isEnableExif = oldValue;
      });
    }
  }

  late bool _isEnableExif;

  static final _log = Logger("widget.settings._SettingsState");

  static const String _sourceRepo = "https://gitlab.com/nkming2/nc-photos";
  static const String _bugReportUrl =
      "https://gitlab.com/nkming2/nc-photos/-/issues";
  static const String _translationUrl =
      "https://gitlab.com/nkming2/nc-photos/-/tree/master/lib/l10n";
}

class AccountSettingsWidgetArguments {
  const AccountSettingsWidgetArguments(this.account);

  final Account account;
}

class AccountSettingsWidget extends StatefulWidget {
  static const routeName = "/account-settings";

  static Route buildRoute(AccountSettingsWidgetArguments args) =>
      MaterialPageRoute(
        builder: (context) => AccountSettingsWidget.fromArgs(args),
      );

  const AccountSettingsWidget({
    Key? key,
    required this.account,
  }) : super(key: key);

  AccountSettingsWidget.fromArgs(AccountSettingsWidgetArguments args,
      {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _AccountSettingsState();

  final Account account;
}

class _AccountSettingsState extends State<AccountSettingsWidget> {
  @override
  initState() {
    super.initState();
    _account = widget.account;

    final settings = Pref.inst().getAccountSettings(_account);
    _isEnableFaceRecognitionApp = settings.isEnableFaceRecognitionApp;
    _shareFolder = settings.shareFolder;
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: (context) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsAccountPageTitle),
          leading: _hasModified
              ? IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: L10n.global().doneButtonTooltip,
                  onPressed: () => _onDonePressed(context),
                )
              : null,
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              ListTile(
                title: Text(L10n.global().settingsIncludedFoldersTitle),
                subtitle: Text(_account.roots.map((e) => "/$e").join("; ")),
                onTap: _onIncludedFoldersPressed,
              ),
              ListTile(
                title: Text(L10n.global().settingsShareFolderTitle),
                subtitle: Text("/$_shareFolder"),
                onTap: () => _onShareFolderPressed(context),
              ),
              _buildCaption(
                  context, L10n.global().settingsServerAppSectionTitle),
              SwitchListTile(
                title: const Text("Face Recognition"),
                value: _isEnableFaceRecognitionApp,
                onChanged: _onEnableFaceRecognitionAppChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onDonePressed(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Home.routeName,
      (route) => false,
      arguments: HomeArguments(_account),
    );
  }

  Future<void> _onIncludedFoldersPressed() async {
    try {
      final result = await Navigator.of(context).pushNamed<Account>(
          RootPicker.routeName,
          arguments: RootPickerArguments(_account));
      if (result == null) {
        // user canceled
        return;
      }
      // we've got a good account
      if (result == _account) {
        // no changes, do nothing
        _log.fine("[_onIncludedFoldersPressed] No changes");
        return;
      }
      final accounts = Pref.inst().getAccounts2()!;
      if (accounts.any((element) => element.account == result)) {
        // conflict with another account. This normally won't happen because
        // the app passwords are unique to each entry, but just in case
        Navigator.of(context).pop();
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().editAccountConflictFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
        return;
      }

      final index = _findAccount(_account, accounts);
      if (index < 0) {
        _log.shout("[_onIncludedFoldersPressed] Account not found: $_account");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().writePreferenceFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
        return;
      }

      final newAccount = accounts[index].copyWith(
        account: result,
      );
      accounts[index] = newAccount;
      if (!await Pref.inst().setAccounts2(accounts)) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().writePreferenceFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
        return;
      }
      setState(() {
        _account = result;
        _hasModified = true;
      });
    } catch (e, stackTrace) {
      _log.shout("[_onIncludedFoldersPressed] Exception", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  Future<void> _onShareFolderPressed(BuildContext context) async {
    final path = await showDialog<String>(
      context: context,
      builder: (_) => _ShareFolderDialog(
        account: widget.account,
        initialValue: _shareFolder,
      ),
    );
    if (path == null || path == _shareFolder) {
      return;
    }
    return _setShareFolder(path);
  }

  Future<void> _onEnableFaceRecognitionAppChanged(bool value) async {
    _log.info("[_onEnableFaceRecognitionAppChanged] New value: $value");
    final oldValue = _isEnableFaceRecognitionApp;
    setState(() {
      _isEnableFaceRecognitionApp = value;
    });
    if (!await _modifyAccountSettings(
      _account,
      isEnableFaceRecognitionApp: value,
    )) {
      _log.severe("[_onEnableFaceRecognitionAppChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isEnableFaceRecognitionApp = oldValue;
      });
    } else {
      setState(() {
        _hasModified = true;
      });
    }
  }

  Future<void> _setShareFolder(String value) async {
    _log.info("[_setShareFolder] New value: $value");
    final oldValue = _shareFolder;
    setState(() {
      _shareFolder = value;
    });
    if (!await _modifyAccountSettings(
      _account,
      shareFolder: value,
    )) {
      _log.severe("[_setShareFolder] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _shareFolder = oldValue;
      });
    } else {
      setState(() {
        _hasModified = true;
      });
    }
  }

  static Future<bool> _modifyAccountSettings(
    Account account, {
    bool? isEnableFaceRecognitionApp,
    String? shareFolder,
  }) {
    try {
      final accounts = Pref.inst().getAccounts2()!;
      final index = _findAccount(account, accounts);
      accounts[index] = accounts[index].copyWith(
        settings: accounts[index].settings.copyWith(
              isEnableFaceRecognitionApp: isEnableFaceRecognitionApp,
              shareFolder: shareFolder,
            ),
      );
      return Pref.inst().setAccounts2(accounts);
    } catch (e, stackTrace) {
      _log.severe(
          "[_modifyAccountSettings] Failed while setting account settings",
          e,
          stackTrace);
      return Future.value(false);
    }
  }

  /// Return the index of [account] in [Pref.getAccounts2]
  static int _findAccount(Account account, [List<PrefAccount>? accounts]) {
    final from = accounts ?? Pref.inst().getAccounts2Or([]);
    return from.indexWhere((element) => element.account == account);
  }

  bool _hasModified = false;
  late Account _account;
  late bool _isEnableFaceRecognitionApp;
  late String _shareFolder;

  static final _log = Logger("widget.settings._AccountSettingsState");
}

class _ShareFolderDialog extends StatefulWidget {
  const _ShareFolderDialog({
    Key? key,
    required this.account,
    required this.initialValue,
  }) : super(key: key);

  @override
  createState() => _ShareFolderDialogState();

  final Account account;
  final String initialValue;
}

class _ShareFolderDialogState extends State<_ShareFolderDialog> {
  @override
  build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().settingsShareFolderDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.global().settingsShareFolderDialogDescription),
            const SizedBox(height: 8),
            InkWell(
              onTap: _onTextFieldPressed,
              child: TextFormField(
                enabled: false,
                controller: _controller,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _onOkPressed,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }

  Future<void> _onTextFieldPressed() async {
    final pick = await Navigator.of(context).pushNamed<String>(
        ShareFolderPicker.routeName,
        arguments: ShareFolderPickerArguments(widget.account, _path));
    if (pick != null) {
      _path = pick;
      _controller.text = "/$pick";
    }
  }

  void _onOkPressed() {
    Navigator.of(context).pop(_path);
  }

  final _formKey = GlobalKey<FormState>();
  late final _controller =
      TextEditingController(text: "/${widget.initialValue}");
  late String _path = widget.initialValue;
}

class _ViewerSettings extends StatefulWidget {
  @override
  createState() => _ViewerSettingsState();
}

class _ViewerSettingsState extends State<_ViewerSettings> {
  @override
  initState() {
    super.initState();
    _screenBrightness = Pref.inst().getViewerScreenBrightnessOr(-1);
    _isForceRotation = Pref.inst().isViewerForceRotationOr(false);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: (context) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsViewerPageTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
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
                subtitle: Text(L10n.global().settingsForceRotationDescription),
                value: _isForceRotation,
                onChanged: (value) => _onForceRotationChanged(value),
              ),
            ],
          ),
        ),
      ],
    );
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

  Future<void> _setScreenBrightness(int value) async {
    final oldValue = _screenBrightness;
    setState(() {
      _screenBrightness = value;
    });
    if (!await Pref.inst().setViewerScreenBrightness(value)) {
      _log.severe("[_setScreenBrightness] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _screenBrightness = oldValue;
      });
    }
  }

  Future<void> _setForceRotation(bool value) async {
    final oldValue = _isForceRotation;
    setState(() {
      _isForceRotation = value;
    });
    if (!await Pref.inst().setViewerForceRotation(value)) {
      _log.severe("[_setForceRotation] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isForceRotation = oldValue;
      });
    }
  }

  late int _screenBrightness;
  late bool _isForceRotation;

  static final _log = Logger("widget.settings._ViewerSettingsState");
}

class _AlbumSettings extends StatefulWidget {
  @override
  createState() => _AlbumSettingsState();
}

class _AlbumSettingsState extends State<_AlbumSettings> {
  @override
  initState() {
    super.initState();
    _isBrowserShowDate = Pref.inst().isAlbumBrowserShowDateOr();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: (context) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsAlbumPageTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              SwitchListTile(
                title: Text(L10n.global().settingsShowDateInAlbumTitle),
                subtitle:
                    Text(L10n.global().settingsShowDateInAlbumDescription),
                value: _isBrowserShowDate,
                onChanged: (value) => _onBrowserShowDateChanged(value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onBrowserShowDateChanged(bool value) async {
    final oldValue = _isBrowserShowDate;
    setState(() {
      _isBrowserShowDate = value;
    });
    if (!await Pref.inst().setAlbumBrowserShowDate(value)) {
      _log.severe("[_onBrowserShowDateChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isBrowserShowDate = oldValue;
      });
    }
  }

  late bool _isBrowserShowDate;

  static final _log = Logger("widget.settings._AlbumSettingsState");
}

class _ThemeSettings extends StatefulWidget {
  @override
  createState() => _ThemeSettingsState();
}

class _ThemeSettingsState extends State<_ThemeSettings> {
  @override
  initState() {
    super.initState();
    _isFollowSystemTheme = Pref.inst().isFollowSystemThemeOr(false);
    _isUseBlackInDarkTheme = Pref.inst().isUseBlackInDarkThemeOr(false);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: (context) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsThemePageTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              if (platform_k.isAndroid && AndroidInfo().sdkInt >= 29)
                SwitchListTile(
                  title: Text(L10n.global().settingsFollowSystemThemeTitle),
                  value: _isFollowSystemTheme,
                  onChanged: (value) => _onFollowSystemThemeChanged(value),
                ),
              SwitchListTile(
                title: Text(L10n.global().settingsUseBlackInDarkThemeTitle),
                subtitle: Text(_isUseBlackInDarkTheme
                    ? L10n.global().settingsUseBlackInDarkThemeTrueDescription
                    : L10n.global()
                        .settingsUseBlackInDarkThemeFalseDescription),
                value: _isUseBlackInDarkTheme,
                onChanged: (value) =>
                    _onUseBlackInDarkThemeChanged(context, value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onFollowSystemThemeChanged(bool value) async {
    final oldValue = _isFollowSystemTheme;
    setState(() {
      _isFollowSystemTheme = value;
    });
    if (await Pref.inst().setFollowSystemTheme(value)) {
      KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
    } else {
      _log.severe("[_onFollowSystemThemeChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isFollowSystemTheme = oldValue;
      });
    }
  }

  void _onUseBlackInDarkThemeChanged(BuildContext context, bool value) async {
    final oldValue = _isUseBlackInDarkTheme;
    setState(() {
      _isUseBlackInDarkTheme = value;
    });
    if (await Pref.inst().setUseBlackInDarkTheme(value)) {
      if (Theme.of(context).brightness == Brightness.dark) {
        KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
      }
    } else {
      _log.severe("[_onUseBlackInDarkThemeChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isUseBlackInDarkTheme = oldValue;
      });
    }
  }

  late bool _isFollowSystemTheme;
  late bool _isUseBlackInDarkTheme;

  static final _log = Logger("widget.settings._ThemeSettingsState");
}

class _ExperimentalSettings extends StatefulWidget {
  @override
  createState() => _ExperimentalSettingsState();
}

class _ExperimentalSettingsState extends State<_ExperimentalSettings> {
  @override
  initState() {
    super.initState();
    _isEnableSharedAlbum = Pref.inst().isLabEnableSharedAlbumOr(false);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(
          builder: (context) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsExperimentalPageTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              SwitchListTile(
                title: const Text("Shared album"),
                subtitle:
                    const Text("Share albums with users on the same server"),
                value: _isEnableSharedAlbum,
                onChanged: (value) => _onEnableSharedAlbumChanged(value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onEnableSharedAlbumChanged(bool value) async {
    final oldValue = _isEnableSharedAlbum;
    setState(() {
      _isEnableSharedAlbum = value;
    });
    if (!await Pref.inst().setLabEnableSharedAlbum(value)) {
      _log.severe("[_onEnableSharedAlbumChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isEnableSharedAlbum = oldValue;
      });
    }
  }

  late bool _isEnableSharedAlbum;

  static final _log = Logger("widget.settings._ExperimentalSettingsState");
}

Widget _buildCaption(BuildContext context, String label) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  );
}
