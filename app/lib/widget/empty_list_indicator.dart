import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EmptyListIndicator extends StatelessWidget {
  const EmptyListIndicator({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 72,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  final IconData icon;
  final String text;
}
