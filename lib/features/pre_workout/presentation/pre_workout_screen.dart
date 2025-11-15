import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/ble/connection_cubit.dart' as connection;
import '../../../core/ble/treadmill_service.dart';
import '../../../core/permissions/ble_permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_plan.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/connection_status_badge.dart';
import '../../shared/widgets/duration_distance_toggle.dart';
import '../../shared/widgets/metric_adjuster.dart';
import '../../shared/widgets/value_wheel_picker.dart';
import '../../workout/bloc/workout_bloc.dart';
import '../../workout/presentation/workout_screen.dart';
import '../bloc/pre_workout_cubit.dart';

class PreWorkoutScreen extends StatefulWidget {
  const PreWorkoutScreen({super.key});

  static const routeName = '/pre-workout';

  @override
  State<PreWorkoutScreen> createState() => _PreWorkoutScreenState();
}

class _PreWorkoutScreenState extends State<PreWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsService>().logScreenView('pre_workout');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 200,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: ConnectionStatusBadge(style: ConnectionBadgeStyle.compact),
        ),
        title: const Text(
          'New Workout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(child: _PreWorkoutBody()),
    );
  }
}

class _PreWorkoutBody extends StatelessWidget {
  const _PreWorkoutBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreWorkoutCubit, PreWorkoutState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.selectedPlan == null) {
          return Center(
            child: Text(
              'No programs available',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
          );
        }

        final allowsAdjustments =
            state.selectedPlan!.id == PreWorkoutCubit.runPlanId;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgramHeader(state: state),
              const SizedBox(height: 24),
              if (allowsAdjustments) ...[
                MetricAdjuster(
                  title: 'Speed',
                  unit: 'km/h',
                  value: state.targetSpeedKmh,
                  min: 1,
                  max: 25,
                  step: 0.1,
                  enabled: allowsAdjustments,
                  onChanged: (value) =>
                      context.read<PreWorkoutCubit>().updateSpeed(value),
                ),
                const SizedBox(height: 16),
                MetricAdjuster(
                  title: 'Incline',
                  unit: '%',
                  value: state.targetInclinePercent,
                  min: 0,
                  max: 20,
                  step: 1,
                  decimals: 0,
                  enabled: allowsAdjustments,
                  onChanged: (value) =>
                      context.read<PreWorkoutCubit>().updateIncline(value),
                ),
                const SizedBox(height: 24),
                DurationDistanceToggle<PreWorkoutGoalType>(
                  durationValue: PreWorkoutGoalType.duration,
                  distanceValue: PreWorkoutGoalType.distance,
                  currentValue: state.goalType,
                  onChanged: context.read<PreWorkoutCubit>().updateGoalType,
                ),
                const SizedBox(height: 16),
                _GoalPicker(state: state),
              ] else ...[
                const _LockedProgramNotice(),
              ],
              const SizedBox(height: 32),
              _PreWorkoutActions(state: state),
            ],
          ),
        );
      },
    );
  }
}

class _ProgramHeader extends StatelessWidget {
  const _ProgramHeader({required this.state});

