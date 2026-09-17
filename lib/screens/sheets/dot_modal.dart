import 'package:flutter/material.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/models/log.dart';

class DotModal extends StatelessWidget {
  final LogEntry log;

  const DotModal({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0E1224),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32, height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(log.logDate,
                    style: kInter(size: 11, spacing: 0.08, color: const Color(0xFF4A5570))),
                  const SizedBox(height: 6),
                  Text(log.habitName,
                    style: kRaleway(size: 17, weight: FontWeight.w300, color: const Color(0xFFD0D8E8))),
                  if (log.comment != null && log.comment!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('"${log.comment}"',
                      style: kInter(size: 13.5, spacing: 0.02, color: const Color(0xFF7888A0))),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
