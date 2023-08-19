part of '../theme_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.isFollowSystemTheme,
    required this.isUseBlackInDarkTheme,
    required this.seedColor,
    this.error,
  });

  @override
  String toString() => _$toString();

  final bool isFollowSystemTheme;
  final bool isUseBlackInDarkTheme;
  // workaround analyzer bug where Color type can't be recognized
  final int? seedColor;

  final ExceptionEvent? error;
}

abstract class _Event {
  const _Event();
}

@toString
class _Init implements _Event {
  const _Init();

  @override
  String toString() => _$toString();
}

@toString
class _SetFollowSystemTheme extends _Event {
  const _SetFollowSystemTheme(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}

@toString
class _SetUseBlackInDarkTheme extends _Event {
  const _SetUseBlackInDarkTheme(this.value, this.theme);

  @override
  String toString() => _$toString();

  final bool value;
  final ThemeData theme;
}

@toString
class _SetSeedColor extends _Event {
  const _SetSeedColor(this.value);

  @override
  String toString() => _$toString();

  final Color? value;
}
