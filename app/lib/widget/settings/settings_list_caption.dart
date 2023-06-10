import 'package:flutter/material.dart';

class SettingsListCaption extends StatelessWidget {
  const SettingsListCaption({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  final String label;
}
