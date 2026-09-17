import 'dart:math';
import 'package:flutter/material.dart';
import 'package:clock/clock.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/models/log.dart';
import 'package:habit_constellation/services/seeded_rng.dart';
import 'package:habit_constellation/widgets/bottom_nav.dart';
import 'package:habit_constellation/screens/sheets/dot_modal.dart';

class ConstellationScreen extends StatefulWidget {
  final List<LogRegistryItem> habits;
  final List<LogEntry> logs;

  const ConstellationScreen({
    super.key,
    required this.habits,
    required this.logs,
  });

  @override
  State<ConstellationScreen> createState() => _ConstellationScreenState();
}

class _ConstellationScreenState extends State<ConstellationScreen> {
  late int _viewYear;
  late int _viewMonth;
  bool _showLines = false;

  @override
  void initState() {
    super.initState();
    final now = clock.now();
    _viewYear = now.year;
    _viewMonth = now.month;
  }

  bool get _isCurrent {
    final now = clock.now();
    return _viewYear == now.year && _viewMonth == now.month;
  }

  List<LogEntry> get _monthLogs {
    final prefix = '$_viewYear-${_viewMonth.toString().padLeft(2, '0')}';
    return widget.logs.where((l) => l.logDate.startsWith(prefix)).toList();
  }

  void _prevMonth() => setState(() {
    if (_viewMonth == 1) { _viewMonth = 12; _viewYear--; }
    else _viewMonth--;
  });

  void _nextMonth() {
    if (_isCurrent) return;
    setState(() {
      if (_viewMonth == 12) { _viewMonth = 1; _viewYear++; }
      else _viewMonth++;
    });
  }

