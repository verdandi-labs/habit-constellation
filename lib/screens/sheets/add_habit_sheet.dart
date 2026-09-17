import 'package:flutter/material.dart';
import 'package:habit_constellation/theme.dart';

class AddHabitSheet extends StatefulWidget {
  final void Function(String) onAdd;

  const AddHabitSheet({super.key, required this.onAdd});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _controller = TextEditingController();
  bool _added = false;

  static const _suggestions = [
    'Meditate', 'Stretch', 'Yoga', 'Walk outside', 'Journal', 'Cold shower',
  ];

  void _handleAdd(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) return;
    widget.onAdd(trimmed);
    _controller.clear();
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _added = false);
    });
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
                          hintText: 'Name your habit…',
                          hintStyle: kInter(size: 15, color: const Color(0xFF4A5570)),
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
                        onSubmitted: _handleAdd,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _handleAdd(_controller.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Text(_added ? 'added ✓' : 'Save',
                          style: kInter(size: 13,
                            color: _added ? const Color(0xFF90C090) : const Color(0xFFB8C8E0))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((s) => GestureDetector(
                    onTap: () => _handleAdd(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s, style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.35),
                      )),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
