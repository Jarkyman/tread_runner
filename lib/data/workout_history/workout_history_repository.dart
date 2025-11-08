import 'package:isar/isar.dart';

import '../../domain/models/workout_session.dart';

class WorkoutHistoryRepository {
  WorkoutHistoryRepository(this._isar);

  final Isar _isar;

  Future<List<WorkoutSession>> getRecentSessions({int limit = 20}) {
    return _isar.workoutSessions
        .where()
        .sortByStartedAtDesc()
        .limit(limit)
        .findAll();
  }

  Stream<List<WorkoutSession>> watchSessions() {
    return _isar.workoutSessions
        .where()
        .sortByStartedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<WorkoutSession?> getSession(Id id) {
    return _isar.workoutSessions.get(id);
  }

  Future<Id> saveSession(WorkoutSession session) {
    return _isar.writeTxn(() => _isar.workoutSessions.put(session));
  }

  Future<void> deleteSession(Id id) {
    return _isar.writeTxn(() => _isar.workoutSessions.delete(id));
  }

  Future<void> clearSessions() {
    return _isar.writeTxn(() => _isar.workoutSessions.clear());
  }
}
