import 'package:isar/isar.dart';

import 'workout_step.dart';

part 'workout_plan.g.dart';

@collection
class WorkoutPlan {
  WorkoutPlan({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.colorValue,
    this.iconCodePoint = 0xE566,
    List<WorkoutStep>? initialSteps,
  }) : steps = initialSteps ?? <WorkoutStep>[];

  Id id;

  late String name;

  /// ARGB color stored as 0xAARRGGBB integer.
  int colorValue;

  /// Material icon code point used for the program badge.
  int iconCodePoint;

  List<WorkoutStep> steps;
}
