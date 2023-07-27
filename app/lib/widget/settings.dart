import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/platform/notification.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/stream_util.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/fancy_option_picker.dart';
import 'package:nc_photos/widget/gps_map.dart';
import 'package:nc_photos/widget/list_tile_center_leading.dart';
import 'package:nc_photos/widget/settings/developer_settings.dart';
import 'package:nc_photos/widget/settings/expert_settings.dart';
import 'package:nc_photos/widget/settings/language_settings.dart';
import 'package:nc_photos/widget/settings/metadata_settings.dart';
import 'package:nc_photos/widget/settings/photos_settings.dart';
import 'package:nc_photos/widget/settings/settings_list_caption.dart';
import 'package:nc_photos/widget/settings/theme_settings.dart';
import 'package:nc_photos/widget/stateful_slider.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:tuple/tuple.dart';

part 'settings.g.dart';

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

@npLog
class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => _buildContent(context),
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
              ValueStreamBuilder<language_util.AppLanguage>(
                stream: context.read<PrefController>().language,
                builder: (context, snapshot) => ListTile(
                  leading: const ListTileCenterLeading(
                    child: Icon(Icons.translate_outlined),
                  ),
                  title: Text(L10n.global().settingsLanguageTitle),
                  subtitle: Text(snapshot.requireData.nativeName),
                  onTap: () {
                    Navigator.of(context).pushNamed(LanguageSettings.routeName);
                  },
                ),
              ),
              _SubPageItem(
                leading: const Icon(Icons.palette_outlined),
                label: L10n.global().settingsThemeTitle,
                description: L10n.global().settingsThemeDescription,
                pageBuilder: () => const ThemeSettings(),
              ),
              _SubPageItem(
                leading: const Icon(Icons.local_offer_outlined),
                label: L10n.global().settingsMetadataTitle,
                pageBuilder: () => const MetadataSettings(),
              ),
              _SubPageItem(
                leading: const Icon(Icons.image_outlined),
                label: L10n.global().photosTabLabel,
                description: L10n.global().settingsPhotosDescription,
                pageBuilder: () => const PhotosSettings(),
              ),
              _SubPageItem(
                leading: const Icon(Icons.grid_view_outlined),
                label: L10n.global().collectionsTooltip,
                pageBuilder: () => _AlbumSettings(),
              ),
              _SubPageItem(
                leading: const Icon(Icons.view_carousel_outlined),
                label: L10n.global().settingsViewerTitle,
                description: L10n.global().settingsViewerDescription,
                pageBuilder: () => _ViewerSettings(),
              ),
              if (features.isSupportEnhancement)
                _SubPageItem(
                  leading: const Icon(Icons.auto_fix_high_outlined),
                  label: L10n.global().settingsImageEditTitle,
                  description: L10n.global().settingsImageEditDescription,
                  pageBuilder: () => const EnhancementSettings(),
                ),
              _SubPageItem(
                leading: const Icon(Icons.emoji_symbols_outlined),
                label: L10n.global().settingsMiscellaneousTitle,
                pageBuilder: () => const _MiscSettings(),
              ),
              // if (_enabledExperiments.isNotEmpty)
              //   _SubPageItem(
              //     leading: const Icon(Icons.science_outlined),
              //     label: L10n.global().settingsExperimentalTitle,
              //     description: L10n.global().settingsExperimentalDescription,
              //     pageBuilder: () => _ExperimentalSettings(),
              //   ),
              _SubPageItem(
                leading: const Icon(Icons.warning_amber),
                label: L10n.global().settingsExpertTitle,
                pageBuilder: () => const ExpertSettings(),
              ),
              if (_isShowDevSettings)
                _SubPageItem(
                  leading: const Icon(Icons.code_outlined),
                  label: "Developer options",
                  pageBuilder: () => const DeveloperSettings(),
                ),
              SettingsListCaption(
                label: L10n.global().settingsAboutSectionTitle,
              ),
              ListTile(
                title: Text(L10n.global().settingsVersionTitle),
                subtitle: const Text(k.versionStr),
                onTap: () {
                  if (!_isShowDevSettings && --_devSettingsUnlockCount <= 0) {
                    setState(() {
                      _isShowDevSettings = true;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(L10n.global().settingsSourceCodeTitle),
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

  Future<void> _onCaptureLogChanged(BuildContext context, bool value) async {
    if (value) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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

  Future<void> _onLogSaveSuccessful(dynamic result) async {
    final nm = platform.NotificationManager();
    try {
      await nm.notify(LogSaveSuccessfulNotification(result));
    } catch (e, stacktrace) {
      _log.shout("[_onLogSaveSuccessful] Failed showing platform notification",
          e, stacktrace);
    }
  }

  var _devSettingsUnlockCount = 3;
  var _isShowDevSettings = false;

  static const String _sourceRepo = "https://bit.ly/3LQerBv";
  static const String _bugReportUrl = "https://bit.ly/3NANrr7";
  static const String _translationUrl = "https://bit.ly/3NwmdSw";
}

class _SubPageItem extends StatelessWidget {
  const _SubPageItem({
    this.leading,
    required this.label,
    this.description,
    required this.pageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading == null ? null : ListTileCenterLeading(child: leading!),
      title: Text(label),
      subtitle: description == null ? null : Text(description!),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => pageBuilder(),
          ),
        );
      },
    );
  }

  final Widget? leading;
  final String label;
  final String? description;
  final Widget Function() pageBuilder;
}

class _ViewerSettings extends StatefulWidget {
  @override
  createState() => _ViewerSettingsState();
}

@npLog
class _ViewerSettingsState extends State<_ViewerSettings> {
  @override
  initState() {
    super.initState();
    _screenBrightness = Pref().getViewerScreenBrightnessOr(-1);
    _isForceRotation = Pref().isViewerForceRotationOr(false);
    _gpsMapProvider = GpsMapProvider.values[Pref().getGpsMapProviderOr(0)];
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsViewerTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              if (platform_k.isMobile)
                SwitchListTile(
                  title: Text(L10n.global().settingsScreenBrightnessTitle),
                  subtitle:
                      Text(L10n.global().settingsScreenBrightnessDescription),
                  value: _screenBrightness >= 0,
                  onChanged: (value) =>
                      _onScreenBrightnessChanged(context, value),
                ),
              if (platform_k.isMobile)
                SwitchListTile(
                  title: Text(L10n.global().settingsForceRotationTitle),
                  subtitle:
                      Text(L10n.global().settingsForceRotationDescription),
                  value: _isForceRotation,
                  onChanged: (value) => _onForceRotationChanged(value),
                ),
              ListTile(
                title: Text(L10n.global().settingsMapProviderTitle),
                subtitle: Text(_gpsMapProvider.toUserString()),
                onTap: () => _onMapProviderTap(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onScreenBrightnessChanged(
      BuildContext context, bool value) async {
    if (value) {
      var brightness = 0.5;
      try {
        await ScreenBrightness().setScreenBrightness(brightness);
        final value = await showDialog<int>(
          context: context,
          builder: (_) => AlertDialog(
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
                    const Icon(Icons.brightness_low),
                    Expanded(
                      child: StatefulSlider(
                        initialValue: brightness,
                        min: 0.01,
                        onChangeEnd: (value) async {
                          brightness = value;
                          try {
                            await ScreenBrightness().setScreenBrightness(value);
                          } catch (e, stackTrace) {
                            _log.severe("Failed while setScreenBrightness", e,
                                stackTrace);
                          }
                        },
                      ),
                    ),
                    const Icon(Icons.brightness_high),
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
        );

        if (value != null) {
          unawaited(_setScreenBrightness(value));
        }
      } finally {
        unawaited(ScreenBrightness().resetScreenBrightness());
      }
    } else {
      unawaited(_setScreenBrightness(-1));
    }
  }

  void _onForceRotationChanged(bool value) => _setForceRotation(value);

  Future<void> _onMapProviderTap(BuildContext context) async {
    final oldValue = _gpsMapProvider;
    final newValue = await showDialog<GpsMapProvider>(
      context: context,
      builder: (context) => FancyOptionPicker(
        items: GpsMapProvider.values
            .map((provider) => FancyOptionPickerItem(
                  label: provider.toUserString(),
                  isSelected: provider == oldValue,
                  onSelect: () {
                    _log.info(
                        "[_onMapProviderTap] Set map provider: ${provider.toUserString()}");
                    Navigator.of(context).pop(provider);
                  },
                ))
            .toList(),
      ),
    );
    if (newValue == null || newValue == oldValue) {
      return;
    }
    setState(() {
      _gpsMapProvider = newValue;
    });
    try {
      await Pref().setGpsMapProvider(newValue.index);
    } catch (e, stackTrace) {
      _log.severe("[_onMapProviderTap] Failed writing pref", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _gpsMapProvider = oldValue;
      });
    }
  }

  Future<void> _setScreenBrightness(int value) async {
    final oldValue = _screenBrightness;
    setState(() {
      _screenBrightness = value;
    });
    if (!await Pref().setViewerScreenBrightness(value)) {
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
    if (!await Pref().setViewerForceRotation(value)) {
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
  late GpsMapProvider _gpsMapProvider;
}

class _AlbumSettings extends StatefulWidget {
  @override
  createState() => _AlbumSettingsState();
}

@npLog
class _AlbumSettingsState extends State<_AlbumSettings> {
  @override
  initState() {
    super.initState();
    _isBrowserShowDate = Pref().isAlbumBrowserShowDateOr();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().collectionsTooltip),
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
    if (!await Pref().setAlbumBrowserShowDate(value)) {
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
}

class EnhancementSettings extends StatefulWidget {
  static const routeName = "/enhancement-settings";

  static Route buildRoute() => MaterialPageRoute(
        builder: (_) => const EnhancementSettings(),
      );

  const EnhancementSettings({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _EnhancementSettingsState();
}

@npLog
class _EnhancementSettingsState extends State<EnhancementSettings> {
  @override
  initState() {
    super.initState();
    _maxWidth = Pref().getEnhanceMaxWidthOr();
    _maxHeight = Pref().getEnhanceMaxHeightOr();
    _isSaveEditResultToServer = Pref().isSaveEditResultToServerOr();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsImageEditTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              SwitchListTile(
                title: Text(
                    L10n.global().settingsImageEditSaveResultsToServerTitle),
                subtitle: Text(_isSaveEditResultToServer
                    ? L10n.global()
                        .settingsImageEditSaveResultsToServerTrueDescription
                    : L10n.global()
                        .settingsImageEditSaveResultsToServerFalseDescription),
                value: _isSaveEditResultToServer,
                onChanged: _onSaveEditResultToServerChanged,
              ),
              ListTile(
                title: Text(L10n.global().settingsEnhanceMaxResolutionTitle2),
                subtitle: Text("${_maxWidth}x$_maxHeight"),
                onTap: () => _onMaxResolutionTap(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onMaxResolutionTap(BuildContext context) async {
    var width = _maxWidth;
    var height = _maxHeight;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.global().settingsEnhanceMaxResolutionTitle2),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.global().settingsEnhanceMaxResolutionDescription),
            const SizedBox(height: 16),
            _EnhanceResolutionSlider(
              initialWidth: _maxWidth,
              initialHeight: _maxHeight,
              onChanged: (value) {
                width = value.item1;
                height = value.item2;
              },
            )
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    if (result != true || (width == _maxWidth && height == _maxHeight)) {
      return;
    }

    unawaited(_setMaxResolution(width, height));
  }

  Future<void> _setMaxResolution(int width, int height) async {
    _log.info(
        "[_setMaxResolution] ${_maxWidth}x$_maxHeight -> ${width}x$height");
    final oldWidth = _maxWidth;
    final oldHeight = _maxHeight;
    setState(() {
      _maxWidth = width;
      _maxHeight = height;
    });
    if (!await Pref().setEnhanceMaxWidth(width) ||
        !await Pref().setEnhanceMaxHeight(height)) {
      _log.severe("[_setMaxResolution] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      await Pref().setEnhanceMaxWidth(oldWidth);
      setState(() {
        _maxWidth = oldWidth;
        _maxHeight = oldHeight;
      });
    }
  }

  Future<void> _onSaveEditResultToServerChanged(bool value) async {
    final oldValue = _isSaveEditResultToServer;
    setState(() {
      _isSaveEditResultToServer = value;
    });
    if (!await Pref().setSaveEditResultToServer(value)) {
      _log.severe("[_onSaveEditResultToServerChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isSaveEditResultToServer = oldValue;
      });
    }
  }

  late int _maxWidth;
  late int _maxHeight;
  late bool _isSaveEditResultToServer;
}

class _EnhanceResolutionSlider extends StatefulWidget {
  const _EnhanceResolutionSlider({
    Key? key,
    required this.initialWidth,
    required this.initialHeight,
    this.onChanged,
  }) : super(key: key);

  @override
  createState() => _EnhanceResolutionSliderState();

  final int initialWidth;
  final int initialHeight;
  final ValueChanged<Tuple2<int, int>>? onChanged;
}

class _EnhanceResolutionSliderState extends State<_EnhanceResolutionSlider> {
  @override
  initState() {
    super.initState();
    _width = widget.initialWidth;
    _height = widget.initialHeight;
  }

  @override
  build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Text("${_width}x$_height"),
        ),
        StatefulSlider(
          initialValue: resolutionToSliderValue(_width).toDouble(),
          min: -3,
          max: 3,
          divisions: 6,
          onChangeEnd: (value) async {
            final resolution = sliderValueToResolution(value.toInt());
            setState(() {
              _width = resolution.item1;
              _height = resolution.item2;
            });
            widget.onChanged?.call(resolution);
          },
        ),
      ],
    );
  }

  static Tuple2<int, int> sliderValueToResolution(int value) {
    switch (value) {
      case -3:
        return const Tuple2(1024, 768);
      case -2:
        return const Tuple2(1280, 960);
      case -1:
        return const Tuple2(1600, 1200);
      case 1:
        return const Tuple2(2560, 1920);
      case 2:
        return const Tuple2(3200, 2400);
      case 3:
        return const Tuple2(4096, 3072);
      default:
        return const Tuple2(2048, 1536);
    }
  }

  static int resolutionToSliderValue(int width) {
    switch (width) {
      case 1024:
        return -3;
      case 1280:
        return -2;
      case 1600:
        return -1;
      case 2560:
        return 1;
      case 3200:
        return 2;
      case 4096:
        return 3;
      default:
        return 0;
    }
  }

  late int _width;
  late int _height;
}

class _MiscSettings extends StatefulWidget {
  const _MiscSettings({Key? key}) : super(key: key);

  @override
  createState() => _MiscSettingsState();
}

@npLog
class _MiscSettingsState extends State<_MiscSettings> {
  @override
  initState() {
    super.initState();
    _isPhotosTabSortByName = Pref().isPhotosTabSortByNameOr();
    _isDoubleTapExit = Pref().isDoubleTapExitOr();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(L10n.global().settingsMiscellaneousTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              SwitchListTile(
                title: Text(L10n.global().settingsDoubleTapExitTitle),
                value: _isDoubleTapExit,
                onChanged: (value) => _onDoubleTapExitChanged(value),
              ),
              SwitchListTile(
                title: Text(L10n.global().settingsPhotosTabSortByNameTitle),
                value: _isPhotosTabSortByName,
                onChanged: (value) => _onPhotosTabSortByNameChanged(value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onDoubleTapExitChanged(bool value) async {
    final oldValue = _isDoubleTapExit;
    setState(() {
      _isDoubleTapExit = value;
    });
    if (!await Pref().setDoubleTapExit(value)) {
      _log.severe("[_onDoubleTapExitChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isDoubleTapExit = oldValue;
      });
    }
  }

  Future<void> _onPhotosTabSortByNameChanged(bool value) async {
    final oldValue = _isPhotosTabSortByName;
    setState(() {
      _isPhotosTabSortByName = value;
    });
    if (!await Pref().setPhotosTabSortByName(value)) {
      _log.severe("[_onPhotosTabSortByNameChanged] Failed writing pref");
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _isPhotosTabSortByName = oldValue;
      });
    }
  }

  late bool _isPhotosTabSortByName;
  late bool _isDoubleTapExit;
}

// final _enabledExperiments = [
// ];
