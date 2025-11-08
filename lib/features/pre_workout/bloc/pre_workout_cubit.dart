import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/programs/programs_repository.dart';
import '../../../domain/models/workout_plan.dart';

enum PreWorkoutGoalType { duration, distance }

class PreWorkoutState extends Equatable {
  const PreWorkoutState({
    required this.availablePlans,
    this.selectedPlan,
    this.targetSpeedKmh = 8,
    this.targetInclinePercent = 1,
    this.goalType = PreWorkoutGoalType.duration,
    this.goalDuration = const Duration(minutes: 20),
    this.goalDistanceKm = 5,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<WorkoutPlan> availablePlans;
  final WorkoutPlan? selectedPlan;
  final double targetSpeedKmh;
  final double targetInclinePercent;
  final PreWorkoutGoalType goalType;
  final Duration goalDuration;
  final double goalDistanceKm;
  final bool isLoading;
  final String? errorMessage;

  PreWorkoutState copyWith({
    List<WorkoutPlan>? availablePlans,
    WorkoutPlan? selectedPlan,
    double? targetSpeedKmh,
    double? targetInclinePercent,
    PreWorkoutGoalType? goalType,
    Duration? goalDuration,
    double? goalDistanceKm,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PreWorkoutState(
      availablePlans: availablePlans ?? this.availablePlans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      targetSpeedKmh: targetSpeedKmh ?? this.targetSpeedKmh,
      targetInclinePercent: targetInclinePercent ?? this.targetInclinePercent,
      goalType: goalType ?? this.goalType,
      goalDuration: goalDuration ?? this.goalDuration,
      goalDistanceKm: goalDistanceKm ?? this.goalDistanceKm,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        availablePlans,
        selectedPlan,
        targetSpeedKmh,
        targetInclinePercent,
        goalType,
        goalDuration,
        goalDistanceKm,
        isLoading,
        errorMessage,
      ];

  static PreWorkoutState initial() => const PreWorkoutState(
        availablePlans: [],
      );
}

class PreWorkoutCubit extends Cubit<PreWorkoutState> {
  PreWorkoutCubit({
    required ProgramsRepository programsRepository,
  })  : _programsRepository = programsRepository,
        super(PreWorkoutState.initial());

  final ProgramsRepository _programsRepository;
  static const int _runPlanId = -100;
  static final WorkoutPlan _runPlan = WorkoutPlan(
    id: _runPlanId,
    name: 'Run',
    colorValue: 0xFF34D399,
    initialSteps: const [],
  );

  static int get runPlanId => _runPlanId;

  Future<void> loadInitialPlan() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final plans = await _programsRepository.getPrograms();
      final mergedPlans = <WorkoutPlan>[
        _runPlan,
        ...plans.where((plan) => plan.id != _runPlanId),
      ];
      final defaultPlan = state.selectedPlan ?? _runPlan;
      emit(
        state.copyWith(
          availablePlans: mergedPlans,
          selectedPlan: defaultPlan,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load programs',
        ),
      );
    }
  }

  void selectPlan(WorkoutPlan plan) {
    emit(state.copyWith(selectedPlan: plan));
  }

  void updateSpeed(double speedKmh) {
    emit(state.copyWith(targetSpeedKmh: speedKmh.clamp(1, 25)));
  }

  void updateIncline(double inclinePercent) {
    emit(state.copyWith(targetInclinePercent: inclinePercent.clamp(0, 20)));
  }

  void updateGoalType(PreWorkoutGoalType type) {
    emit(state.copyWith(goalType: type));
  }

  void updateGoalDuration(Duration duration) {
    emit(state.copyWith(goalDuration: duration));
  }

  void updateGoalDistance(double distanceKm) {
    emit(state.copyWith(goalDistanceKm: distanceKm));
  }
}
