import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../../data/programs/programs_repository.dart';
import '../../../data/workout_history/workout_history_repository.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_session.dart';

class WorkoutSummaryState extends Equatable {
  const WorkoutSummaryState({
    this.session,
    this.plan,
    this.isLoading = false,
    this.errorMessage,
  });

  final WorkoutSession? session;
  final WorkoutPlan? plan;
  final bool isLoading;
  final String? errorMessage;

  WorkoutSummaryState copyWith({
    WorkoutSession? session,
    WorkoutPlan? plan,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorkoutSummaryState(
      session: session ?? this.session,
      plan: plan ?? this.plan,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [session, plan, isLoading, errorMessage];
}

class WorkoutSummaryCubit extends Cubit<WorkoutSummaryState> {
  WorkoutSummaryCubit({
    required WorkoutHistoryRepository historyRepository,
    required ProgramsRepository programsRepository,
  })  : _historyRepository = historyRepository,
        _programsRepository = programsRepository,
        super(const WorkoutSummaryState());

  final WorkoutHistoryRepository _historyRepository;
  final ProgramsRepository _programsRepository;

  Future<void> loadSession(Id id) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final session = await _historyRepository.getSession(id);
      if (session == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Workout not found.',
          ),
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

  Future<void> showSession(
    WorkoutSession session, {
    WorkoutPlan? plan,
  }) async {
    final resolvedPlan =
        plan ?? await _fetchPlan(session.planId);
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
    final updated = WorkoutSession(
      id: session.id,
      planId: session.planId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      deviceId: session.deviceId,
      samples: List.of(session.metrics),
      note: note,
    );
    await _historyRepository.saveSession(updated);
    emit(state.copyWith(session: updated));
  }

  Future<WorkoutPlan?> _fetchPlan(int? planId) {
    if (planId == null) return Future.value(null);
    return _programsRepository.getProgramById(planId);
  }

  void clear() => emit(const WorkoutSummaryState());
}
