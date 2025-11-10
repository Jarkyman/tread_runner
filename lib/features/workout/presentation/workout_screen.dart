import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/ble/connection_cubit.dart' as connection;
import '../../../core/ble/treadmill_service.dart';
import '../../../core/preferences/units_preference.dart';
import '../../../core/preferences/user_preferences_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_step.dart';
import '../../shared/widgets/connection_status_badge.dart';
import '../../workout_summary/cubit/workout_summary_cubit.dart';
import '../../workout_summary/presentation/workout_summary_screen.dart';
import '../bloc/workout_bloc.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  static const routeName = '/workout';

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  UnitsPreference _unitsPreference = UnitsPreference.metric;
  bool _isUnitsLoading = true;
  bool _navigatedToSummary = false;

  @override
  void initState() {
    super.initState();
    _loadUnitsPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsService>().logScreenView('workout');
    });
  }

  Future<void> _loadUnitsPreference() async {
    final pref = await context
        .read<UserPreferencesRepository>()
        .getUnitsPreference();
    if (!mounted) return;
    setState(() {
      _unitsPreference = pref;
      _isUnitsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<WorkoutBloc, WorkoutState>(
          listener: (context, state) {
            final message = state.errorMessage;
            if (message != null && message.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
            if (!_navigatedToSummary &&
                state.status == WorkoutStatus.completed &&
                state.completedSession != null) {
              _navigatedToSummary = true;
              final summaryCubit = context.read<WorkoutSummaryCubit>();
              summaryCubit.showSession(
                state.completedSession!,
                plan: state.plan,
              );
              Navigator.of(context).pushReplacementNamed(
                WorkoutSummaryScreen.routeName,
                arguments: WorkoutSummaryArgs(
                  session: state.completedSession!,
                  plan: state.plan,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == WorkoutStatus.idle || state.plan == null) {
              return _WorkoutEmptyState(
                onClose: () => Navigator.of(context).pop(),
              );
            }

            final timeline = _WorkoutTimeline.fromPlan(state.plan!);
            final treadmillService = context.read<TreadmillService>();

            return Column(
              children: [
                const SizedBox(height: 12),
                _WorkoutHeader(plan: state.plan!, status: state.status),
                if (_isUnitsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: LinearProgressIndicator(),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ConnectionWarning(),
                        _PrimaryStatsCard(
                          elapsed: state.elapsed,
                          distanceMeters: state.metrics.distanceMeters,
                          heartRate: state.metrics.heartRate,
                          unitsPreference: _unitsPreference,
                        ),
                        const SizedBox(height: 20),
                        _CompactControlRow(
                          displaySpeedKmh: state.metrics.speedKmh,
                          displayInclinePercent: state.metrics.inclinePercent,
                          unitsPreference: _unitsPreference,
                          enabled: state.status == WorkoutStatus.running,
                          onSpeedDelta: (delta) => _changeSpeed(
                            context,
                            treadmillService,
                            state.metrics.speedKmh,
                            delta,
                          ),
                          onInclineDelta: (delta) => _changeIncline(
                            context,
                            treadmillService,
                            state.metrics.inclinePercent,
                            delta,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _WorkoutTimelineView(
                          plan: state.plan!,
                          timeline: timeline,
                          elapsed: state.elapsed,
                          metrics: state.metrics,
                          goalDuration: state.goalDuration,
                          goalDistanceMeters: state.goalDistanceMeters,
                          currentStepIndex: state.currentStepIndex,
                        ),
                        const SizedBox(height: 16),
                        _CurrentSegmentCard(
                          plan: state.plan!,
                          timeline: timeline,
                          elapsed: state.elapsed,
                          metrics: state.metrics,
                          goalDuration: state.goalDuration,
                          goalDistanceMeters: state.goalDistanceMeters,
                          unitsPreference: _unitsPreference,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                _BottomControls(status: state.status),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  void _changeSpeed(
    BuildContext context,
    TreadmillService service,
    double currentSpeed,
    double delta,
  ) {
    final double newSpeed = (currentSpeed + delta).clamp(0.0, 25.0);
    unawaited(service.setSpeed(newSpeed));
  }

  void _changeIncline(
    BuildContext context,
    TreadmillService service,
    double currentIncline,
    double delta,
  ) {
    final double newIncline = (currentIncline + delta).clamp(0.0, 15.0);
    unawaited(service.setIncline(newIncline));
  }
}

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.plan, required this.status});

  final WorkoutPlan plan;
  final WorkoutStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const ConnectionStatusBadge(style: ConnectionBadgeStyle.compact),
          const Spacer(),
          Column(
            children: [
              const Text(
                'Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                plan.name,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          // TODO: Add sync badge once watch/health sync is wired up.
          const Spacer(),
        ],
      ),
    );
  }
}

class _ConnectionWarning extends StatelessWidget {
  const _ConnectionWarning();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<connection.ConnectionCubit, connection.ConnectionState>(
      builder: (context, state) {
        final isConnected = state.status == TreadmillConnectionState.connected;
        if (isConnected) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(24),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.isScanning
                      ? 'Connection interrupted. Reconnecting...'
                      : 'Treadmill connection lost.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryStatsCard extends StatelessWidget {
  const _PrimaryStatsCard({
    required this.elapsed,
    required this.distanceMeters,
    required this.heartRate,
    required this.unitsPreference,
  });

  final Duration elapsed;
  final double distanceMeters;
  final int heartRate;
  final UnitsPreference unitsPreference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.timer_outlined, color: Colors.white54),
                    SizedBox(width: 8),
                    Text('Time Elapsed', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatElapsed(elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _MiniStat(
                  label: 'Distance',
                  value: _formatDistance(distanceMeters, unitsPreference),
                  unit: _distanceUnit(unitsPreference),
                ),
                const SizedBox(height: 16),
                _MiniStat(
                  label: 'Heart Rate',
                  value: heartRate > 0 ? heartRate.toString() : '--',
                  unit: 'BPM',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(unit, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ],
    );
  }
}

class _CompactControlRow extends StatelessWidget {
  const _CompactControlRow({
    required this.displaySpeedKmh,
    required this.displayInclinePercent,
    required this.unitsPreference,
    required this.onSpeedDelta,
    required this.onInclineDelta,
    required this.enabled,
  });

  final double displaySpeedKmh;
  final double displayInclinePercent;
  final UnitsPreference unitsPreference;
  final ValueChanged<double> onSpeedDelta;
  final ValueChanged<double> onInclineDelta;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ControlTile(
            label: 'Speed',
            value: _formatSpeed(displaySpeedKmh, unitsPreference),
            unit: _speedUnit(unitsPreference),
            onDecrement: () => onSpeedDelta(-0.1),
            onIncrement: () => onSpeedDelta(0.1),
            enabled: enabled,
            dense: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ControlTile(
            label: 'Incline',
            value: displayInclinePercent.toStringAsFixed(1),
            unit: '%',
            onDecrement: () => onInclineDelta(-1),
            onIncrement: () => onInclineDelta(1),
            enabled: enabled,
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
    required this.enabled,
    this.dense = false,
  });

  final String label;
  final String value;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool enabled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final double buttonSize = dense ? 48 : 56;
    final double iconSize = dense ? 20 : 24;
    final double fontSize = dense ? 26 : 32;
    final EdgeInsets padding = EdgeInsets.all(dense ? 14 : 16);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                label == 'Speed'
                    ? Icons.speed_outlined
                    : Icons.landscape_outlined,
                color: Colors.white54,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ControlButton(
                icon: Icons.remove,
                onPressed: enabled ? onDecrement : null,
                size: buttonSize,
                iconSize: iconSize,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _ControlButton(
                icon: Icons.add,
                onPressed: enabled ? onIncrement : null,
                size: buttonSize,
                iconSize: iconSize,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.iconSize = 24,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(size, size),
          backgroundColor:
              onPressed == null ? Colors.white12 : Colors.white.withAlpha(20),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Center(child: Icon(icon, size: iconSize)),
      ),
    );
  }
}

class _WorkoutTimelineView extends StatelessWidget {
  const _WorkoutTimelineView({
    required this.plan,
    required this.timeline,
    required this.elapsed,
    required this.metrics,
    this.goalDuration,
    this.goalDistanceMeters,
    required this.currentStepIndex,
  });

  final WorkoutPlan plan;
  final _WorkoutTimeline timeline;
  final Duration elapsed;
  final TreadmillMetrics metrics;
  final Duration? goalDuration;
  final double? goalDistanceMeters;
  final int currentStepIndex;

  @override
  Widget build(BuildContext context) {
    final color = Color(plan.colorValue);
    final segments = timeline.segments;
    final hasSegments = segments.isNotEmpty;
    final fallbackProgress = _singleGoalProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout Timeline',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (hasSegments)
          LayoutBuilder(
            builder: (context, constraints) {
              final totalDurationMs = segments.fold<int>(
                0,
                (sum, segment) => sum + segment.duration.inMilliseconds,
              );
              final spacing = 8.0;
              final availableWidth = max(
                0.0,
                constraints.maxWidth - spacing * (segments.length - 1),
              );
              const activeScale = 1.35;
              const inactiveScale = 0.85;
              final fractions = segments
                  .map(
                    (segment) =>
                        segment.duration.inMilliseconds / totalDurationMs,
                  )
                  .toList();
              final scaledTotal = fractions.asMap().entries.fold<double>(
                0,
                (sum, entry) {
                  final scale =
                      entry.key == currentStepIndex ? activeScale : inactiveScale;
                  return sum + entry.value * scale;
                },
              );
              return Row(
                children: [
                  for (var i = 0; i < segments.length; i++) ...[
                    _AnimatedSegment(
                      width: availableWidth *
                          (fractions[i] *
                              (i == currentStepIndex
                                  ? activeScale
                                  : inactiveScale) /
                              scaledTotal),
                      progress: timeline.segmentProgress(i, elapsed),
                      isActive: i == currentStepIndex,
                      isComplete: i < currentStepIndex,
                      color: color,
                    ),
                    if (i != segments.length - 1) SizedBox(width: spacing),
                  ],
                ],
              );
            },
          )
        else if (fallbackProgress != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Container(
                  height: 28,
                  color: Colors.white10,
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fallbackProgress,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const Text(
            'Progress will appear when a goal is set.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
      ],
    );
  }

  double? _singleGoalProgress() {
    if (goalDuration != null && goalDuration!.inSeconds > 0) {
      final ratio = elapsed.inSeconds / goalDuration!.inSeconds;
      return ratio.clamp(0, 1).toDouble();
    }
    if (goalDistanceMeters != null && goalDistanceMeters! > 0) {
      final ratio = metrics.distanceMeters / goalDistanceMeters!;
      return ratio.clamp(0, 1).toDouble();
    }
    return null;
  }
}

class _CurrentSegmentCard extends StatelessWidget {
  const _CurrentSegmentCard({
    required this.plan,
    required this.timeline,
    required this.elapsed,
    required this.metrics,
    required this.unitsPreference,
    this.goalDuration,
    this.goalDistanceMeters,
  });

  final WorkoutPlan plan;
  final _WorkoutTimeline timeline;
  final Duration elapsed;
  final TreadmillMetrics metrics;
  final UnitsPreference unitsPreference;
  final Duration? goalDuration;
  final double? goalDistanceMeters;

  @override
  Widget build(BuildContext context) {
    final segment = timeline.currentSegment(elapsed);
    if (segment == null) {
      return _GoalSummaryCard(
        plan: plan,
        elapsed: elapsed,
        goalDuration: goalDuration,
        goalDistanceMeters: goalDistanceMeters,
        metrics: metrics,
        unitsPreference: unitsPreference,
      );
    }
    final remaining = segment.end > elapsed
        ? segment.end - elapsed
        : Duration.zero;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.play_circle_outline, color: Colors.white70),
              SizedBox(width: 8),
              Text('Current Segment', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _segmentTitle(segment),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatElapsed(remaining)} remaining',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.plan,
    required this.elapsed,
    required this.metrics,
    required this.unitsPreference,
    this.goalDuration,
    this.goalDistanceMeters,
  });

  final WorkoutPlan plan;
  final Duration elapsed;
  final TreadmillMetrics metrics;
  final UnitsPreference unitsPreference;
  final Duration? goalDuration;
  final double? goalDistanceMeters;

  @override
  Widget build(BuildContext context) {
    final title = '${plan.name} Goal';
    final subtitle = _buildSubtitle();
    if (subtitle == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.flag_outlined, color: Colors.white70),
              SizedBox(width: 8),
              Text('Current Goal', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String? _buildSubtitle() {
    if (goalDuration != null && goalDuration!.inSeconds > 0) {
      final remaining = goalDuration! - elapsed;
      final clamped =
          remaining.isNegative ? Duration.zero : remaining;
      return '${_formatElapsed(clamped)} remaining';
    }
    if (goalDistanceMeters != null && goalDistanceMeters! > 0) {
      final remaining = goalDistanceMeters! - metrics.distanceMeters;
      final double clamped = remaining < 0 ? 0.0 : remaining;
      final remainingText =
          _formatDistance(clamped, unitsPreference);
      return '$remainingText ${_distanceUnit(unitsPreference)} remaining';
    }
    return null;
  }
}

class _AnimatedSegment extends StatelessWidget {
  const _AnimatedSegment({
    required this.width,
    required this.progress,
    required this.isActive,
    required this.isComplete,
    required this.color,
  });

  final double width;
  final double progress;
  final bool isActive;
  final bool isComplete;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final baseColor = isComplete
        ? color
        : isActive
            ? color.withAlpha((0.85 * 255).round())
            : Colors.white24;
    final height = isActive ? 30.0 : 24.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 350),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0, 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              decoration: BoxDecoration(
                color: baseColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.status});

  final WorkoutStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _PauseResumeButton(status: status),
    );
  }
}

class _PauseResumeButton extends StatefulWidget {
  const _PauseResumeButton({required this.status});

  final WorkoutStatus status;

  @override
  State<_PauseResumeButton> createState() => _PauseResumeButtonState();
}

class _PauseResumeButtonState extends State<_PauseResumeButton>
    with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 3);
  static const Duration _holdActivationDelay = Duration(milliseconds: 150);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _holdDuration,
  );
  Timer? _holdTimer;
  Timer? _holdStartTimer;
  bool _isHolding = false;

  bool get _isInteractive => widget.status != WorkoutStatus.completed;
  bool get _canHoldToEnd => widget.status == WorkoutStatus.paused;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _holdStartTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PauseResumeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInteractive) {
      _cancelHold(reset: true);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isInteractive) return;
    if (!_canHoldToEnd) return;
    _cancelHold(reset: true);
    _holdStartTimer = Timer(_holdActivationDelay, () {
      if (!mounted || !_canHoldToEnd) return;
      setState(() {
        _isHolding = true;
      });
      _controller.forward(from: 0);
      _holdTimer = Timer(_holdDuration, () {
        _controller.value = 1;
        _stopWorkout();
      });
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isInteractive) return;
    if (_canHoldToEnd) {
      final wasHolding = _isHolding;
      _cancelHold(reset: true);
      if (!wasHolding) {
        _togglePauseResume();
      }
      return;
    }
    _togglePauseResume();
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    if (_canHoldToEnd) {
      _cancelHold(reset: true);
    }
  }

  void _cancelHold({required bool reset}) {
    _holdTimer?.cancel();
    _holdStartTimer?.cancel();
    if (reset) {
      _controller.reset();
    }
    if (_isHolding) {
      setState(() {
        _isHolding = false;
      });
    }
  }

  void _togglePauseResume() {
    final bloc = context.read<WorkoutBloc>();
    if (widget.status == WorkoutStatus.paused) {
      bloc.add(const WorkoutResumed());
    } else if (widget.status == WorkoutStatus.running) {
      bloc.add(const WorkoutPaused());
    }
  }

  void _stopWorkout() {
    _cancelHold(reset: true);
    final bloc = context.read<WorkoutBloc>();
    bloc.add(const WorkoutStopped());
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = widget.status == WorkoutStatus.paused;
    final isComplete = widget.status == WorkoutStatus.completed;
    final baseColor = isComplete ? Colors.white24 : AppColors.primary;
    final textColor = isComplete ? Colors.white70 : Colors.black;
    final label = isPaused ? 'Resume (Hold 3 sec to end)' : 'Pause';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: isComplete || !_isHolding
                            ? 0
                            : _controller.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withAlpha(220),
                                Colors.white.withAlpha(90),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WorkoutTimeline {
  _WorkoutTimeline(this.segments);

  factory _WorkoutTimeline.fromPlan(WorkoutPlan plan) {
    final segments = <_TimelineSegment>[];
    var cursor = Duration.zero;
    for (final step in plan.steps) {
      final repeats = max(1, step.repeatCount ?? 1);
      for (var i = 0; i < repeats; i++) {
        final duration = _estimateStepDuration(step);
        final segment = _TimelineSegment(
          step: step,
          start: cursor,
          end: cursor + duration,
          repeatIndex: i + 1,
          repeatTotal: repeats,
        );
        segments.add(segment);
        cursor += duration;
      }
    }
    return _WorkoutTimeline(segments);
  }

  final List<_TimelineSegment> segments;

  _TimelineSegment? currentSegment(Duration elapsed) {
    for (final segment in segments) {
      if (elapsed < segment.end) {
        return segment;
      }
    }
    return segments.isEmpty ? null : segments.last;
  }

  double segmentProgress(int index, Duration elapsed) {
    if (index >= segments.length) return 0;
    final segment = segments[index];
    if (elapsed >= segment.end) return 1;
    if (elapsed <= segment.start) return 0;
    final total = segment.duration.inMilliseconds;
    if (total == 0) return 0;
    final elapsedMs = elapsed.inMilliseconds - segment.start.inMilliseconds;
    return (elapsedMs / total).clamp(0, 1);
  }
}

class _TimelineSegment {
  _TimelineSegment({
    required this.step,
    required this.start,
    required this.end,
    required this.repeatIndex,
    required this.repeatTotal,
  });

  final WorkoutStep step;
  final Duration start;
  final Duration end;
  final int repeatIndex;
  final int repeatTotal;

  Duration get duration => end - start;
}

class _WorkoutEmptyState extends StatelessWidget {
  const _WorkoutEmptyState({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No active workout',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a workout from the Pre Workout screen.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onClose, child: const Text('Close')),
        ],
      ),
    );
  }
}

Duration _estimateStepDuration(WorkoutStep step) {
  if (step.durationSeconds != null && step.durationSeconds! > 0) {
    return Duration(seconds: step.durationSeconds!);
  }
  if (step.distanceMeters != null && step.targetSpeedKmh != null) {
    final metersPerSecond = (step.targetSpeedKmh! * 1000) / 3600;
    if (metersPerSecond > 0) {
      return Duration(
        seconds: max(1, (step.distanceMeters! / metersPerSecond).round()),
      );
    }
  }
  return const Duration(minutes: 1);
}

String _formatElapsed(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  final seconds = value.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String _formatDistance(double meters, UnitsPreference preference) {
  final value = preference == UnitsPreference.metric
      ? meters / 1000
      : meters * 0.000621371;
  if (value.isNaN || value.isInfinite) {
    return '0.0';
  }
  return value.toStringAsFixed(2);
}

String _distanceUnit(UnitsPreference preference) {
  return preference == UnitsPreference.metric ? 'KM' : 'MI';
}

String _formatSpeed(double kmh, UnitsPreference preference) {
  final value = preference == UnitsPreference.metric ? kmh : kmh * 0.621371;
  return value.toStringAsFixed(1);
}

String _speedUnit(UnitsPreference preference) {
  return preference == UnitsPreference.metric ? 'KM/H' : 'MPH';
}

String _segmentTitle(_TimelineSegment segment) {
  final base = _segmentLabel(segment.step.type);
  if (segment.repeatTotal > 1) {
    return '$base ${segment.repeatIndex}/${segment.repeatTotal}';
  }
  return base;
}

String _segmentLabel(WorkoutStepType type) {
  switch (type) {
    case WorkoutStepType.warmup:
      return 'Warm-up';
    case WorkoutStepType.run:
      return 'Interval';
    case WorkoutStepType.recovery:
      return 'Recovery';
    case WorkoutStepType.cooldown:
      return 'Cooldown';
    case WorkoutStepType.hill:
      return 'Hill';
  }
}
