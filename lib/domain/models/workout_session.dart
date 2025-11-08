import 'package:isar/isar.dart';

import 'workout_metric_sample.dart';

part 'workout_session.g.dart';

@collection
class WorkoutSession {
  WorkoutSession({
    this.id = Isar.autoIncrement,
    this.planId,
    required this.startedAt,
    this.endedAt,
    this.deviceId,
    List<WorkoutMetricSample>? samples,
  }) : metrics = samples ?? <WorkoutMetricSample>[];

  Id id;

  int? planId;

  DateTime startedAt;

  DateTime? endedAt;

  String? deviceId;

  List<WorkoutMetricSample> metrics;
}
