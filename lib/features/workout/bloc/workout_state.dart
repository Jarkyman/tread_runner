part of 'workout_bloc.dart';

enum WorkoutStatus { idle, running, paused, completed }

class WorkoutState extends Equatable {
  const WorkoutState({
    this.status = WorkoutStatus.idle,
    this.plan,
    this.deviceId,
    this.startedAt,
    this.elapsed = Duration.zero,
    this.currentStepIndex = 0,
    this.metrics = TreadmillMetrics.zero,
    this.samples = const <WorkoutMetricSample>[],
    this.completedSession,
    this.errorMessage,
    this.goalDuration,
    this.goalDistanceMeters,
  });

  final WorkoutStatus status;
  final WorkoutPlan? plan;
  final String? deviceId;
  final DateTime? startedAt;
  final Duration elapsed;
  final int currentStepIndex;
  final TreadmillMetrics metrics;
  final List<WorkoutMetricSample> samples;
  final WorkoutSession? completedSession;
  final String? errorMessage;
  final Duration? goalDuration;
  final double? goalDistanceMeters;

  WorkoutState copyWith({
    WorkoutStatus? status,
    WorkoutPlan? plan,
    String? deviceId,
    DateTime? startedAt,
    Duration? elapsed,
    int? currentStepIndex,
    TreadmillMetrics? metrics,
    List<WorkoutMetricSample>? samples,
    WorkoutSession? completedSession,
    String? errorMessage,
    Duration? goalDuration,
    double? goalDistanceMeters,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      deviceId: deviceId ?? this.deviceId,
      startedAt: startedAt ?? this.startedAt,
      elapsed: elapsed ?? this.elapsed,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      metrics: metrics ?? this.metrics,
      samples: samples ?? this.samples,
      completedSession: completedSession ?? this.completedSession,
      errorMessage: errorMessage ?? this.errorMessage,
      goalDuration: goalDuration ?? this.goalDuration,
      goalDistanceMeters: goalDistanceMeters ?? this.goalDistanceMeters,
    );
  }

  @override
  List<Object?> get props => [
        status,
        plan,
        deviceId,
        startedAt,
        elapsed,
        currentStepIndex,
        metrics,
        samples,
        completedSession,
        errorMessage,
        goalDuration,
        goalDistanceMeters,
      ];
}
