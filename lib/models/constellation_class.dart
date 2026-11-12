import 'dart:ui' show Offset;

class ConstellationTemplate {
  final String name;
  final double width;
  final double height;
  final List<Offset> points;
  final List<(int, int)> lines;

  const ConstellationTemplate({
    required this.name,
    required this.width,
    required this.height,
    required this.points,
    required this.lines,
  });
}
