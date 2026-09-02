part of 'image_editor.dart';

class _MarkupCanvas extends StatefulWidget {
  const _MarkupCanvas();

  @override
  State<StatefulWidget> createState() => _MarkupCanvasState();
}

class _MarkupCanvasState extends State<_MarkupCanvas> {
  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.src != current.src ||
          previous.dst != current.dst ||
          previous.markupFilter != current.markupFilter ||
          previous.appliedStrokeIds != current.appliedStrokeIds,
      builder: (context, state) {
        final image = state.dst ?? state.src!;
        final pendingStrokes = state.markupFilter.strokes
            .where((s) => !state.appliedStrokeIds.contains(s.id))
            .toList();
        return Center(
          child: AspectRatio(
            aspectRatio: image.width / image.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = constraints.biggest;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: PixelImage(image.pixel, image.width, image.height),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        setState(() {
                          _currentStroke = [_normalize(details.localPosition)];
                        });
                      },
                      onPanUpdate: (details) {
                        final p = _normalize(details.localPosition);
                        if (_currentStroke.isNotEmpty) {
                          final last = _currentStroke.last;
                          // reduce point resolution to lower point counts
                          if (pow(p.x - last.x, 2) + pow(p.y - last.y, 2) <
                              0.0004) {
                            return;
                          }
                        }
                        setState(() {
                          _currentStroke = _currentStroke.added(p);
                        });
                      },
                      onPanEnd: (_) {
                        if (_currentStroke.isNotEmpty) {
                          context.addEvent(_AddBrushStroke(_currentStroke));
                        }
                        setState(() {
                          _currentStroke = [];
                        });
                      },
                      child: CustomPaint(
                        painter: _BrushPainter(
                          strokes: [
                            ...pendingStrokes,
                            BrushStroke(
                              id: -1,
                              points: _currentStroke,
                              radius: state.markupFilter.radius,
                              color: state.markupFilter.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Point<double> _normalize(Offset local) {
    final s = _canvasSize;
    if (s == null || s.width == 0 || s.height == 0) {
      return const Point(0, 0);
    }
    return Point(
      (local.dx / s.width).clamp(0, 1),
      (local.dy / s.height).clamp(0, 1),
    );
  }

  Size? _canvasSize;
  List<Point<double>> _currentStroke = [];
}

class _BrushPainter extends CustomPainter {
  const _BrushPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.radius * 2 * size.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      _paintStroke(canvas, size, s.points, paint);
    }
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Size size, List<Point> stroke, Paint paint) {
    if (stroke.isEmpty) {
      return;
    }
    if (stroke.length == 1) {
      canvas.drawCircle(
        Offset(stroke[0].x * size.width, stroke[0].y * size.height),
        paint.strokeWidth / 2,
        Paint()..color = paint.color,
      );
    } else {
      final path = Path()
        ..moveTo(stroke[0].x * size.width, stroke[0].y * size.height);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.x * size.width, p.y * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushPainter oldDelegate) =>
      oldDelegate.strokes != strokes;

  final List<BrushStroke> strokes;
}
