part of '../collection_browser.dart';

class _LabelView extends StatelessWidget {
  const _LabelView({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoListLabel(text: text);
  }

  final String text;
}

class _EditLabelView extends StatelessWidget {
  const _EditLabelView({
    required this.text,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoListLabelEdit(
      text: text,
      onEditPressed: onEditPressed,
    );
  }

  final String text;
  final VoidCallback? onEditPressed;
}
