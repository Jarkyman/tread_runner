import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../../data/programs/programs_repository.dart';
import '../../../domain/models/workout_plan.dart';

part 'programs_event.dart';
part 'programs_state.dart';

class ProgramsBloc extends Bloc<ProgramsEvent, ProgramsState> {
  ProgramsBloc(this._programsRepository) : super(const ProgramsState()) {
    on<ProgramsSubscriptionRequested>(_onSubscriptionRequested);
    on<ProgramSaved>(_onProgramSaved);
    on<ProgramDeleted>(_onProgramDeleted);
  }

  final ProgramsRepository _programsRepository;

  Future<void> _onSubscriptionRequested(
    ProgramsSubscriptionRequested event,
    Emitter<ProgramsState> emit,
  ) async {
    emit(state.copyWith(status: ProgramsStatus.loading));
    await emit.forEach<List<WorkoutPlan>>(
      _programsRepository.watchPrograms(),
      onData: (programs) => state.copyWith(
        status: ProgramsStatus.success,
        programs: programs,
      ),
      onError: (_, __) => state.copyWith(status: ProgramsStatus.failure),
    );
  }

  Future<void> _onProgramSaved(
    ProgramSaved event,
    Emitter<ProgramsState> emit,
  ) async {
    try {
      await _programsRepository.saveProgram(event.plan);
    } catch (_) {
      emit(state.copyWith(status: ProgramsStatus.failure));
    }
  }

  Future<void> _onProgramDeleted(
    ProgramDeleted event,
    Emitter<ProgramsState> emit,
  ) async {
    try {
      await _programsRepository.deleteProgram(event.planId);
    } catch (_) {
      emit(state.copyWith(status: ProgramsStatus.failure));
    }
  }
}
