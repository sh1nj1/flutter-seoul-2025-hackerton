import 'package:flutter/material.dart';

import 'stroke.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({
    super.key,
    required this.strokes,
    this.inProgress,
  });

  final List<Stroke> strokes;
  final Stroke? inProgress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StrokePainter(
        strokes: strokes,
        inProgress: inProgress,
      ),
      size: Size.infinite,
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({
    required this.strokes,
    required this.inProgress,
  });

  final List<Stroke> strokes;
  final Stroke? inProgress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final Stroke stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (inProgress != null && !inProgress!.isEmpty) {
      _paintStroke(canvas, inProgress!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    final Paint paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final Offset p1 = stroke.points[i];
      final Offset p2 = stroke.points[i + 1];
      canvas.drawLine(p1, p2, paint);
    }

    if (stroke.points.length == 1) {
      final Paint dotPaint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(stroke.points.first, stroke.width / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return true;
  }
}
