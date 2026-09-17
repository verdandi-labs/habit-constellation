import 'package:flutter/material.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/models/habit.dart';

class CommentSheet extends StatefulWidget {
  final HabitWithTodayLog habit;
  final String? existingComment;
  final bool hasLog;
  final void Function(String) onSave;
  final VoidCallback onDelete;

  const CommentSheet({
    super.key,
    required this.habit,
    this.existingComment,
    required this.hasLog,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingComment ?? '');
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
                const SizedBox(height: 20),
                Text(widget.habit.name,
                  style: kInter(size: 11, spacing: 0.07, color: const Color(0xFF4A5570))),
                const SizedBox(height: 4),
                Text('How did you feel?',
                  style: kRaleway(size: 20, weight: FontWeight.w300, color: const Color(0xFFD0D8E8))),
                const SizedBox(height: 18),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 4,
                  style: kInter(size: 15, color: const Color(0xFFD0D8E8)),
                  decoration: InputDecoration(
                    hintText: 'Write a note…',
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
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.existingComment != null)
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Text('Delete note',
                          style: kInter(size: 13, color: const Color(0xFF4A5570))),
                      )
                    else
                      const SizedBox(),
                    GestureDetector(
                      onTap: () {
                        widget.onSave(_controller.text);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Text('Save', style: kInter(size: 14, color: const Color(0xFFB8C8E0))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
