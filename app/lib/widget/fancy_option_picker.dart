import 'package:flutter/material.dart';

class FancyOptionPickerItem {
  FancyOptionPickerItem({
    required this.label,
    this.description,
    this.isSelected = false,
    this.onSelect,
    this.onUnselect,
    this.dense = false,
  });

  String label;
  String? description;
  bool isSelected;
  VoidCallback? onSelect;
  VoidCallback? onUnselect;
  bool dense;
}

/// A fancy looking dialog to pick an option
class FancyOptionPicker extends StatelessWidget {
  const FancyOptionPicker({
    Key? key,
    this.title,
    required this.items,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return SimpleDialog(
      title: title != null ? Text(title!) : null,
      children: items
          .map((e) => SimpleDialogOption(
                child: ListTile(
                  leading: Icon(
                    e.isSelected ? Icons.check : null,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    e.label,
                    style: e.isSelected
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  subtitle: e.description == null ? null : Text(e.description!),
                  onTap: e.isSelected ? e.onUnselect : e.onSelect,
                  dense: e.dense,
                ),
              ))
          .toList(),
    );
  }

  final String? title;
  final List<FancyOptionPickerItem> items;
}
