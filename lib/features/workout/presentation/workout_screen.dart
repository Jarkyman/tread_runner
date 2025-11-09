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
    final pref =
        await context.read<UserPreferencesRepository>().getUnitsPreference();
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
          builder: (context, state) {
            if (state.status == WorkoutStatus.idle || state.plan == null) {
              return _WorkoutEmptyState(onClose: () => Navigator.of(context).pop());
            }

            final timeline = _WorkoutTimeline.fromPlan(state.plan!);
            final treadmillService = context.read<TreadmillService>();

            return Column(
              children: [
                const SizedBox(height: 12),
                _WorkoutHeader(
                  plan: state.plan!,
                  status: state.status,
                ),
                if (_isUnitsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: LinearProgressIndicator(),
                  ),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      const _ConnectionWarning(),
                      _TimeStatCard(elapsed: state.elapsed),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'Distance',
                              value: _formatDistance(
                                state.metrics.distanceMeters,
                                _unitsPreference,
                              ),
                              unit: _distanceUnit(_unitsPreference),
                              icon: Icons.route,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: 'Heart Rate',
                              value: state.metrics.heartRate > 0
                                  ? state.metrics.heartRate.toString()
                                  : '--',
                              unit: 'BPM',
                              icon: Icons.favorite_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _ControlTile(
                        label: 'Speed',
                        value: _formatSpeed(
                          state.metrics.speedKmh,
                          _unitsPreference,
                        ),
                        unit: _speedUnit(_unitsPreference),
                        onDecrement: () => _changeSpeed(
                          context,
                          treadmillService,
                          state.metrics.speedKmh,
                          -0.2,
                        ),
                        onIncrement: () => _changeSpeed(
                          context,
                          treadmillService,
                          state.metrics.speedKmh,
                          0.2,
                        ),
                        enabled: state.status == WorkoutStatus.running,
                      ),
                      const SizedBox(height: 16),
                      _ControlTile(
                        label: 'Incline',
                        value: state.metrics.inclinePercent.toStringAsFixed(1),
                        unit: '%',
                        onDecrement: () => _changeIncline(
                          context,
                          treadmillService,
                          state.metrics.inclinePercent,
                          -0.5,
                        ),
                        onIncrement: () => _changeIncline(
                          context,
                          treadmillService,
                          state.metrics.inclinePercent,
                          0.5,
                        ),
                        enabled: state.status == WorkoutStatus.running,
                      ),
                      const SizedBox(height: 24),
                      _WorkoutTimelineView(
                        plan: state.plan!,
                        timeline: timeline,
                        elapsed: state.elapsed,
                      ),
                      const SizedBox(height: 16),
                      _CurrentSegmentCard(
                        timeline: timeline,
                        elapsed: state.elapsed,
                      ),
                      const SizedBox(height: 24),
                    ],
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
        final isConnected =
            state.status == TreadmillConnectionState.connected;
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

class _TimeStatCard extends StatelessWidget {
  const _TimeStatCard({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timer_outlined, color: Colors.white54),
              SizedBox(width: 8),
              Text(
                'Time Elapsed',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatElapsed(elapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
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
  });

  final String label;
  final String value;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(56, 56),
          backgroundColor:
              onPressed == null ? Colors.white12 : Colors.white.withAlpha(20),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Center(child: Icon(icon, size: 24)),
      ),
    );
  }
}

class _WorkoutTimelineView extends StatelessWidget {
  const _WorkoutTimelineView({
    required this.plan,
    required this.timeline,
    required this.elapsed,
  });

  final WorkoutPlan plan;
  final _WorkoutTimeline timeline;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    if (timeline.segments.isEmpty) {
      return const SizedBox.shrink();
    }
    final color = Color(plan.colorValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout Timeline',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < timeline.segments.length; i++)
              Expanded(
                flex: max(1, timeline.segments[i].duration.inSeconds),
                child: Container(
                  height: 14,
                  margin: EdgeInsets.only(right: i == timeline.segments.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white10,
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: timeline.segmentProgress(i, elapsed),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CurrentSegmentCard extends StatelessWidget {
  const _CurrentSegmentCard({
    required this.timeline,
    required this.elapsed,
  });

  final _WorkoutTimeline timeline;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final segment = timeline.currentSegment(elapsed);
    if (segment == null) {
      return const SizedBox.shrink();
    }
    final remaining =
        segment.end > elapsed ? segment.end - elapsed : Duration.zero;
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
              Text(
                'Current Segment',
                style: TextStyle(color: Colors.white70),
              ),
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

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _holdDuration,
  );
  Timer? _holdTimer;
  bool _holdCompleted = false;

  bool get _isInteractive => widget.status != WorkoutStatus.completed;

  @override
  void dispose() {
    _holdTimer?.cancel();
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
    _holdCompleted = false;
    _controller.forward(from: 0);
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDuration, () {
      _holdCompleted = true;
      _controller.value = 1;
      _stopWorkout();
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isInteractive) return;
    final completed = _holdCompleted;
    _cancelHold(reset: !completed);
    if (!completed) {
      _togglePauseResume();
    }
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    _cancelHold(reset: true);
  }

  void _cancelHold({required bool reset}) {
    _holdTimer?.cancel();
    if (reset) {
      _controller.reset();
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
    final bloc = context.read<WorkoutBloc>();
    bloc.add(const WorkoutStopped());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = widget.status == WorkoutStatus.paused;
    final isComplete = widget.status == WorkoutStatus.completed;
    final baseColor =
        isComplete ? Colors.white24 : AppColors.primary;
    final textColor = isComplete ? Colors.white70 : Colors.black;
    final label =
        isPaused ? 'Resume (Hold 3 sec to end)' : 'Pause';

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
                        widthFactor:
                            isComplete ? 0 : _controller.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withAlpha((0.35 * 255).round()),
                                Colors.white.withAlpha((0.05 * 255).round()),
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
          OutlinedButton(
            onPressed: onClose,
            child: const Text('Close'),
          ),
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
  final value =
      preference == UnitsPreference.metric ? kmh : kmh * 0.621371;
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