  void _handleTap(BuildContext context, TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final tapPos = box.globalToLocal(details.globalPosition);

    for (final log in _monthLogs) {
      final hi = widget.habits.indexWhere((h) => h.id == log.habitId);
      if (hi == -1) continue;

      final rng = SeededRng('${log.id}-$hi');
      final day = int.tryParse(log.logDate.substring(8)) ?? 1;
      final laneHeight = 90.0;
      final laneCenter = (hi + 0.5) * laneHeight + 20;
      final jitterY = (rng.next() - 0.5) * laneHeight * 0.65;
      final jitterX = (rng.next() - 0.5) * 0.04 * box.size.width;
      final x = (day / 31) * (box.size.width - 24) + 12 + jitterX;
      final y = laneCenter + jitterY;

      final dist = (Offset(x, y) - tapPos).distance;
      if (dist < 24) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => DotModal(log: log),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    final monthLogs = _monthLogs;

    return Scaffold(
      body: Container(
        decoration: kBg,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 52, 24, 4),
                    child: Text('Small victories',
                      style: kRaleway(size: 22, weight: FontWeight.w200,
                        spacing: 0.18, color: const Color(0xFFA0B4CC))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _prevMonth,
                          child: Icon(Icons.chevron_left_rounded, size: 22,
                            color: Colors.white.withOpacity(0.38)),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 152,
                          child: Text('${months[_viewMonth - 1]} $_viewYear',
                            textAlign: TextAlign.center,
                            style: kInter(size: 12, spacing: 0.06, color: const Color(0xFF6878A0))),
                        ),
                        GestureDetector(
                          onTap: _nextMonth,
                          child: Icon(Icons.chevron_right_rounded, size: 22,
                            color: _isCurrent
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.38)),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showLines = !_showLines),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('lines ${_showLines ? 'on' : 'off'}',
                              style: kInter(size: 10.5, spacing: 0.04, color: const Color(0xFF6878A0))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: monthLogs.isEmpty
                      ? Center(
                          child: Text('This month\'s sky is dark.',
                            style: kInter(size: 13, color: const Color(0xFF3A4560))),
                        )
                      : GestureDetector(
                          onTapUp: (details) => _handleTap(context, details),
                          child: _ConstellationCanvas(
                            habits: widget.habits,
                            logs: monthLogs,
                            showLines: _showLines,
                          ),
                        ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: BottomNav(
                  active: 'constellation',
                  onHome: () => Navigator.of(context).pop(),
                  onConstellation: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstellationCanvas extends StatelessWidget {
  final List<LogRegistryItem> habits;
  final List<LogEntry> logs;
  final bool showLines;

  const _ConstellationCanvas({
    required this.habits,
    required this.logs,
    required this.showLines,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final laneHeight = 90.0;
        final canvasHeight = max(habits.length * laneHeight + 40, constraints.maxHeight);
        final habitMap = {for (var h in habits) h.id: h};

        return SingleChildScrollView(
          child: SizedBox(
            width: w,
            height: canvasHeight,
            child: CustomPaint(
              painter: _StarPainter(
                habits: habits,
                logs: logs,
                habitMap: habitMap,
                showLines: showLines,
                canvasWidth: w,
                canvasHeight: canvasHeight,
                laneHeight: laneHeight,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<LogRegistryItem> habits;
  final List<LogEntry> logs;
  final Map<String, LogRegistryItem> habitMap;
  final bool showLines;
  final double canvasWidth;
  final double canvasHeight;
  final double laneHeight;

  _StarPainter({
    required this.habits,
    required this.logs,
    required this.habitMap,
    required this.showLines,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.laneHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <_StarPosition>[];

    for (final log in logs) {
      final hi = habits.indexWhere((h) => h.id == log.habitId);
      if (hi == -1) continue;
      final habit = habits[hi];

      final rng = SeededRng('${log.id}-$hi');
      final day = int.tryParse(log.logDate.substring(8)) ?? 1;
      final laneCenter = (hi + 0.5) * laneHeight + 20;
      final jitterY = (rng.next() - 0.5) * laneHeight * 0.65;
      final jitterX = (rng.next() - 0.5) * 0.04 * canvasWidth;
      final x = (day / 31) * (canvasWidth - 24) + 12 + jitterX;
      final y = laneCenter + jitterY;
      final starSize = 1.5 + rng.next() * 2.5;
      final brightness = habit.archived ? 0.35 : 0.55 + rng.next() * 0.45;

      positions.add(_StarPosition(
        x: x, y: y, size: starSize, brightness: brightness,
        log: log, habit: habit,
      ));
    }

    if (showLines) {
      for (final habit in habits) {
        final habitPositions = positions
          .where((p) => p.habit.id == habit.id)
          .toList()
          ..sort((a, b) {
            final da = int.tryParse(a.log.logDate.substring(8)) ?? 0;
            final db = int.tryParse(b.log.logDate.substring(8)) ?? 0;
            return da - db;
          });
        if (habitPositions.length < 2) continue;

        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..strokeWidth = 0.7
          ..style = PaintingStyle.stroke;

        final path = Path();
        path.moveTo(habitPositions.first.x, habitPositions.first.y);
        for (int i = 1; i < habitPositions.length; i++) {
          path.lineTo(habitPositions[i].x, habitPositions[i].y);
        }
        canvas.drawPath(path, linePaint);
      }
    }

    for (final p in positions) {
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(p.brightness),
            const Color(0xFFDCE6FF).withOpacity(p.brightness * 0.6),
            const Color(0xFFC8DCFF).withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(p.x, p.y), radius: p.size * 2.5));

      canvas.drawCircle(Offset(p.x, p.y), p.size * 2.5, gradientPaint);

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(p.brightness);
      canvas.drawCircle(Offset(p.x, p.y), p.size, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return oldDelegate.showLines != showLines ||
        oldDelegate.logs.length != logs.length ||
        oldDelegate.habits.length != habits.length;
  }
}

class _StarPosition {
  final double x, y, size, brightness;
  final LogEntry log;
  final LogRegistryItem habit;

  const _StarPosition({
    required this.x, required this.y, required this.size,
    required this.brightness, required this.log, required this.habit,
  });
}
