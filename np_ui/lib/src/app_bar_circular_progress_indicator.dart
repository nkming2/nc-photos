import 'package:flutter/material.dart';

class AppBarCircularProgressIndicator extends StatelessWidget {
  const AppBarCircularProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
        ),
      ),
    );
  }
}
