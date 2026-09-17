import 'package:flutter/material.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/models/habit.dart';

class EditHabitSheet extends StatefulWidget {
  final HabitWithTodayLog habit;
  final void Function(String) onRename;
  final VoidCallback onDelete;

  const EditHabitSheet({
    super.key,
    required this.habit,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends State<EditHabitSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.habit.name);
  }

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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: kInter(size: 15, color: const Color(0xFFD0D8E8)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final name = _controller.text.trim();
                        if (name.isNotEmpty && name.length <= 60) {
                          widget.onRename(name);
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Text('Save', style: kInter(size: 13, color: const Color(0xFFB8C8E0))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x33FF5050)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Delete habit',
                      textAlign: TextAlign.center,
                      style: kInter(size: 14, color: const Color(0x80FF7878))),
                  ),
                ),
                const SizedBox(height: 10),
                Text('It disappears from today, but its stars remain in your past skies.',
                  textAlign: TextAlign.center,
                  style: kInter(size: 11, color: const Color(0xFF4A5570))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
