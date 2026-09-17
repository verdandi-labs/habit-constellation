import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final String active;
  final VoidCallback onHome;
  final VoidCallback onConstellation;

  const BottomNav({
    super.key,
    required this.active,
    required this.onHome,
    required this.onConstellation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: active == 'home' ? 0 : 1,
        onDestinationSelected: (i) => i == 0 ? onHome() : onConstellation(),
        backgroundColor: const Color(0xEE07091C),
        indicatorColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white38),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined, color: Colors.white38),
            selectedIcon: Icon(Icons.auto_awesome, color: Colors.white),
            label: '',
          ),
        ],
      ),
    );
  }
}
