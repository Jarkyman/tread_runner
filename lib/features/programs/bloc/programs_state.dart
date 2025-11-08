part of 'programs_bloc.dart';

enum ProgramsStatus { initial, loading, success, failure }

class ProgramsState extends Equatable {
  const ProgramsState({
    this.status = ProgramsStatus.initial,
    this.programs = const [],
  });

  final ProgramsStatus status;
  final List<WorkoutPlan> programs;

  ProgramsState copyWith({
    ProgramsStatus? status,
    List<WorkoutPlan>? programs,
  }) {
    return ProgramsState(
      status: status ?? this.status,
      programs: programs ?? this.programs,
    );
  }

  @override
  List<Object?> get props => [status, programs];
}
