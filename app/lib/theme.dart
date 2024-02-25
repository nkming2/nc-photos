import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/theme/dimension.dart';
import 'package:np_ui/np_ui.dart';

const defaultSeedColor = Color(0xFF2196F3);

extension ThemeExtension on ThemeData {
  double get widthLimitedContentMaxWidth => 550.0;

  Color get listPlaceholderBackgroundColor =>
      colorScheme.secondaryContainer.withOpacity(.6);

  Color get listPlaceholderForegroundColor =>
      colorScheme.onSecondaryContainer.withOpacity(.7);

  Color get homeNavigationBarBackgroundColor =>
      elevate(colorScheme.surface, 2).withOpacity(.55);

  Color get onDarkSurface {
    return brightness == Brightness.light
        ? colorScheme.onInverseSurface
        : colorScheme.onSurface;
  }

  ImageFilter get appBarBlurFilter => ImageFilter.blur(
        sigmaX: 12,
        sigmaY: 12,
        tileMode: TileMode.mirror,
      );

  Color get nextcloudBlue => const Color(0xFF0082C9);

  /// Apply surface tint to [color] based on the [elevation] level
  ///
  /// This function is a temporary workaround for widgets not yet fully
  /// supported Material 3
  Color elevate(Color color, int elevation) {
    final double tintOpacity;
    switch (elevation) {
      case 1:
        tintOpacity = 0.05;
        break;
      case 2:
        tintOpacity = 0.08;
        break;
      case 3:
        tintOpacity = 0.11;
        break;
      case 4:
        tintOpacity = 0.12;
        break;
      case 5:
      default:
        tintOpacity = 0.14;
        break;
    }
    return Color.lerp(color, colorScheme.surfaceTint, tintOpacity)!;
  }
}

class DarkModeSwitchTheme extends StatelessWidget {
  const DarkModeSwitchTheme({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        switchTheme: SwitchThemeData(
          trackColor: MaterialStateProperty.all(theme.colorScheme.surface),
          thumbColor: MaterialStateProperty.all(Colors.black87),
        ),
        colorScheme: theme.colorScheme.copyWith(
          outline: Colors.transparent,
        ),
      ),
      child: child,
    );
  }

  final Widget child;
}

ThemeData buildTheme(BuildContext context, Brightness brightness) {
  return (brightness == Brightness.light)
      ? buildLightTheme(context)
      : buildDarkTheme(context);
}

ThemeData buildLightTheme(BuildContext context, [ColorScheme? dynamicScheme]) {
  final colorScheme = _getColorScheme(context, dynamicScheme, Brightness.light);
  return _applyColorScheme(colorScheme);
}

ThemeData buildDarkTheme(BuildContext context, [ColorScheme? dynamicScheme]) {
  final colorScheme = _getColorScheme(context, dynamicScheme, Brightness.dark);
  if (context.read<PrefController>().isUseBlackInDarkTheme.value) {
    return _applyColorScheme(colorScheme.copyWith(
      background: Colors.black,
      surface: Colors.grey[900],
    ));
  } else {
    return _applyColorScheme(colorScheme);
  }
}

Color? getSeedColor(BuildContext context) {
  return context.read<PrefController>().seedColorValue;
}

ColorScheme _getColorScheme(
    BuildContext context, ColorScheme? dynamicScheme, Brightness brightness) {
  var seedColor = getSeedColor(context);
  if (seedColor == null) {
    if (dynamicScheme != null) {
      return dynamicScheme;
    } else {
      seedColor = defaultSeedColor;
    }
  }
  return ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
}

ThemeData _applyColorScheme(ColorScheme colorScheme) {
  return ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.background,
      foregroundColor: colorScheme.onSurface,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
    ),
    iconTheme: IconThemeData(
      color: colorScheme.onSurfaceVariant,
    ),
    // remove after dialog supports m3
    dialogBackgroundColor:
        Color.lerp(colorScheme.surface, colorScheme.surfaceTint, 0.11),
    popupMenuTheme: PopupMenuThemeData(
      // remove after menu supports m3
      color: Color.lerp(colorScheme.surface, colorScheme.surfaceTint, 0.08),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      // default for Material 3
      height: 80,
    ),
    // remove after checkbox supports m3
    // see: https://m3.material.io/components/checkbox/specs
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return colorScheme.onSurface;
        } else {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          } else {
            return Colors.transparent;
          }
        }
      }),
      checkColor: MaterialStateProperty.all(colorScheme.onPrimary),
    ),
    // remove after checkbox supports m3
    // see: https://m3.material.io/components/switch/specs
    // the color here is slightly modified to work better with the M2 switch
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.onSurface.withOpacity(.12);
          } else {
            return colorScheme.surfaceVariant.withOpacity(.12);
          }
        } else {
          if (states.contains(MaterialState.selected)) {
            // return colorScheme.primary;
            return colorScheme.primaryContainer;
          } else {
            return colorScheme.surfaceVariant;
          }
        }
      }),
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          if (states.contains(MaterialState.selected)) {
            // return colorScheme.surface;
            return colorScheme.onSurface.withOpacity(.38);
          } else {
            return colorScheme.onSurface.withOpacity(.38);
          }
        } else {
          if (states.contains(MaterialState.selected)) {
            // return colorScheme.onPrimary;
            return colorScheme.primary;
          } else {
            return colorScheme.outline;
          }
        }
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.inversePrimary,
      behavior: SnackBarBehavior.floating,
    ),
    extensions: [
      M3(
        checkbox: M3Checkbox(
          disabled: M3CheckboxDisabled(
            container: colorScheme.onSurface.withOpacity(.38),
          ),
        ),
        filterChip: M3FilterChip(
          disabled: M3FilterChipDisabled(
            containerSelected: colorScheme.onSurface.withOpacity(.12),
            labelText: colorScheme.onSurface.withOpacity(.38),
          ),
        ),
        listTile: M3ListTile(
          enabled: M3ListTileEnabled(
            headline: colorScheme.onSurface,
            supportingText: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const AppDimension(
        homeBottomAppBarHeight: 68,
      ),
    ],
  );
}

extension BrightnessExtension on Brightness {
  Brightness invert() {
    switch (this) {
      case Brightness.dark:
        return Brightness.light;
      case Brightness.light:
        return Brightness.dark;
    }
  }
}
