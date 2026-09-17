import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/models/habit.dart';
import 'package:habit_constellation/providers/habits_provider.dart';
import 'package:habit_constellation/providers/repository_provider.dart';
import 'package:habit_constellation/screens/sheets/add_habit_sheet.dart';
import 'package:habit_constellation/screens/sheets/edit_habit_sheet.dart';
import 'package:habit_constellation/screens/sheets/comment_sheet.dart';
import 'package:habit_constellation/screens/sheets/settings_sheet.dart';
import 'package:habit_constellation/widgets/bottom_nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onGoConstellation;

  const HomeScreen({super.key, required this.onGoConstellation});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: Container(
        decoration: kBg,
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  _HomeHeader(onSettings: () => _showSettings(context)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: habitsAsync.when(
                      data: (habits) => _HabitCard(
                        habits: habits,
                        onToggleLog: _toggleLog,
                        onTapName: (h) => _showEditHabit(context, h),
                        onTapComment: (h) => _showComment(context, h),
                        onAddHabit: () => _showAddHabit(context),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: BottomNav(
                  active: 'home',
                  onHome: () {},
                  onConstellation: widget.onGoConstellation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLog(HabitWithTodayLog habit) {
    final repository = ref.read(repositoryProvider);
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (habit.isDoneToday) {
      repository.deleteLog(habit.id, dateStr).then((_) {
        ref.invalidate(habitsProvider);
      });
    } else {
      repository.logHabit(habit.id, dateStr).then((_) {
        ref.invalidate(habitsProvider);
      });
    }
  }

  void _showAddHabit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddHabitSheet(onAdd: (name) {
        ref.read(repositoryProvider).createHabit(name).then((_) {
          ref.invalidate(habitsProvider);
        });
      }),
    );
  }

  void _showEditHabit(BuildContext context, HabitWithTodayLog habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditHabitSheet(
        habit: habit,
        onRename: (name) {
          ref.read(repositoryProvider).renameHabit(habit.id, name).then((_) {
            ref.invalidate(habitsProvider);
          });
        },
        onDelete: () {
          Navigator.pop(context);
          showDialog(context: context, builder: (_) => ConfirmDialog(
            message: 'It disappears from today, but its stars remain in your past skies.',
            confirmLabel: 'Delete',
            danger: true,
            onConfirm: () {
              ref.read(repositoryProvider).deleteHabit(habit.id).then((_) {
                ref.invalidate(habitsProvider);
              });
            },
          ));
        },
      ),
    );
  }

  void _showComment(BuildContext context, HabitWithTodayLog habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CommentSheet(
        habit: habit,
        existingComment: habit.todayLog?.comment,
        hasLog: habit.isDoneToday,
        onSave: (text) {
          if (habit.todayLog != null) {
            ref.read(repositoryProvider).patchLog(habit.todayLog!.id, comment: text).then((_) {
              ref.invalidate(habitsProvider);
            });
          }
        },
        onDelete: () {
          if (habit.todayLog != null) {
            ref.read(repositoryProvider).patchLog(habit.todayLog!.id, comment: null).then((_) {
              ref.invalidate(habitsProvider);
            });
          }
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SettingsSheet(onLogout: () {
        Navigator.pop(context);
        showDialog(context: context, builder: (_) => ConfirmDialog(
          message: 'Log out of Habit Constellation?',
          confirmLabel: 'Log out',
          danger: true,
          onConfirm: () {
            ref.read(repositoryProvider).signOut();
          },
        ));
      }),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onSettings;
  const _HomeHeader({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Every habit you practice becomes a star.',
                  style: kRaleway(size: 15.5, weight: FontWeight.w300, spacing: 0.03,
                    color: const Color(0xFFB8C8E0))),
                const SizedBox(height: 6),
                Text('Tap ◯ to mark a habit as practiced today. Tap again to undo.',
                  style: kInter(size: 11.5, spacing: 0.03, color: const Color(0xFF4A5570))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSettings,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.settings_outlined, size: 19, color: const Color(0xFF4A5570)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final List<HabitWithTodayLog> habits;
  final void Function(HabitWithTodayLog) onToggleLog;
  final void Function(HabitWithTodayLog) onTapName;
  final void Function(HabitWithTodayLog) onTapComment;
  final VoidCallback onAddHabit;

  const _HabitCard({
    required this.habits,
    required this.onToggleLog,
    required this.onTapName,
    required this.onTapComment,
    required this.onAddHabit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.022),
      ),
      child: Column(
        children: [
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
              child: Text('Your constellation is waiting, log your first habit.',
                textAlign: TextAlign.center,
                style: kInter(size: 13, color: const Color(0xFF3A4560), spacing: 0.02)),
            )
          else
            ...habits.asMap().entries.map((e) {
              final i = e.key;
              final habit = e.value;
              return Column(children: [
                if (i > 0) Divider(height: 1, thickness: 1, indent: 18, endIndent: 18,
                  color: Colors.white.withOpacity(0.048)),
                _HabitRow(
                  habit: habit,
                  onToggle: () => onToggleLog(habit),
                  onTapName: () => onTapName(habit),
                  onTapComment: () => onTapComment(habit),
                ),
              ]);
            }),
          Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.055)),
          _AddHabitFooter(onTap: onAddHabit),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final HabitWithTodayLog habit;
  final VoidCallback onToggle;
  final VoidCallback onTapName;
  final VoidCallback onTapComment;

  const _HabitRow({
    required this.habit,
    required this.onToggle,
    required this.onTapName,
    required this.onTapComment,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.isDoneToday;
    final hasNote = habit.todayLog?.hasComment ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTapName,
              child: Text(habit.name,
                style: kInter(size: 15, spacing: 0.018,
                  color: done ? const Color(0xFFB8C8E0) : const Color(0xFF6878A0))),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onTapComment,
            child: SizedBox(
              width: 28, height: 28,
              child: Center(child: _EnvelopeIcon(blue: hasNote)),
            ),
          ),
          const SizedBox(width: 12),
          _LogButton(done: done, onTap: onToggle),
        ],
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  const _LogButton({required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? const Color(0x23BCD5E4) : Colors.transparent,
          border: Border.all(
            color: done ? const Color(0xA6C6D4EB) : Colors.white.withOpacity(0.28),
            width: 1,
          ),
          boxShadow: done ? [
            BoxShadow(color: kSilver.withOpacity(0.22), blurRadius: 10),
          ] : null,
        ),
        child: done ? Center(
          child: Container(
            width: 9, height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xD9D7E0F0),
              boxShadow: [BoxShadow(color: const Color(0xD7E0F0).withOpacity(0.65), blurRadius: 7)],
            ),
          ),
        ) : null,
      ),
    );
  }
}

class _EnvelopeIcon extends StatelessWidget {
  final bool blue;
  const _EnvelopeIcon({required this.blue});

  @override
  Widget build(BuildContext context) {
    final color = blue ? const Color(0xFF7AB6E0) : Colors.white.withOpacity(0.35);
    return Icon(Icons.mail_outline_rounded, size: 18, color: color,
      shadows: blue ? [Shadow(color: const Color(0xFF7AB6E0).withOpacity(0.5), blurRadius: 6)] : null);
  }
}

class _AddHabitFooter extends StatelessWidget {
  final VoidCallback onTap;
  const _AddHabitFooter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Icon(Icons.add, size: 12, color: Colors.white.withOpacity(0.35)),
            ),
            const SizedBox(width: 10),
            Text('add a new habit',
              style: kInter(size: 11.5, spacing: 0.08, color: const Color(0xFF4A5570))),
          ],
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String message;
  final String confirmLabel;
  final bool danger;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.message,
    required this.confirmLabel,
    required this.danger,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0E1224),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(message, style: kInter(size: 14, color: const Color(0xFFB8C8E0))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: kInter(size: 13, color: const Color(0xFF6878A0))),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(confirmLabel, style: kInter(size: 13,
            color: danger ? const Color(0xFFE07070) : const Color(0xFF7AB6E0))),
        ),
      ],
    );
  }
}
