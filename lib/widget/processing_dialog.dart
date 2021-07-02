import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ProcessingDialog extends StatelessWidget {
  ProcessingDialog({
    Key key,
    @required this.text,
  });

  @override
  build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(text),
          ],
        ),
      ),
    );
  }

  final String text;
}
