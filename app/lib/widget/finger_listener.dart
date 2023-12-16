import 'package:flutter/material.dart';

class FingerListener extends StatefulWidget {
  const FingerListener({
    super.key,
    required this.child,
    this.onFingerChanged,
    this.onPointerMove,
  });

  @override
  State<StatefulWidget> createState() => _FingerListenerState();

  final Widget? child;
  final void Function(int finger)? onFingerChanged;

  final PointerMoveEventListener? onPointerMove;
}

class _FingerListenerState extends State<FingerListener> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        ++_finger;
        widget.onFingerChanged?.call(_finger);
      },
      onPointerUp: (_) {
        --_finger;
        widget.onFingerChanged?.call(_finger);
      },
      onPointerCancel: (_) {
        --_finger;
        widget.onFingerChanged?.call(_finger);
      },
      onPointerMove: widget.onPointerMove,
      child: widget.child,
    );
  }

  var _finger = 0;
}
