import 'dart:ui';

class Stroke {
  Stroke({required this.color, required this.width});

  final Color color;
  final double width;
  final List<Offset> points = <Offset>[];

  bool get isEmpty => points.isEmpty;

  void addPoint(Offset point) {
    points.add(point);
  }
}
