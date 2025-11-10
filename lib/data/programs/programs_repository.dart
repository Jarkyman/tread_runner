import 'package:isar/isar.dart';

import '../../domain/models/workout_plan.dart';
import '../../domain/models/workout_step.dart';

class ProgramsRepository {
  ProgramsRepository(this._isar);

  final Isar _isar;
  static final WorkoutPlan _timelineDemoPlan = WorkoutPlan(
    name: 'Timeline Demo',
    colorValue: 0xFF8E24AA,
    initialSteps: [
      WorkoutStep(
        type: WorkoutStepType.warmup,
        durationSeconds: 20,
        targetSpeedKmh: 6,
        inclinePercent: 1,
      ),
      WorkoutStep(
        type: WorkoutStepType.run,
        durationSeconds: 20,
        targetSpeedKmh: 10,
        inclinePercent: 1,
      ),
      WorkoutStep(
        type: WorkoutStepType.run,
        durationSeconds: 20,
        targetSpeedKmh: 12,
        inclinePercent: 2,
      ),
      WorkoutStep(
        type: WorkoutStepType.recovery,
        durationSeconds: 20,
        targetSpeedKmh: 7,
        inclinePercent: 1,
      ),
      WorkoutStep(
        type: WorkoutStepType.cooldown,
        durationSeconds: 20,
        targetSpeedKmh: 5.5,
        inclinePercent: 0,
      ),
    ],
  );

  Future<List<WorkoutPlan>> getPrograms() {
    return _isar.workoutPlans.where().findAll();
  }

  Stream<List<WorkoutPlan>> watchPrograms() {
    return _isar.workoutPlans.where().watch(fireImmediately: true);
  }

  Future<WorkoutPlan?> getProgramById(Id id) {
    return _isar.workoutPlans.get(id);
  }

  Future<Id> saveProgram(WorkoutPlan plan) {
    return _isar.writeTxn(() => _isar.workoutPlans.put(plan));
  }

  Future<void> deleteProgram(Id id) {
    return _isar.writeTxn(() => _isar.workoutPlans.delete(id));
  }

  Future<void> seedDefaultsIfNeeded() async {
    final existingCount = await _isar.workoutPlans.count();
    if (existingCount > 0) {
      await _ensureTimelineDemoPlan();
      return;
    }

    final defaults = _buildDefaultPrograms();
    await _isar.writeTxn(() async {
      for (final plan in defaults) {
        await _isar.workoutPlans.put(plan);
      }
    });
    await _ensureTimelineDemoPlan();
  }

  List<WorkoutPlan> _buildDefaultPrograms() {
    return [
      WorkoutPlan(
        name: '20 Minute Tempo',
        colorValue: 0xFFE65100,
        initialSteps: [
          WorkoutStep(
            type: WorkoutStepType.warmup,
            durationSeconds: 5 * 60,
            targetSpeedKmh: 7.5,
            inclinePercent: 1,
          ),
          WorkoutStep(
            type: WorkoutStepType.run,
            durationSeconds: 10 * 60,
            targetSpeedKmh: 9.0,
            inclinePercent: 1,
          ),
          WorkoutStep(
            type: WorkoutStepType.cooldown,
            durationSeconds: 5 * 60,
            targetSpeedKmh: 6.0,
            inclinePercent: 0,
          ),
        ],
      ),
      WorkoutPlan(
        name: 'Interval Booster',
        colorValue: 0xFF1E88E5,
        initialSteps: [
          WorkoutStep(
            type: WorkoutStepType.warmup,
            durationSeconds: 5 * 60,
            targetSpeedKmh: 7.0,
          ),
          WorkoutStep(
            type: WorkoutStepType.run,
            durationSeconds: 120,
            targetSpeedKmh: 10.0,
            inclinePercent: 1,
            repeatCount: 6,
          ),
          WorkoutStep(
            type: WorkoutStepType.recovery,
            durationSeconds: 60,
            targetSpeedKmh: 6.5,
          ),
          WorkoutStep(
            type: WorkoutStepType.cooldown,
            durationSeconds: 5 * 60,
            targetSpeedKmh: 6.0,
          ),
        ],
      ),
      WorkoutPlan(
        name: 'Hill Climber',
        colorValue: 0xFF43A047,
        initialSteps: [
          WorkoutStep(
            type: WorkoutStepType.warmup,
            durationSeconds: 5 * 60,
            targetSpeedKmh: 7.0,
          ),
          WorkoutStep(
            type: WorkoutStepType.hill,
            durationSeconds: 3 * 60,
            targetSpeedKmh: 8.0,
            inclinePercent: 5,
            repeatCount: 4,
          ),
          WorkoutStep(
            type: WorkoutStepType.recovery,
            durationSeconds: 90,
            targetSpeedKmh: 6.5,
            inclinePercent: 1,
          ),
          WorkoutStep(
            type: WorkoutStepType.cooldown,
            durationSeconds: 5 * 60,
            targetSpeedKmh: 6.0,
          ),
        ],
      ),
      // TODO: Remove debug plan once workout timeline UI is finalized.
      _timelineDemoPlan,
    ];
  }

  Future<void> _ensureTimelineDemoPlan() async {
    final existing = await _isar.workoutPlans
        .filter()
        .nameEqualTo(_timelineDemoPlan.name)
        .findFirst();
    if (existing != null) return;

    await _isar.writeTxn(() async {
      await _isar.workoutPlans.put(_timelineDemoPlan);
    });
  }
}
