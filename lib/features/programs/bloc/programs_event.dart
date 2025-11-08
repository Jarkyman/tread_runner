part of 'programs_bloc.dart';

abstract class ProgramsEvent extends Equatable {
  const ProgramsEvent();

  @override
  List<Object?> get props => [];
}

class ProgramsSubscriptionRequested extends ProgramsEvent {
  const ProgramsSubscriptionRequested();
}

class ProgramSaved extends ProgramsEvent {
  const ProgramSaved(this.plan);

  final WorkoutPlan plan;

  @override
  List<Object?> get props => [plan];
}

class ProgramDeleted extends ProgramsEvent {
  const ProgramDeleted(this.planId);

  final Id planId;

  @override
  List<Object?> get props => [planId];
}
