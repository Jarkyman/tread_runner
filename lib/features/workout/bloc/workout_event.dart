part of 'workout_bloc.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class WorkoutStarted extends WorkoutEvent {
  const WorkoutStarted({
    required this.plan,
    required this.initialSpeedKmh,
    required this.initialInclinePercent,
    this.deviceId,
  });

  final WorkoutPlan plan;
  final double initialSpeedKmh;
  final double initialInclinePercent;
  final String? deviceId;

  @override
  List<Object?> get props =>
      [plan, initialSpeedKmh, initialInclinePercent, deviceId];
}

class WorkoutPaused extends WorkoutEvent {
  const WorkoutPaused();
}

class WorkoutResumed extends WorkoutEvent {
  const WorkoutResumed();
}

class WorkoutStopped extends WorkoutEvent {
  const WorkoutStopped();
}

class _WorkoutTicked extends WorkoutEvent {
  const _WorkoutTicked({this.delta = const Duration(seconds: 1)});

  final Duration delta;

  @override
  List<Object?> get props => [delta];
}

class _WorkoutMetricsUpdated extends WorkoutEvent {
  const _WorkoutMetricsUpdated(this.metrics);

  final TreadmillMetrics metrics;

  @override
  List<Object?> get props => [metrics];
}
