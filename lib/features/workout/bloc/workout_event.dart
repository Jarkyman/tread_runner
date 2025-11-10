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
    this.goalDuration,
    this.goalDistanceMeters,
  });

  final WorkoutPlan plan;
  final double initialSpeedKmh;
  final double initialInclinePercent;
  final String? deviceId;
  final Duration? goalDuration;
  final double? goalDistanceMeters;

  @override
  List<Object?> get props =>
      [
        plan,
        initialSpeedKmh,
        initialInclinePercent,
        deviceId,
        goalDuration,
        goalDistanceMeters,
      ];
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
  const _WorkoutTicked();
}

class _WorkoutMetricsUpdated extends WorkoutEvent {
  const _WorkoutMetricsUpdated(this.metrics);

  final TreadmillMetrics metrics;

  @override
  List<Object?> get props => [metrics];
}
