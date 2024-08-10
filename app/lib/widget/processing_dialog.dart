import 'package:flutter/material.dart';
import 'package:nc_photos/widget/app_intermediate_circular_progress_indicator.dart';

class ProcessingDialog extends StatelessWidget {
  const ProcessingDialog({
    super.key,
    required this.text,
  });

  @override
  build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIntermediateCircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(text),
          ],
        ),
      ),
    );
  }

  final String text;
}
