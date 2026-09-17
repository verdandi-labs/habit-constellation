import 'package:flutter/material.dart';

const Color kSilver = Color(0xFFBCCDE4);
const Color kBlueGlow = Color(0xFF7AB6E0);
const Color kText = Color(0xFFFFFFFF);
const List<Color> kStarColors = [
  Color(0xFFFFFFFF), Color(0xFFF2F2F6), Color(0xFFE8E9F2),
  Color(0xFFDDE0ED), Color(0xFFD4D8E8), Color(0xFFCDD2E4),
  Color(0xFFC4CCE0), Color(0xFFBBC4DB), Color(0xFFB4BED8),
];

BoxDecoration get kBg => const BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(-0.8, 0.8),
    radius: 1.4,
    colors: [Color(0xFF14083A), Color(0xFF07091C)],
  ),
);

TextStyle kRaleway({double size = 16, FontWeight weight = FontWeight.w300, double spacing = 0.05, Color color = const Color(0xFFB8C8E0)}) =>
    TextStyle(fontFamily: 'Raleway', fontSize: size, fontWeight: weight, letterSpacing: spacing, color: color);

TextStyle kInter({double size = 14, FontWeight weight = FontWeight.w300, double spacing = 0.03, Color color = const Color(0xFF7888A0)}) =>
    TextStyle(fontFamily: 'Inter', fontSize: size, fontWeight: weight, letterSpacing: spacing, color: color);
