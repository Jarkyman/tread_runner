part of 'workout_summary_cubit.dart';

class WorkoutSummaryState extends Equatable {
  const WorkoutSummaryState({
    this.session,
    this.plan,
    this.recentSessions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final WorkoutSession? session;
  final WorkoutPlan? plan;
  final List<WorkoutSession> recentSessions;
  final bool isLoading;
  final String? errorMessage;

  WorkoutSummaryState copyWith({
    WorkoutSession? session,
    WorkoutPlan? plan,
    List<WorkoutSession>? recentSessions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorkoutSummaryState(
      session: session ?? this.session,
      plan: plan ?? this.plan,
      recentSessions: recentSessions ?? this.recentSessions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    session,
    plan,
    recentSessions,
    isLoading,
    errorMessage,
  ];
}
