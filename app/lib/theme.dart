import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/material3.dart';
import 'package:nc_photos/pref.dart';

enum SeedColor {
  // the order must NOT change
  amber,
  blue,
  green,
  purple,
  red;

  Color toColor() {
    switch (this) {
      case amber:
        return const Color(0xFFFFC107);
      case blue:
        return const Color(0xFF2196F3);
      case green:
        return const Color(0xFF4CAF50);
      case purple:
        return const Color(0xFF9C27B0);
      case red:
        return const Color(0xFFF44336);
    }
  }
}

extension ThemeExtension on ThemeData {
  double get widthLimitedContentMaxWidth => 550.0;

  Color get listPlaceholderBackgroundColor =>
      colorScheme.secondaryContainer.withOpacity(.6);

  Color get listPlaceholderForegroundColor =>
      colorScheme.onSecondaryContainer.withOpacity(.7);

  Color get homeNavigationBarBackgroundColor =>
      elevate(colorScheme.surface, 2).withOpacity(.77);

  Color get onDarkSurface {
    return brightness == Brightness.light
        ? colorScheme.onInverseSurface
        : colorScheme.onSurface;
  }

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

ThemeData buildTheme(Brightness brightness) {
  return (brightness == Brightness.light)
      ? buildLightTheme()
      : buildDarkTheme();
}

ThemeData buildLightTheme() {
  final seedColor = getSeedColor();
  final color = seedColor.toColor();
  final colorScheme = ColorScheme.fromSeed(
    seedColor: color,
  );
  return _applyColorScheme(colorScheme, color);
}

ThemeData buildDarkTheme() {
  final seedColor = getSeedColor();
  final color = seedColor.toColor();
  final colorScheme = ColorScheme.fromSeed(
    seedColor: color,
    brightness: Brightness.dark,
  );
  if (Pref().isUseBlackInDarkThemeOr(false)) {
    return _applyColorScheme(
      colorScheme.copyWith(
        background: Colors.black,
        surface: Colors.grey[900],
      ),
      color,
    );
  } else {
    return _applyColorScheme(colorScheme, color);
  }
}

ThemeData buildDarkModeSwitchTheme(BuildContext context) {
  final theme = Theme.of(context);
  return theme.copyWith(
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(theme.colorScheme.surfaceVariant),
      thumbColor: MaterialStateProperty.all(Colors.black87),
    ),
  );
}

SeedColor getSeedColor() {
  final index = Pref().getSeedColor();
  if (index == null) {
    return SeedColor.blue;
  } else {
    SeedColor seedColor;
    try {
      seedColor = SeedColor.values[index];
    } catch (e, stackTrace) {
      _log.severe("[getSeedColor] Uncaught exception", e, stackTrace);
      seedColor = SeedColor.blue;
    }
    return seedColor;
  }
}

ThemeData _applyColorScheme(ColorScheme colorScheme, Color seedColor) {
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
    ),
    extensions: [
      M3(
        seed: seedColor,
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
    ],
  );
}

final _log = Logger("theme");
