import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/workout_history/workout_history_repository.dart';
import '../../../domain/models/workout_session.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.recentSessions = const [],
    this.status = DashboardStatus.loading,
  });

  final List<WorkoutSession> recentSessions;
  final DashboardStatus status;

  DashboardState copyWith({
    List<WorkoutSession>? recentSessions,
    DashboardStatus? status,
  }) {
    return DashboardState(
      recentSessions: recentSessions ?? this.recentSessions,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [recentSessions, status];
}

enum DashboardStatus { loading, success, failure }

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._historyRepository) : super(const DashboardState()) {
    _subscribe();
  }

  final WorkoutHistoryRepository _historyRepository;
  StreamSubscription<List<WorkoutSession>>? _historySubscription;

  void _subscribe() {
    _historySubscription?.cancel();
    _historySubscription = _historyRepository.watchSessions().listen(
      (sessions) {
        emit(
          state.copyWith(
            recentSessions: sessions,
            status: DashboardStatus.success,
          ),
        );
      },
      onError: (_) {
        emit(state.copyWith(status: DashboardStatus.failure));
      },
    );
  }

  @override
  Future<void> close() async {
    await _historySubscription?.cancel();
    return super.close();
  }
}
