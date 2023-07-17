import 'dart:async';

import 'package:copy_with/copy_with.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'theme/bloc.dart';
part 'theme/state_event.dart';
part 'theme_settings.g.dart';

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(KiwiContainer().resolve<DiContainer>()),
      child: const _WrappedThemeSettings(),
    );
  }
}

class _WrappedThemeSettings extends StatefulWidget {
  const _WrappedThemeSettings();

  @override
  State<StatefulWidget> createState() => _WrappedThemeSettingsState();
}

@npLog
class _WrappedThemeSettingsState extends State<_WrappedThemeSettings> {
  @override
  void initState() {
    super.initState();
    _errorSubscription = context.read<_Bloc>().errorStream().listen((_) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().writePreferenceFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
    });
  }

  @override
  void dispose() {
    _errorSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(L10n.global().settingsThemeTitle),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              BlocBuilder<_Bloc, _State>(
                buildWhen: (previous, current) =>
                    previous.seedColor != current.seedColor,
                builder: (context, state) {
                  return ListTile(
                    title: Text(L10n.global().settingsSeedColorTitle),
                    subtitle: Text(L10n.global().settingsSeedColorDescription),
                    trailing: Icon(
                      Icons.circle,
                      size: 32,
                      color: state.seedColor,
                    ),
                    onTap: () => _onSeedColorPressed(context),
                  );
                },
              ),
              if (platform_k.isAndroid &&
                  AndroidInfo().sdkInt >= AndroidVersion.Q)
                BlocBuilder<_Bloc, _State>(
                  buildWhen: (previous, current) =>
                      previous.isFollowSystemTheme !=
                      current.isFollowSystemTheme,
                  builder: (context, state) {
                    return SwitchListTile(
                      title: Text(L10n.global().settingsFollowSystemThemeTitle),
                      value: state.isFollowSystemTheme,
                      onChanged: (value) {
                        context.read<_Bloc>().add(_SetFollowSystemTheme(value));
                      },
                    );
                  },
                ),
              BlocBuilder<_Bloc, _State>(
                buildWhen: (previous, current) =>
                    previous.isUseBlackInDarkTheme !=
                    current.isUseBlackInDarkTheme,
                builder: (context, state) {
                  return SwitchListTile(
                    title: Text(L10n.global().settingsUseBlackInDarkThemeTitle),
                    subtitle: Text(state.isUseBlackInDarkTheme
                        ? L10n.global()
                            .settingsUseBlackInDarkThemeTrueDescription
                        : L10n.global()
                            .settingsUseBlackInDarkThemeFalseDescription),
                    value: state.isUseBlackInDarkTheme,
                    onChanged: (value) {
                      context.read<_Bloc>().add(
                          _SetUseBlackInDarkTheme(value, Theme.of(context)));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onSeedColorPressed(BuildContext context) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => const _SeedColorPicker(),
    );
    if (result == null) {
      return;
    }
    if (mounted) {
      context.read<_Bloc>().add(_SetSeedColor(result));
    }
  }

  late final StreamSubscription _errorSubscription;
}

class _SeedColorPicker extends StatefulWidget {
  const _SeedColorPicker();

  @override
  State<StatefulWidget> createState() => _SeedColorPickerState();
}

class _SeedColorPickerState extends State<_SeedColorPicker> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _isVisible,
      child: AlertDialog(
        title: Text(L10n.global().settingsSeedColorPickerTitle),
        content: Wrap(
          children: const [
            Color(0xFFF44336),
            Color(0xFF9C27B0),
            Color(0xFF2196F3),
            Color(0xFF4CAF50),
            Color(0xFFFFC107),
            null,
          ]
              .map((c) => _SeedColorPickerItem(
                    seedColor: c,
                    onSelected: () => _onItemSelected(context, c),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _onItemSelected(BuildContext context, Color? seedColor) async {
    if (seedColor != null) {
      Navigator.of(context).pop(seedColor);
      return;
    }
    setState(() {
      _isVisible = false;
    });
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => const _SeedColorCustomPicker(),
      barrierColor: Colors.transparent,
    );
    Navigator.of(context).pop(color);
  }

  var _isVisible = true;
}

class _SeedColorCustomPicker extends StatefulWidget {
  const _SeedColorCustomPicker();

  @override
  State<StatefulWidget> createState() => _SeedColorCustomPickerState();
}

class _SeedColorCustomPickerState extends State<_SeedColorCustomPicker> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().settingsSeedColorPickerTitle),
      content: SingleChildScrollView(
        child: _HueRingPicker(
          pickerColor: _customColor,
          onColorChanged: (value) {
            setState(() {
              _customColor = value;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_customColor);
          },
          child: Text(L10n.global().applyButtonLabel),
        ),
      ],
    );
  }

  late Color _customColor = getSeedColor();
}

class _SeedColorPickerItem extends StatelessWidget {
  const _SeedColorPickerItem({
    required this.seedColor,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox.square(
      dimension: _size,
      child: Center(
        child: seedColor != null
            ? Icon(
                Icons.circle,
                size: _size * .9,
                color: seedColor,
              )
            : Transform.scale(
                scale: .9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset("assets/ic_custom_color_56dp.png"),
                    const Icon(
                      Icons.colorize_outlined,
                      size: _size * .5,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
      ),
    );
    if (onSelected != null) {
      return InkWell(
        customBorder: const CircleBorder(),
        onTap: onSelected,
        child: content,
      );
    } else {
      return content;
    }
  }

  final Color? seedColor;
  final VoidCallback? onSelected;

  static const _size = 56.0;
}

/// Based on the original HueRingPicker
class _HueRingPicker extends StatefulWidget {
  const _HueRingPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    // ignore: unused_element
    this.colorPickerHeight = 250.0,
    // ignore: unused_element
    this.hueRingStrokeWidth = 20.0,
    // ignore: unused_element
    this.displayThumbColor = true,
    // ignore: unused_element
    this.pickerAreaBorderRadius = const BorderRadius.all(Radius.zero),
  }) : super(key: key);

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final double colorPickerHeight;
  final double hueRingStrokeWidth;
  final bool displayThumbColor;
  final BorderRadius pickerAreaBorderRadius;

  @override
  _HueRingPickerState createState() => _HueRingPickerState();
}

class _HueRingPickerState extends State<_HueRingPicker> {
  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    super.initState();
  }

  @override
  void didUpdateWidget(_HueRingPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  void onColorChanging(HSVColor color) {
    setState(() => currentHsvColor = color.withSaturation(1).withValue(1));
    widget.onColorChanged(currentHsvColor.toColor());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: widget.pickerAreaBorderRadius,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                ColorIndicator(
                  currentHsvColor,
                  width: 128,
                  height: 128,
                ),
                SizedBox(
                  width: widget.colorPickerHeight,
                  height: widget.colorPickerHeight,
                  child: ColorPickerHueRing(
                    currentHsvColor,
                    onColorChanging,
                    displayThumbColor: widget.displayThumbColor,
                    strokeWidth: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
