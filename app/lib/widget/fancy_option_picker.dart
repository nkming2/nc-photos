import 'package:flutter/material.dart';
import 'package:nc_photos/object_extension.dart';

class FancyOptionPickerItem {
  const FancyOptionPickerItem({
    required this.label,
    this.description,
    this.isSelected = false,
    this.onSelect,
    this.onUnselect,
    this.dense = false,
  });

  final String label;
  final String? description;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onUnselect;
  final bool dense;
}

/// A fancy looking dialog to pick an option
class FancyOptionPicker extends StatelessWidget {
  const FancyOptionPicker({
    Key? key,
    this.title,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: title != null ? Text(title!) : null,
      children: items
          .map((e) => SimpleDialogOption(
                child: FancyOptionPickerItemView(
                  label: e.label,
                  description: e.description,
                  isSelected: e.isSelected,
                  onSelect: e.onSelect,
                  onUnselect: e.onUnselect,
                  dense: e.dense,
                ),
              ))
          .toList(),
    );
  }

  final String? title;
  final List<FancyOptionPickerItem> items;
}

class FancyOptionPickerItemView extends StatelessWidget {
  const FancyOptionPickerItemView({
    super.key,
    required this.label,
    this.description,
    required this.isSelected,
    this.onSelect,
    this.onUnselect,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check : null,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        label,
        style: isSelected
            ? TextStyle(
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
      subtitle: description?.run(Text.new),
      onTap: isSelected ? onUnselect : onSelect,
      dense: dense,
    );
  }

  final String label;
  final String? description;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onUnselect;
  final bool dense;
}
