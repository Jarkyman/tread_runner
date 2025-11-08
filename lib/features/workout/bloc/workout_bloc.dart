import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ble/treadmill_service.dart';
import '../../../core/utils/ticker.dart';
import '../../../data/workout_history/workout_history_repository.dart';
import '../../../domain/models/workout_metric_sample.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_session.dart';

part 'workout_event.dart';
part 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  WorkoutBloc({
    required WorkoutHistoryRepository workoutHistoryRepository,
    required TreadmillService treadmillService,
    Ticker ticker = const Ticker(),
  })  : _historyRepository = workoutHistoryRepository,
        _treadmillService = treadmillService,
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
  final Ticker _ticker;

  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<TreadmillMetrics>? _metricsSubscription;

  Future<void> _onStarted(
    WorkoutStarted event,
    Emitter<WorkoutState> emit,
  ) async {
    await _tickerSubscription?.cancel();
    await _metricsSubscription?.cancel();

    try {
      await _treadmillService.setSpeed(event.initialSpeedKmh);
      await _treadmillService.setIncline(event.initialInclinePercent);
    } catch (_) {
      // Non-fatal: controls might be unsupported.
    }

    _tickerSubscription =
        _ticker.tick().listen((_) => add(const _WorkoutTicked()));
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
      ),
    );
  }

  Future<void> _onPaused(
    WorkoutPaused event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state.status != WorkoutStatus.running) return;
    _tickerSubscription?.pause();
    emit(state.copyWith(status: WorkoutStatus.paused));
  }

  Future<void> _onResumed(
    WorkoutResumed event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state.status != WorkoutStatus.paused) return;
    _tickerSubscription?.resume();
    emit(state.copyWith(status: WorkoutStatus.running));
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
    }

    emit(
      state.copyWith(
        status: WorkoutStatus.completed,
        completedSession: session,
      ),
    );
  }

  void _onTicked(
    _WorkoutTicked event,
    Emitter<WorkoutState> emit,
  ) {
    if (state.status != WorkoutStatus.running) return;
    emit(
      state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      ),
    );
  }

  void _onMetricsUpdated(
    _WorkoutMetricsUpdated event,
    Emitter<WorkoutState> emit,
  ) {
    if (state.status == WorkoutStatus.idle) return;
    final sample = WorkoutMetricSample(
      elapsedSeconds: event.metrics.elapsed.inSeconds,
      speedKmh: event.metrics.speedKmh,
      inclinePercent: event.metrics.inclinePercent,
      distanceMeters: event.metrics.distanceMeters,
      heartRate: event.metrics.heartRate,
    );

    final updatedSamples = List<WorkoutMetricSample>.from(state.samples)
      ..add(sample);

    emit(
      state.copyWith(
        metrics: event.metrics,
        samples: updatedSamples,
      ),
    );
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
    return super.close();
  }
}
