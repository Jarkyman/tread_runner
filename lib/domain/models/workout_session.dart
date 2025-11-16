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
    this.note,
  }) : metrics = samples ?? <WorkoutMetricSample>[];

  Id id;

  int? planId;

  DateTime startedAt;

  DateTime? endedAt;

  String? deviceId;

  List<WorkoutMetricSample> metrics;

  String? note;

  WorkoutSession copyWith({
    Id? id,
    int? planId,
    DateTime? startedAt,
    DateTime? endedAt,
    String? deviceId,
    List<WorkoutMetricSample>? metrics,
    String? note,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      deviceId: deviceId ?? this.deviceId,
      samples: metrics ?? this.metrics,
      note: note ?? this.note,
    );
  }
}
