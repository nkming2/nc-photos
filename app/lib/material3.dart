import 'package:flutter/material.dart';

class M3 extends ThemeExtension<M3> {
  const M3({
    required this.seed,
    required this.checkbox,
    required this.assistChip,
    required this.filterChip,
    required this.listTile,
  });

  static M3 of(BuildContext context) => Theme.of(context).extension<M3>()!;

  @override
  M3 copyWith({
    Color? seed,
    M3Checkbox? checkbox,
    M3AssistChip? assistChip,
    M3FilterChip? filterChip,
    M3ListTile? listTile,
  }) =>
      M3(
        seed: seed ?? this.seed,
        checkbox: checkbox ?? this.checkbox,
        assistChip: assistChip ?? this.assistChip,
        filterChip: filterChip ?? this.filterChip,
        listTile: listTile ?? this.listTile,
      );

  @override
  M3 lerp(ThemeExtension<M3>? other, double t) {
    if (other is! M3) {
      return this;
    }
    return M3(
      seed: Color.lerp(seed, other.seed, t)!,
      checkbox: checkbox.lerp(other.checkbox, t),
      assistChip: assistChip.lerp(other.assistChip, t),
      filterChip: filterChip.lerp(other.filterChip, t),
      listTile: listTile.lerp(other.listTile, t),
    );
  }

  final Color seed;
  final M3Checkbox checkbox;
  final M3AssistChip assistChip;
  final M3FilterChip filterChip;
  final M3ListTile listTile;
}

class M3Checkbox {
  const M3Checkbox({
    required this.disabled,
  });

  M3Checkbox lerp(M3Checkbox? other, double t) {
    if (other is! M3Checkbox) {
      return this;
    }
    return M3Checkbox(
      disabled: disabled.lerp(other.disabled, t),
    );
  }

  final M3CheckboxDisabled disabled;
}

class M3CheckboxDisabled {
  const M3CheckboxDisabled({
    required this.container,
  });

  M3CheckboxDisabled lerp(M3CheckboxDisabled? other, double t) {
    if (other is! M3CheckboxDisabled) {
      return this;
    }
    return M3CheckboxDisabled(
      container: Color.lerp(container, other.container, t)!,
    );
  }

  final Color container;
}

class M3AssistChip {
  const M3AssistChip({
    required this.enabled,
  });

  M3AssistChip lerp(M3AssistChip? other, double t) {
    if (other is! M3AssistChip) {
      return this;
    }
    return M3AssistChip(
      enabled: enabled.lerp(other.enabled, t),
    );
  }

  final M3AssistChipEnabled enabled;
}

class M3AssistChipEnabled {
  const M3AssistChipEnabled({
    required this.container,
    required this.containerElevated,
  });

  M3AssistChipEnabled lerp(M3AssistChipEnabled? other, double t) {
    if (other is! M3AssistChipEnabled) {
      return this;
    }
    return M3AssistChipEnabled(
      container: Color.lerp(container, other.container, t)!,
      containerElevated:
          Color.lerp(containerElevated, other.containerElevated, t)!,
    );
  }

  final Color container;
  final Color containerElevated;
}

class M3FilterChip {
  const M3FilterChip({
    required this.disabled,
  });

  M3FilterChip lerp(M3FilterChip? other, double t) {
    if (other is! M3FilterChip) {
      return this;
    }
    return M3FilterChip(
      disabled: disabled.lerp(other.disabled, t),
    );
  }

  final M3FilterChipDisabled disabled;
}

class M3FilterChipDisabled {
  const M3FilterChipDisabled({
    required this.containerSelected,
    required this.labelText,
  });

  M3FilterChipDisabled lerp(M3FilterChipDisabled? other, double t) {
    if (other is! M3FilterChipDisabled) {
      return this;
    }
    return M3FilterChipDisabled(
      containerSelected:
          Color.lerp(containerSelected, other.containerSelected, t)!,
      labelText: Color.lerp(labelText, other.labelText, t)!,
    );
  }

  final Color containerSelected;
  final Color labelText;
}

class M3ListTile {
  const M3ListTile({
    required this.enabled,
  });

  M3ListTile lerp(M3ListTile? other, double t) {
    if (other is! M3ListTile) {
      return this;
    }
    return M3ListTile(
      enabled: enabled.lerp(other.enabled, t),
    );
  }

  final M3ListTileEnabled enabled;
}

class M3ListTileEnabled {
  const M3ListTileEnabled({
    required this.headline,
    required this.supportingText,
  });

  M3ListTileEnabled lerp(M3ListTileEnabled? other, double t) {
    if (other is! M3ListTileEnabled) {
      return this;
    }
    return M3ListTileEnabled(
      headline: Color.lerp(headline, other.headline, t)!,
      supportingText: Color.lerp(supportingText, other.supportingText, t)!,
    );
  }

  final Color headline;
  final Color supportingText;
}
