import 'package:flutter/material.dart';

class PopupMenuZoom extends PopupMenuEntry<void> {
  PopupMenuZoom({
    Key key,
    @required this.initialValue,
    this.onChanged,
  }) : super(key: key);

  @override
  represents(void value) => false;

  @override
  createState() => _PopupMenuZoomState();

  @override
  // this value doesn't seems to do anything?
  final double height = 48.0;

  final int initialValue;
  final void Function(double) onChanged;
}

class _PopupMenuZoomState extends State<PopupMenuZoom> {
  @override
  initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
  }

  @override
  build(BuildContext context) {
    return Slider(
      value: _value,
      min: 0,
      max: 2,
      divisions: 2,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
        widget.onChanged?.call(value);
      },
    );
  }

  var _value = 0.0;
}
