import 'package:flutter/material.dart';
import 'package:nc_photos/widget/app_intermediate_circular_progress_indicator.dart';

class AppBarProgressIndicator extends StatelessWidget {
  const AppBarProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 24,
        child: AppIntermediateCircularProgressIndicator(),
      ),
    );
  }
}
