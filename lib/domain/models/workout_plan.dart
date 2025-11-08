import 'package:isar/isar.dart';

import 'workout_step.dart';

part 'workout_plan.g.dart';

@collection
class WorkoutPlan {
  WorkoutPlan({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.colorValue,
    List<WorkoutStep>? initialSteps,
  }) : steps = initialSteps ?? <WorkoutStep>[];

  Id id;

  late String name;

  /// ARGB color stored as 0xAARRGGBB integer.
  int colorValue;

  List<WorkoutStep> steps;
}
