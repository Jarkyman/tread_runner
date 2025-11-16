import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:isar/isar.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/ble/treadmill_service.dart';
import '../../../core/utils/ticker.dart';
import '../../../data/workout_history/workout_history_repository.dart';
import '../../../domain/models/workout_metric_sample.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_session.dart';
import '../../../domain/models/workout_step.dart';
part 'workout_event.dart';
part 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  WorkoutBloc({
    required WorkoutHistoryRepository workoutHistoryRepository,
    required TreadmillService treadmillService,
    required AnalyticsService analyticsService,
    Ticker ticker = const Ticker(),
  })  : _historyRepository = workoutHistoryRepository,
        _treadmillService = treadmillService,
        _analytics = analyticsService,
        _ticker = ticker,
        super(const WorkoutState()) {
    on<WorkoutStarted>(_onStarted);
    on<WorkoutPaused>(_onPaused);
    on<WorkoutResumed>(_onResumed);
    on<WorkoutStopped>(_onStopped);
    on<_WorkoutTicked>(_onTicked);
    on<_WorkoutMetricsUpdated>(_onMetricsUpdated);
  }

  final WorkoutHistoryRepository _historyRepository;
  final TreadmillService _treadmillService;
  final AnalyticsService _analytics;
  final Ticker _ticker;
  List<_CalculatedSegment> _segments = const [];
  bool _autoStopRequested = false;

  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<TreadmillMetrics>? _metricsSubscription;
  double? _resumeSpeedKmh;
  double? _resumeInclinePercent;
  TreadmillMetrics? _metricsBaseline;

  Future<void> _onStarted(
    WorkoutStarted event,
    Emitter<WorkoutState> emit,
  ) async {
    await _tickerSubscription?.cancel();
    await _metricsSubscription?.cancel();
    _resumeSpeedKmh = null;
    _resumeInclinePercent = null;
    _metricsBaseline = null;
    _segments = const [];
    _autoStopRequested = false;

    try {
      await _treadmillService.setSpeed(event.initialSpeedKmh);
      await _treadmillService.setIncline(event.initialInclinePercent);
    } catch (_) {
      // Non-fatal: controls might be unsupported.
    }

    unawaited(
      _analytics.logWorkoutStarted(
        programId: event.plan.id != Isar.autoIncrement
            ? event.plan.id.toString()
            : null,
      ),
    );

    _segments = _calculateSegments(event.plan);
    if (_segments.isNotEmpty) {
      unawaited(_applyStepTargets(0));
    }

    _tickerSubscription = _ticker.tick().listen(
      (_) => add(const _WorkoutTicked()),
    );
    _metricsSubscription = _treadmillService.listenToMetrics().listen(
      (metrics) => add(_WorkoutMetricsUpdated(metrics)),
      onError: (_) => add(const WorkoutStopped()),
    );

    emit(
      state.copyWith(
        status: WorkoutStatus.running,
        plan: event.plan,
        deviceId: event.deviceId,
        startedAt: DateTime.now(),
        elapsed: Duration.zero,
        samples: const <WorkoutMetricSample>[],
        completedSession: null,
        errorMessage: null,
        goalDuration: event.goalDuration,
        goalDistanceMeters: event.goalDistanceMeters,
        currentStepIndex: 0,
      ),
    );
  }

  Future<void> _onPaused(
    WorkoutPaused event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state.status != WorkoutStatus.running) return;
    _tickerSubscription?.pause();
    _resumeSpeedKmh = state.metrics.speedKmh;
    _resumeInclinePercent = state.metrics.inclinePercent;
    emit(state.copyWith(status: WorkoutStatus.paused));
    try {
      await _treadmillService.setSpeed(0);
    } catch (_) {
      // Ignore lack of support.
    }
  }

  Future<void> _onResumed(
    WorkoutResumed event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state.status != WorkoutStatus.paused) return;
    final targetSpeed = _resumeSpeedKmh;
    final targetIncline = _resumeInclinePercent;
    _tickerSubscription?.resume();
    emit(state.copyWith(status: WorkoutStatus.running));
    if (targetSpeed != null) {
      try {
        await _treadmillService.setSpeed(targetSpeed);
      } catch (_) {
        // non fatal
      }
      _resumeSpeedKmh = null;
    }
    if (targetIncline != null) {
      try {
        await _treadmillService.setIncline(targetIncline);
      } catch (_) {
        // ignore
      }
      _resumeInclinePercent = null;
    }
  }

  Future<void> _onStopped(
    WorkoutStopped event,
    Emitter<WorkoutState> emit,
  ) async {
    await _tickerSubscription?.cancel();
    await _metricsSubscription?.cancel();
    if (state.status == WorkoutStatus.idle) return;

    final session = _buildSession(state);
    if (session != null) {
      await _historyRepository.saveSession(session);
      unawaited(_logWorkoutCompleted(session));
    }

    emit(
      state.copyWith(
        status: WorkoutStatus.completed,
        completedSession: session,
      ),
    );
    _resumeSpeedKmh = null;
    _resumeInclinePercent = null;
    _segments = const [];
    _autoStopRequested = false;
  }

  void _onTicked(_WorkoutTicked event, Emitter<WorkoutState> emit) {
    if (state.status != WorkoutStatus.running) return;
    final nextElapsed = state.elapsed + const Duration(seconds: 1);
    emit(state.copyWith(elapsed: nextElapsed));
    _maybeRequestAutoStop(nextElapsed, state.metrics.distanceMeters);
  }

  void _onMetricsUpdated(
    _WorkoutMetricsUpdated event,
    Emitter<WorkoutState> emit,
  ) {
    if (state.status != WorkoutStatus.running) return;
    final relativeElapsed = _relativeElapsed(event.metrics);
    final relativeDistance = _relativeDistance(event.metrics);
    final sample = WorkoutMetricSample(
      elapsedSeconds: relativeElapsed.inSeconds,
      speedKmh: event.metrics.speedKmh,
      inclinePercent: event.metrics.inclinePercent,
      distanceMeters: relativeDistance,
      heartRate: event.metrics.heartRate,
    );

    final updatedSamples = List<WorkoutMetricSample>.from(state.samples)
      ..add(sample);

    final updatedStepIndex = _resolveStepIndex(relativeElapsed);
    if (updatedStepIndex != state.currentStepIndex) {
      unawaited(_applyStepTargets(updatedStepIndex));
    }

    emit(
      state.copyWith(
        metrics: event.metrics.copyWith(
          elapsed: relativeElapsed,
          distanceMeters: relativeDistance,
        ),
        samples: updatedSamples,
        currentStepIndex: updatedStepIndex,
      ),
    );
    _maybeRequestAutoStop(relativeElapsed, relativeDistance);
  }

  WorkoutSession? _buildSession(WorkoutState state) {
    if (state.plan == null || state.startedAt == null) return null;
    return WorkoutSession(
      planId: state.plan!.id,
      startedAt: state.startedAt!,
      endedAt: DateTime.now(),
      deviceId: state.deviceId,
      samples: state.samples,
    );
  }

  @override
  Future<void> close() async {
    await _tickerSubscription?.cancel();
    await _metricsSubscription?.cancel();
    _resumeSpeedKmh = null;
    _resumeInclinePercent = null;
    _metricsBaseline = null;
    return super.close();
  }

  Duration _relativeElapsed(TreadmillMetrics metrics) {
    _metricsBaseline ??= metrics;
    final baseline = _metricsBaseline!;
    final diff = metrics.elapsed - baseline.elapsed;
    return diff.isNegative ? Duration.zero : diff;
  }

  double _relativeDistance(TreadmillMetrics metrics) {
    _metricsBaseline ??= metrics;
    final baseline = _metricsBaseline!;
    final diff = metrics.distanceMeters - baseline.distanceMeters;
    if (diff.isNegative) return 0;
    return diff;
  }

  void _maybeRequestAutoStop(Duration elapsed, double distanceMeters) {
    if (state.status != WorkoutStatus.running) return;
    if (_autoStopRequested) return;
    final goalDuration = state.goalDuration;
    if (goalDuration != null && elapsed >= goalDuration) {
      _autoStopRequested = true;
      add(const WorkoutStopped());
      return;
    }
    final goalDistance = state.goalDistanceMeters;
    if (goalDistance != null && distanceMeters >= goalDistance) {
      _autoStopRequested = true;
      add(const WorkoutStopped());
      return;
    }
    if (_segments.isNotEmpty && elapsed >= _segments.last.end) {
      _autoStopRequested = true;
      add(const WorkoutStopped());
    }
  }

  int _resolveStepIndex(Duration elapsed) {
    if (_segments.isEmpty) return 0;
    for (var i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      if (elapsed < segment.end) {
        return i;
      }
    }
    return max(0, _segments.length - 1);
  }

  List<_CalculatedSegment> _calculateSegments(WorkoutPlan plan) {
    final segments = <_CalculatedSegment>[];
    var cursor = Duration.zero;
    for (final step in plan.steps) {
      final repeats = max(1, step.repeatCount ?? 1);
      for (var i = 0; i < repeats; i++) {
        final duration = _estimateStepDuration(step);
        segments.add(
          _CalculatedSegment(start: cursor, end: cursor + duration, step: step),
        );
        cursor += duration;
      }
    }
    return segments;
  }

  Duration _estimateStepDuration(WorkoutStep step) {
    if (step.durationSeconds != null && step.durationSeconds! > 0) {
      return Duration(seconds: step.durationSeconds!);
    }
    if (step.distanceMeters != null && step.targetSpeedKmh != null) {
      final metersPerSecond = (step.targetSpeedKmh! * 1000) / 3600;
      if (metersPerSecond > 0) {
        final seconds = (step.distanceMeters! / metersPerSecond).round();
        return Duration(seconds: max(1, seconds));
      }
    }
    return const Duration(minutes: 1);
  }

  Future<void> _applyStepTargets(int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= _segments.length) return;
    final step = _segments[stepIndex].step;
    final futures = <Future<void>>[];
    if (step.targetSpeedKmh != null) {
      futures.add(_treadmillService.setSpeed(step.targetSpeedKmh!));
    }
    if (step.inclinePercent != null) {
      futures.add(_treadmillService.setIncline(step.inclinePercent!));
    }
    if (futures.isEmpty) return;
    try {
      await Future.wait(futures);
    } catch (_) {
      // Ignore device control errors for unsupported treadmills.
    }
  }

  Future<void> _logWorkoutCompleted(WorkoutSession session) async {
    final ended = session.endedAt ?? DateTime.now();
    final duration = ended.difference(session.startedAt);
    final distanceMeters =
        session.metrics.isNotEmpty ? (session.metrics.last.distanceMeters ?? 0) : 0;
    await _analytics.logWorkoutCompleted(
      duration: duration,
      distanceKm: distanceMeters > 0 ? distanceMeters / 1000 : null,
    );
  }
}

class _CalculatedSegment {
  _CalculatedSegment({
    required this.start,
    required this.end,
    required this.step,
  });

  final Duration start;
  final Duration end;
  final WorkoutStep step;
}
