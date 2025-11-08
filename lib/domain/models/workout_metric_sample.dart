import 'package:isar/isar.dart';

part 'workout_metric_sample.g.dart';

@embedded
class WorkoutMetricSample {
  WorkoutMetricSample({
    this.elapsedSeconds = 0,
    this.speedKmh,
    this.inclinePercent,
    this.distanceMeters,
    this.heartRate,
  });

  /// Seconds elapsed since workout start.
  int elapsedSeconds;

  double? speedKmh;

  double? inclinePercent;

  double? distanceMeters;

  int? heartRate;
}
