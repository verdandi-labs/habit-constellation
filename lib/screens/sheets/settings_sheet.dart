import 'package:flutter/material.dart';
import 'package:habit_constellation/theme.dart';

class SettingsSheet extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsSheet({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(top: 120),
            decoration: const BoxDecoration(
              color: Color(0xFF0E1224),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 32, height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Settings',
                  style: kRaleway(size: 18, weight: FontWeight.w300, color: const Color(0xFFB8C8E0))),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x33FF5050)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Log out',
                      textAlign: TextAlign.center,
                      style: kInter(size: 14, color: const Color(0x80FF7878))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
