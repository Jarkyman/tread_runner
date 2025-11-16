import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_step.dart';

enum ProgramSectionGoalType { duration, distance }

class ProgramSection extends Equatable {
  const ProgramSection({
    required this.id,
    this.speedKmh = 8,
    this.inclinePercent = 1,
    this.goalType = ProgramSectionGoalType.duration,
    this.durationMinutes = 5,
    this.distanceMeters = 1000,
    this.repeatCount = 1,
  });

  final int id;
  final double speedKmh;
  final int inclinePercent;
  final ProgramSectionGoalType goalType;
  final int durationMinutes;
  final int distanceMeters;
  final int repeatCount;

  ProgramSection copyWith({
    double? speedKmh,
    int? inclinePercent,
    ProgramSectionGoalType? goalType,
    int? durationMinutes,
    int? distanceMeters,
    int? repeatCount,
  }) {
    return ProgramSection(
      id: id,
      speedKmh: speedKmh ?? this.speedKmh,
      inclinePercent: inclinePercent ?? this.inclinePercent,
      goalType: goalType ?? this.goalType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        speedKmh,
        inclinePercent,
        goalType,
        durationMinutes,
        distanceMeters,
        repeatCount,
      ];
}

class CreateProgramState extends Equatable {
  const CreateProgramState({
    required this.sections,
    required this.colorValue,
    required this.iconCodePoint,
    this.planId,
    this.name = '',
    this.isSaving = false,
    this.errorMessage,
  });

  final List<ProgramSection> sections;
  final int colorValue;
  final int iconCodePoint;
  final Id? planId;
  final String name;
  final bool isSaving;
  final String? errorMessage;

  CreateProgramState copyWith({
    List<ProgramSection>? sections,
    int? colorValue,
    int? iconCodePoint,
    Id? planId,
    String? name,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateProgramState(
      sections: sections ?? this.sections,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        sections,
        colorValue,
        iconCodePoint,
        planId,
        name,
        isSaving,
        errorMessage,
      ];

  factory CreateProgramState.initial(
    WorkoutPlan? initialPlan,
  ) {
    if (initialPlan == null) {
      return CreateProgramState(
        sections: const [ProgramSection(id: 0)],
        colorValue: 0xFF34D399,
        iconCodePoint: Icons.directions_run.codePoint,
      );
    }

    final sections = <ProgramSection>[];
    for (final entry in initialPlan.steps.asMap().entries) {
      final step = entry.value;
      sections.add(
        ProgramSection(
          id: entry.key,
          speedKmh: step.targetSpeedKmh ?? 8,
          inclinePercent: (step.inclinePercent ?? 1).round(),
          goalType: step.distanceMeters != null
              ? ProgramSectionGoalType.distance
              : ProgramSectionGoalType.duration,
          durationMinutes: step.durationSeconds != null
              ? max(1, (step.durationSeconds! / 60).round())
              : 5,
          distanceMeters: step.distanceMeters != null
              ? step.distanceMeters!.round()
              : 1000,
          repeatCount: step.repeatCount ?? 1,
        ),
      );
    }

    return CreateProgramState(
      sections: sections.isEmpty ? const [ProgramSection(id: 0)] : sections,
      colorValue: initialPlan.colorValue,
      iconCodePoint: initialPlan.iconCodePoint,
      name: initialPlan.name,
      planId: initialPlan.id,
    );
  }
}

class CreateProgramCubit extends Cubit<CreateProgramState> {
  CreateProgramCubit({WorkoutPlan? initialPlan})
      : _nextId = _initialNextId(initialPlan),
        super(CreateProgramState.initial(initialPlan));

  int _nextId;

  static int _initialNextId(WorkoutPlan? plan) {
    if (plan == null || plan.steps.isEmpty) return 1;
    return plan.steps.length;
  }

  void updateName(String value) {
    emit(state.copyWith(name: value, clearError: true));
  }

  void updateColor(int colorValue) {
    emit(state.copyWith(colorValue: colorValue));
  }

  void updateIcon(int iconCodePoint) {
    emit(state.copyWith(iconCodePoint: iconCodePoint));
  }

  void addSection() {
    final sections = List<ProgramSection>.from(state.sections)
      ..add(ProgramSection(id: _nextId++));
    emit(state.copyWith(sections: sections));
  }

  void removeSection(int id) {
    if (state.sections.length <= 1) {
      return;
    }
    final sections = state.sections.where((section) => section.id != id).toList();
    emit(state.copyWith(sections: sections));
  }

  void updateSpeed(int id, double delta) {
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      final newSpeed = (section.speedKmh + delta).clamp(1, 20);
      return section.copyWith(speedKmh: double.parse(newSpeed.toStringAsFixed(1)));
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  void setSpeedValue(int id, double value) {
    final normalized = value.clamp(1, 20);
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      return section.copyWith(
        speedKmh: double.parse(normalized.toStringAsFixed(1)),
      );
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  void updateIncline(int id, int delta) {
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      final newIncline = (section.inclinePercent + delta).clamp(0, 15);
      return section.copyWith(inclinePercent: newIncline);
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  void setInclineValue(int id, double value) {
    final normalized = value.clamp(0, 15).round();
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      return section.copyWith(inclinePercent: normalized);
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  void updateGoalType(int id, ProgramSectionGoalType type) {
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      return section.copyWith(goalType: type);
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  void updateDuration(int id, int minutes) {
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      return section.copyWith(durationMinutes: minutes);
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  void updateDistance(int id, int meters) {
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      return section.copyWith(distanceMeters: meters);
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  void updateRepeat(int id, int repeatCount) {
    final normalized = repeatCount.clamp(1, 99);
    final sections = state.sections.map((section) {
      if (section.id != id) return section;
      return section.copyWith(repeatCount: normalized);
    }).toList();
    emit(state.copyWith(sections: sections));
  }

  WorkoutPlan? buildPlan(List<WorkoutPlan> existingPrograms) {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Program name cannot be empty.',
          isSaving: false,
        ),
      );
      return null;
    }
    if (state.sections.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Add at least one section.',
          isSaving: false,
        ),
      );
      return null;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    final lowerName = name.toLowerCase();
    final hasDuplicate = existingPrograms.any(
      (plan) => plan.name.toLowerCase() == lowerName && plan.id != state.planId,
    );
    if (hasDuplicate) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Program with this name already exists.',
        ),
      );
      return null;
    }

    final steps = <WorkoutStep>[];
    for (final section in state.sections) {
      steps.add(
        WorkoutStep(
          targetSpeedKmh: section.speedKmh,
          inclinePercent: section.inclinePercent.toDouble(),
          durationSeconds: section.goalType == ProgramSectionGoalType.duration
              ? section.durationMinutes * 60
              : null,
          distanceMeters: section.goalType == ProgramSectionGoalType.distance
              ? section.distanceMeters.toDouble()
              : null,
          repeatCount: section.repeatCount > 1 ? section.repeatCount : null,
        ),
      );
    }

    emit(state.copyWith(isSaving: false));
    return WorkoutPlan(
      id: state.planId ?? Isar.autoIncrement,
      name: name,
      colorValue: state.colorValue,
      iconCodePoint: state.iconCodePoint,
      initialSteps: steps,
    );
  }
}
