import 'package:flutter/material.dart';

class SwitchFormField extends FormField<bool> {
  SwitchFormField({
    Key? key,
    required bool initialValue,
    Widget? title,
    Widget? subtitle,
    Widget? subtitleTrue,
    Widget? subtitleFalse,
    bool? dense,
    FormFieldSetter<bool>? onSaved,
    FormFieldValidator<bool>? validator,
    bool enabled = true,
    AutovalidateMode? autovalidateMode,
  }) : super(
          key: key,
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue,
          enabled: enabled,
          autovalidateMode: autovalidateMode,
          builder: (field) {
            final value = field.value ?? initialValue;
            return SwitchListTile(
              value: value,
              contentPadding: const EdgeInsets.all(0),
              title: title,
              subtitle: value
                  ? (subtitleTrue ?? subtitle)
                  : (subtitleFalse ?? subtitle),
              dense: dense,
              onChanged: field.didChange,
            );
          },
        );
}
