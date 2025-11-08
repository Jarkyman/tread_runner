import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/workout_session.dart';

class WorkoutSummaryState extends Equatable {
  const WorkoutSummaryState({this.session});

  final WorkoutSession? session;

  WorkoutSummaryState copyWith({WorkoutSession? session}) {
    return WorkoutSummaryState(session: session ?? this.session);
  }

  @override
  List<Object?> get props => [session];
}

class WorkoutSummaryCubit extends Cubit<WorkoutSummaryState> {
  WorkoutSummaryCubit() : super(const WorkoutSummaryState());

  void showSession(WorkoutSession session) {
    emit(WorkoutSummaryState(session: session));
  }

  void clear() => emit(const WorkoutSummaryState());
}
