import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:clock/clock.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/models/habit.dart';
import 'package:habit_constellation/providers/habits_provider.dart';
import 'package:habit_constellation/providers/repository_provider.dart';
import 'package:habit_constellation/screens/sheets/add_habit_sheet.dart';
import 'package:habit_constellation/screens/sheets/edit_habit_sheet.dart';
import 'package:habit_constellation/screens/sheets/comment_sheet.dart';
import 'package:habit_constellation/screens/sheets/settings_sheet.dart';
import 'package:habit_constellation/widgets/bottom_nav.dart';
import 'package:habit_constellation/services/offline_queue.dart';
import 'package:habit_constellation/services/toast_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onGoConstellation;

  const HomeScreen({super.key, required this.onGoConstellation});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTooltip = false;
  String? _tooltipText;
  Offset? _tooltipPosition;
  bool _showStarFlash = false;
  final Map<String, GlobalKey> _logButtonKeys = {};
  final Map<String, GlobalKey> _commentButtonKeys = {};
  bool _firstLogTooltipsStarted = false;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  final _offlineQueue = OfflineQueue();
  Set<String> _pendingHabitIds = {};

  @override
  void initState() {
    super.initState();
    _loadPending();
    _checkConnectivity();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPending() async {
    await _offlineQueue.load();
    if (mounted) {
      setState(() {
        _pendingHabitIds = _offlineQueue.items.map((a) => a.habitId).toSet();
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _connectivityResult = isConnected ? ConnectivityResult.wifi : ConnectivityResult.none;
      });
      if (isConnected) {
        _syncQueue();
      }
    }
  }

  Future<void> _syncQueue() async {
    final items = await _offlineQueue.drain();
    final repository = ref.read(repositoryProvider);
    final remaining = <QueuedAction>[];
    for (final action in items) {
      try {
        if (action.action == QueueAction.log) {
          await repository.logHabit(action.habitId, action.logDate);
        } else if (action.action == QueueAction.undo) {
          await repository.deleteLog(action.habitId, action.logDate);
        }
        if (mounted) {
          setState(() {
            _pendingHabitIds.remove(action.habitId);
          });
        }
      } catch (e) {
        remaining.add(action);
        if (mounted) {
          setState(() {
            _pendingHabitIds.add(action.habitId);
          });
          ToastService.show('Sync failed, will retry');
        }
      }
    }
    for (final action in remaining) {
      await _offlineQueue.enqueue(action);
    }
  }

  bool get isOnline => _connectivityResult != ConnectivityResult.none;

  void _toggleLog(HabitWithTodayLog habit, BuildContext context) {
    final repository = ref.read(repositoryProvider);
    final now = clock.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (!isOnline) {
      _offlineQueue.enqueue(QueuedAction(
        habitId: habit.id,
        logDate: dateStr,
        action: habit.isDoneToday ? QueueAction.undo : QueueAction.log,
      ));
      if (habit.isDoneToday) {
        setState(() {
          _pendingHabitIds.add(habit.id);
        });
      } else {
        _showStarFlashAnimation();
        setState(() {
          _pendingHabitIds.add(habit.id);
        });
        _showFirstLogTooltips(habit.id);
      }
      return;
    }

    if (habit.isDoneToday) {
      if (habit.todayLog?.hasComment ?? false) {
        showDialog(context: context, builder: (_) => ConfirmDialog(
          message: 'This also deletes your note.',
          confirmLabel: 'Delete note & undo',
          danger: true,
          onConfirm: () {
            repository.deleteLog(habit.id, dateStr).then((_) {
              ref.invalidate(habitsProvider);
            });
          },
        ));
      } else {
        repository.deleteLog(habit.id, dateStr).then((_) {
          ref.invalidate(habitsProvider);
        });
      }
    } else {
      _showStarFlashAnimation();
      _showFirstLogTooltips(habit.id);
      repository.logHabit(habit.id, dateStr).then((_) {
        ref.invalidate(habitsProvider);
      }).catchError((_) {
        _offlineQueue.enqueue(QueuedAction(
          habitId: habit.id,
          logDate: dateStr,
          action: QueueAction.log,
        ));
        setState(() {
          _pendingHabitIds.add(habit.id);
        });
      });
    }
  }

  void _showStarFlashAnimation() {
    setState(() => _showStarFlash = true);
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _showStarFlash = false);
    });
  }

  GlobalKey _keyFor(Map<String, GlobalKey> map, String habitId) =>
      map.putIfAbsent(habitId, () => GlobalKey());

  Offset? _screenPosition(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return box.localToGlobal(Offset.zero);
  }

  Future<void> _showFirstLogTooltips(String habitId) async {
    if (_firstLogTooltipsStarted) return;
    _firstLogTooltipsStarted = true;
    try {
      debugPrint('_showFirstLogTooltips started');

      final user = await ref.read(repositoryProvider).getCurrentUser();
      debugPrint('tooltip_log_seen from /me: ${user.tooltipLogSeen}');
      if (user.tooltipLogSeen) return;

      debugPrint('Calling patchMe...');
      try {
        await ref.read(repositoryProvider).patchMe(
          tooltipLogSeen: true,
          tooltipCommentSeen: true,
        );
        debugPrint('patchMe succeeded');
      } catch (e) {
        debugPrint('patchMe failed: $e');
      }

      final logPos = _screenPosition(_keyFor(_logButtonKeys, habitId));
      final commentPos = _screenPosition(_keyFor(_commentButtonKeys, habitId));
      if (logPos == null) return;
      final secondPos = commentPos ?? logPos;
      _tooltipPosition = logPos;

      setState(() {
        _showTooltip = true;
        _tooltipText = 'Tap again to undo';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      setState(() {
        _tooltipPosition = secondPos;
        _tooltipText = 'Write how it felt, if you feel like it';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      setState(() => _showTooltip = false);
    } catch (_) {}
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
        ref.read(repositoryProvider).signOut();
        Navigator.popUntil(context, (route) => route.isFirst);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final anchor = _tooltipPosition;
    const tooltipWidth = 220.0;
    const tooltipMargin = 12.0;
    double tooltipLeft = tooltipMargin;
    double tooltipTop = tooltipMargin;
    if (anchor != null) {
      final screen = MediaQuery.of(context).size;
      tooltipLeft = anchor.dx - tooltipWidth - 16;
      final maxLeft = screen.width - tooltipWidth - tooltipMargin;
      tooltipLeft = maxLeft > tooltipMargin
          ? tooltipLeft.clamp(tooltipMargin, maxLeft)
          : tooltipMargin;
      tooltipTop = (anchor.dy - 4).clamp(
        tooltipMargin,
        screen.height - 100 > tooltipMargin ? screen.height - 100 : tooltipMargin,
      );
    }

    return Scaffold(
      body: Container(
        decoration: kBg,
        child: SafeArea(
          child: Stack(
            children: [
              habitsAsync.when(
                data: (habits) => ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    _HomeHeader(onSettings: () => _showSettings(context)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _HabitCard(
                        habits: habits,
                        isOnline: isOnline,
                        pendingHabitIds: _pendingHabitIds,
                        logButtonKeys: _logButtonKeys,
                        commentButtonKeys: _commentButtonKeys,
                        onToggleLog: (h) => _toggleLog(h, context),
                        onTapName: (h) => _showEditHabit(context, h),
                        onTapComment: (h) => _showComment(context, h),
                        onAddHabit: () => _showAddHabit(context),
                      ),
                    ),
                  ],
                ),
                loading: () => _HomeSkeleton(),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Something went wrong', style: kInter(size: 14, color: const Color(0xFF7888A0))),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => ref.invalidate(habitsProvider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Retry', style: kInter(size: 13, color: kBlueGlow)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: BottomNav(
                  active: 'home',
                  onHome: () {},
                  onConstellation: widget.onGoConstellation,
                ),
              ),
              if (_showStarFlash)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        Align(alignment: Alignment(-0.5, -0.55), child: _StarFlash()),
                        Align(alignment: Alignment(0.45, -0.4), child: _StarFlash()),
                        Align(alignment: Alignment(-0.65, 0.05), child: _StarFlash()),
                        Align(alignment: Alignment(0.6, 0.2), child: _StarFlash()),
                        Align(alignment: Alignment(-0.35, 0.55), child: _StarFlash()),
                        Align(alignment: Alignment(0.3, 0.6), child: _StarFlash()),
                        Align(alignment: Alignment(0.05, -0.15), child: _StarFlash()),
                        Align(alignment: Alignment(-0.1, 0.35), child: _StarFlash()),
                      ],
                    ),
                  ),
                ),
              if (_showTooltip && _tooltipPosition != null)
                Positioned(
                  left: tooltipLeft,
                  top: tooltipTop,
                  child: _TooltipBubble(text: _tooltipText ?? ''),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarFlash extends StatefulWidget {
  const _StarFlash();

  @override
  State<_StarFlash> createState() => _StarFlashState();
}

class _StarFlashState extends State<_StarFlash> with SingleTickerProviderStateMixin {
  static const _fadeInMs = 100;
  static const _fadeOutMs = 600;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _fadeInMs + _fadeOutMs),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _opacity {
    final t = _controller.value;
    final fadeInEnd = _fadeInMs / (_fadeInMs + _fadeOutMs);
    if (t < fadeInEnd) {
      return Curves.easeOut.transform(t / fadeInEnd);
    }
    return 1 - Curves.easeIn.transform((t - fadeInEnd) / (1 - fadeInEnd));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: const Size(15, 15),
        painter: _StarFlashPainter(_opacity),
      ),
    );
  }
}

class _StarFlashPainter extends CustomPainter {
  final double opacity;
  _StarFlashPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9 * opacity),
          kSilver.withValues(alpha: 0.35 * opacity),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glow);

    final core = Paint()
      ..color = Colors.white.withValues(alpha: opacity);
    canvas.drawCircle(center, 1.5, core);
  }

  @override
  bool shouldRepaint(_StarFlashPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class _TooltipBubble extends StatelessWidget {
  final String text;
  const _TooltipBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    const fill = Color(0xEEE080B4);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: fill.withValues(alpha: 0.95),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: kInter(size: 12.5, color: const Color(0xFFD0D8E8))),
        ),
        Positioned(
          right: -5,
          top: 13,
          child: Transform.rotate(
            angle: 0.7853981634,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: fill.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
              ),
            ),
          ),
        ),
      ],
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
  final bool isOnline;
  final Set<String> pendingHabitIds;
  final Map<String, GlobalKey> logButtonKeys;
  final Map<String, GlobalKey> commentButtonKeys;

  const _HabitCard({
    required this.habits,
    required this.onToggleLog,
    required this.onTapName,
    required this.onTapComment,
    required this.onAddHabit,
    required this.isOnline,
    required this.pendingHabitIds,
    required this.logButtonKeys,
    required this.commentButtonKeys,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.022),
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
                  color: Colors.white.withValues(alpha: 0.048)),
                _HabitRow(
                  habit: habit,
                  isOnline: isOnline,
                  isPending: pendingHabitIds.contains(habit.id),
                  logButtonKey: logButtonKeys.putIfAbsent(habit.id, () => GlobalKey()),
                  commentButtonKey: commentButtonKeys.putIfAbsent(habit.id, () => GlobalKey()),
                  onToggle: () => onToggleLog(habit),
                  onTapName: () => onTapName(habit),
                  onTapComment: () => onTapComment(habit),
                ),
              ]);
            }),
          Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.055)),
          _AddHabitFooter(onTap: onAddHabit),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final HabitWithTodayLog habit;
  final bool isOnline;
  final bool isPending;
  final GlobalKey? logButtonKey;
  final GlobalKey? commentButtonKey;
  final VoidCallback onToggle;
  final VoidCallback onTapName;
  final VoidCallback onTapComment;

  const _HabitRow({
    required this.habit,
    required this.isOnline,
    required this.isPending,
    this.logButtonKey,
    this.commentButtonKey,
    required this.onToggle,
    required this.onTapName,
    required this.onTapComment,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.isDoneToday;
    final hasNote = habit.todayLog?.hasComment ?? false;
    final canComment = isOnline && done && !isPending;
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
            key: commentButtonKey,
            onTap: canComment ? onTapComment : null,
            child: SizedBox(
              width: 28, height: 28,
              child: Center(child: _EnvelopeIcon(blue: hasNote, dimmed: !canComment)),
            ),
          ),
          const SizedBox(width: 12),
          _LogButton(key: logButtonKey, done: done, onTap: onToggle),
        ],
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  const _LogButton({super.key, required this.done, required this.onTap});

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
            color: done ? const Color(0xA6C6D4EB) : Colors.white.withValues(alpha: 0.28),
            width: 1,
          ),
          boxShadow: done ? [
            BoxShadow(color: kSilver.withValues(alpha: 0.22), blurRadius: 10),
          ] : null,
        ),
        child: done ? Center(
          child: Container(
            width: 9, height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xD9D7E0F0),
              boxShadow: [BoxShadow(color: const Color(0xD7E0F0).withValues(alpha: 0.65), blurRadius: 7)],
            ),
          ),
        ) : null,
      ),
    );
  }
}

class _EnvelopeIcon extends StatelessWidget {
  final bool blue;
  final bool dimmed;
  const _EnvelopeIcon({required this.blue, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? const Color(0xFF4A5570) : (blue ? const Color(0xFF7AB6E0) : const Color(0xFF4A5570));
    return Icon(Icons.mail_outline_rounded, size: 18, color: color.withValues(alpha: dimmed ? 0.35 : (blue ? 1.0 : 0.35)),
      shadows: blue && !dimmed ? [Shadow(color: const Color(0xFF7AB6E0).withValues(alpha: 0.5), blurRadius: 6)] : null);
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Icon(Icons.add, size: 12, color: Colors.white.withValues(alpha: 0.35)),
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

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _HomeHeader(onSettings: () {}),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.022),
            ),
            child: Column(
              children: List.generate(4, (i) {
                return Column(children: [
                  if (i > 0) Divider(height: 1, thickness: 1, indent: 18, endIndent: 18,
                    color: Colors.white.withValues(alpha: 0.048)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 120, height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                              width: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]);
              }),
            ),
          ),
        ),
      ],
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
