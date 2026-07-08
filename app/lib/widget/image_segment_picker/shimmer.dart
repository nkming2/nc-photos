part of 'image_segment_picker.dart';

class _DotShimmerOverlay extends StatefulWidget {
  const _DotShimmerOverlay();

  @override
  State<StatefulWidget> createState() => _DotShimmerOverlayState();
}

class _DotShimmerOverlayState extends State<_DotShimmerOverlay>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: -1)
      ..repeat(min: -1, max: 2, period: const Duration(milliseconds: 2500));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(painter: _DotShimmerPainter(value: _controller.value)),
    );
  }

  late final AnimationController _controller;
}

class _DotShimmerPainter extends CustomPainter {
  const _DotShimmerPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0x00FFFFFF),
        Color(0x0DFFFFFF),
        Color(0x80FFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: const [.3, .4, .95, 1],
      transform: _DotShimmerTransform(value),
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      for (var x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotShimmerPainter oldDelegate) =>
      oldDelegate.value != value;

  final double value;

  static const _dotRadius = 2.0;
  static const _spacing = 16.0;
}

class _DotShimmerTransform extends GradientTransform {
  const _DotShimmerTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(0, bounds.height * value, 0);
  }

  final double value;
}
