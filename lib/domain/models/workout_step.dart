import 'package:isar/isar.dart';

part 'workout_step.g.dart';

@embedded
class WorkoutStep {
  WorkoutStep({
    this.type = WorkoutStepType.run,
    this.durationSeconds,
    this.distanceMeters,
    this.targetSpeedKmh,
    this.inclinePercent,
    this.repeatCount,
  });

  @Enumerated(EnumType.name)
  WorkoutStepType type;

  /// Duration of the step in seconds. Mutually exclusive with [distanceMeters].
  int? durationSeconds;

  /// Distance goal in meters. Mutually exclusive with [durationSeconds].
  double? distanceMeters;

  /// Target treadmill speed in km/h for this step.
  double? targetSpeedKmh;

  /// Target incline percentage.
  double? inclinePercent;

  /// Optional repeat count for this step (e.g. repeats of an interval block).
  int? repeatCount;
}

enum WorkoutStepType {
  warmup,
  run,
  recovery,
  cooldown,
  hill,
}
