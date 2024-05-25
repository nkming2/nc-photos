import 'package:flutter/material.dart';

class ProcessingDialog extends StatelessWidget {
  const ProcessingDialog({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(text),
          ],
        ),
      ),
    );
  }

  final String text;
}
