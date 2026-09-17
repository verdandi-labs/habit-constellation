import 'package:flutter/material.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/services/reminder_service.dart';

class SettingsSheet extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsSheet({super.key, required this.onLogout});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _reminderService = ReminderService();
  bool _reminderEnabled = false;
  int _reminderHour = 16;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final enabled = await _reminderService.isEnabled;
    final (h, m) = await _reminderService.scheduledTime;
    setState(() {
      _reminderEnabled = enabled;
      _reminderHour = h;
      _reminderMinute = m;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    await _reminderService.setEnabled(value);
    if (value) await _reminderService.setTime(_reminderHour, _reminderMinute);
    setState(() => _reminderEnabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              surface: Color(0xFF0E1224),
              primary: Color(0xFF7AB6E0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
      await _reminderService.setTime(_reminderHour, _reminderMinute);
      setState(() {});
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0E1224),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log out of Habit Constellation?',
          style: kRaleway(size: 16, weight: FontWeight.w300, color: const Color(0xFFB8C8E0))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: kInter(size: 14, color: const Color(0xFF7888A0))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            child: Text('Log out', style: kInter(size: 14, color: const Color(0xFFE07070))),
          ),
        ],
      ),
    );
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Settings',
                  style: kRaleway(size: 18, weight: FontWeight.w300, color: const Color(0xFFB8C8E0))),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _reminderEnabled ? _pickTime : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily reminder',
                            style: kInter(size: 14, color: const Color(0xFFD0D8E8))),
                          const SizedBox(height: 4),
                          Text('The sky is clear tonight.',
                            style: kInter(size: 11, color: const Color(0xFF4A5570))),
                        ],
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: _toggleReminder,
                        activeThumbColor: const Color(0xFF7AB6E0),
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF7AB6E0);
                          }
                          return Colors.grey;
                        }),
                      ),
                    ],
                  ),
                ),
                if (_reminderEnabled) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Text(
                      'Reminder at ${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                      style: kInter(size: 12, color: const Color(0xFF7AB6E0)),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _confirmLogout,
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
