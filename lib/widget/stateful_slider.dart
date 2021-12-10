import 'package:flutter/material.dart';

/// Slider with state
class StatefulSlider extends StatefulWidget {
  const StatefulSlider({
    Key? key,
    required this.initialValue,
    this.min = 0.0,
    this.max = 1.0,
    this.onChangeEnd,
  }) : super(key: key);

  @override
  createState() => _StatefulSliderState();

  final double initialValue;
  final double min;
  final double max;
  final ValueChanged<double>? onChangeEnd;
}

class _StatefulSliderState extends State<StatefulSlider> {
  @override
  initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  build(BuildContext context) {
    return Slider(
      value: _value,
      min: widget.min,
      max: widget.max,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
      onChangeEnd: widget.onChangeEnd,
    );
  }

  late double _value;
}