  final PreWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final plan = state.selectedPlan!;
    final iconData = _programIcon(plan);
    final tint = Color(plan.colorValue);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withAlpha((0.2 * 255).round()),
            ),
            child: Icon(iconData, color: tint),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Program', style: TextStyle(color: Colors.white54)),
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<WorkoutPlan>(
            color: AppColors.secondary,
            icon: const Icon(Icons.expand_more, color: Colors.white),
            onSelected: (value) =>
                context.read<PreWorkoutCubit>().selectPlan(value),
            itemBuilder: (context) {
              return state.availablePlans
                  .map(
                    (plan) => PopupMenuItem(
                      value: plan,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(plan.colorValue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            plan.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  IconData _programIcon(WorkoutPlan plan) {
    final name = plan.name.toLowerCase();
    if (name.contains('hill')) return Icons.terrain;
    if (name.contains('interval')) return Icons.timeline;
    if (name.contains('speed')) return Icons.speed;
    if (name.contains('endurance')) return Icons.show_chart;
    return Icons.fitness_center;
  }
}

class _GoalPicker extends StatelessWidget {
  const _GoalPicker({required this.state});

  final PreWorkoutState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: state.goalType == PreWorkoutGoalType.duration
          ? _DurationPicker(duration: state.goalDuration)
          : _DistancePicker(distanceKm: state.goalDistanceKm),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PreWorkoutCubit>();
    final minutes = duration.inMinutes.clamp(1, 120);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ValueWheelPicker(
          min: 5,
          max: 120,
          step: 1,
          value: minutes.toDouble(),
          labelBuilder: (value) => '${value.toInt()} min',
          onChanged: (value) =>
              cubit.updateGoalDuration(Duration(minutes: value.toInt())),
        ),
      ],
    );
  }
}

class _DistancePicker extends StatelessWidget {
  const _DistancePicker({required this.distanceKm});

  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PreWorkoutCubit>();
    final value = distanceKm.clamp(0.1, 50.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distance',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ValueWheelPicker(
          min: 0.1,
          max: 50,
          step: 0.1,
          value: double.parse(value.toStringAsFixed(1)),
          labelBuilder: (v) => '${v.toStringAsFixed(1)} km',
          onChanged: (v) =>
              cubit.updateGoalDistance(double.parse(v.toStringAsFixed(1))),
        ),
      ],
    );
  }
}

class _PreWorkoutActions extends StatelessWidget {
  const _PreWorkoutActions({required this.state});

  final PreWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final connectionState = context.watch<connection.ConnectionCubit>().state;
    final isConnected =
        connectionState.status == TreadmillConnectionState.connected;
    final primaryLabel = isConnected ? 'Begin Workout' : 'Connect treadmill';

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () => _handlePrimaryAction(context, connectionState),
            child: Text(
              primaryLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    connection.ConnectionState connectionState,
  ) async {
    final cubit = context.read<PreWorkoutCubit>();
    final state = cubit.state;
    if (state.selectedPlan == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a program.')));
      return;
    }

    final isConnected =
        connectionState.status == TreadmillConnectionState.connected;
    if (!isConnected) {
      final connectionCubit = context.read<connection.ConnectionCubit>();
      final scanStarted = await connectionCubit.startScan();
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (scanStarted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Scanning for treadmills...')),
        );
      } else {
        final latestState = connectionCubit.state;
        final fallbackMessage =
            latestState.errorMessage ??
            _permissionFallbackText(latestState.permissionStatus);
        messenger.showSnackBar(SnackBar(content: Text(fallbackMessage)));
      }
      return;
    }

    final goalDuration =
        state.goalType == PreWorkoutGoalType.duration ? state.goalDuration : null;
    final double? goalDistanceMeters =
        state.goalType == PreWorkoutGoalType.distance
            ? state.goalDistanceKm * 1000
            : null;

    context.read<WorkoutBloc>().add(
      WorkoutStarted(
        plan: state.selectedPlan!,
        initialSpeedKmh: state.targetSpeedKmh,
        initialInclinePercent: state.targetInclinePercent,
        deviceId: connectionState.connectedDeviceId,
        goalDuration: goalDuration,
        goalDistanceMeters: goalDistanceMeters,
      ),
    );

    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(WorkoutScreen.routeName);
  }

  String _permissionFallbackText(BlePermissionStatus status) {
    switch (status) {
      case BlePermissionStatus.denied:
        return 'Bluetooth permission is required to find your treadmill.';
      case BlePermissionStatus.permanentlyDenied:
        return 'Bluetooth access is disabled. Enable it in system settings to connect.';
      case BlePermissionStatus.granted:
      case BlePermissionStatus.unknown:
        return 'Unable to start scan. Please try again.';
    }
  }
}

class _LockedProgramNotice extends StatelessWidget {
  const _LockedProgramNotice();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preset program',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'This plan uses its own speed, incline, and goal settings.',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            'Allow editing preset programs in a future update.',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
