import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../../data/programs/programs_repository.dart';
import '../../../data/workout_history/workout_history_repository.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_session.dart';

part 'workout_summary_state.dart';

class WorkoutSummaryCubit extends Cubit<WorkoutSummaryState> {
  WorkoutSummaryCubit({
    required WorkoutHistoryRepository historyRepository,
    required ProgramsRepository programsRepository,
  }) : _historyRepository = historyRepository,
       _programsRepository = programsRepository,
       super(const WorkoutSummaryState()) {
    _sessionSubscription = _historyRepository.watchSessions().listen(
      _handleSessionStream,
    );
  }

  final WorkoutHistoryRepository _historyRepository;
  final ProgramsRepository _programsRepository;
  StreamSubscription<List<WorkoutSession>>? _sessionSubscription;

  Future<void> loadSession(Id id) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final session = await _historyRepository.getSession(id);
      if (session == null) {
        emit(
          state.copyWith(isLoading: false, errorMessage: 'Workout not found.'),
        );
        return;
      }
      final plan = await _fetchPlan(session.planId);
      emit(
        state.copyWith(
          session: session,
          plan: plan,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load workout summary.',
        ),
      );
    }
  }

  Future<void> showSession(WorkoutSession session, {WorkoutPlan? plan}) async {
    final resolvedPlan = plan ?? await _fetchPlan(session.planId);
    emit(
      state.copyWith(
        session: session,
        plan: resolvedPlan,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  Future<void> updateNote(String note) async {
    final session = state.session;
    if (session == null) return;
    final updated = session.copyWith(note: note);
    await _historyRepository.saveSession(updated);
    emit(state.copyWith(session: updated));
  }

  Future<WorkoutPlan?> _fetchPlan(int? planId) {
    if (planId == null) return Future.value(null);
    return _programsRepository.getProgramById(planId);
  }

  void clear() => emit(const WorkoutSummaryState());

  void _handleSessionStream(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      emit(
        state.copyWith(
          recentSessions: const [],
          session: null,
          plan: null,
          isLoading: false,
        ),
      );
      return;
    }
    final current = state.session;
    final nextSession = current != null
        ? sessions.firstWhere(
            (it) => it.id == current.id,
            orElse: () => sessions.first,
          )
        : sessions.first;
    emit(
      state.copyWith(
        recentSessions: sessions,
        session: nextSession,
        isLoading: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    return super.close();
  }
}
