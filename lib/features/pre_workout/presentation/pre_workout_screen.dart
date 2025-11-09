import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/ble/connection_cubit.dart' as connection;
import '../../../core/ble/treadmill_service.dart';
import '../../../core/permissions/ble_permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_plan.dart';
import '../../shared/widgets/connection_status_badge.dart';
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
                _ControlTile(
                  title: 'Speed',
                  value: state.targetSpeedKmh,
                  unit: 'km/h',
                  enabled: allowsAdjustments,
                  onChanged: (value) =>
                      context.read<PreWorkoutCubit>().updateSpeed(value),
                ),
                const SizedBox(height: 16),
                _ControlTile(
                  title: 'Incline',
                  value: state.targetInclinePercent,
                  unit: '%',
                  enabled: allowsAdjustments,
                  onChanged: (value) =>
                      context.read<PreWorkoutCubit>().updateIncline(value),
                ),
                const SizedBox(height: 24),
                _GoalSelector(state: state),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
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

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove,
                onTap: enabled
                    ? () => onChanged((value - _step).clamp(_min, _max))
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${value.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.add,
                onTap: enabled
                    ? () => onChanged((value + _step).clamp(_min, _max))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  double get _step => title == 'Speed' ? 0.1 : 1.0;
  double get _min => title == 'Speed' ? 0 : 0;
  double get _max => title == 'Speed' ? 25 : 20;
}

class _GoalSelector extends StatelessWidget {
  const _GoalSelector({required this.state});

  final PreWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PreWorkoutCubit>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AnimatedToggleSwitch<PreWorkoutGoalType>.size(
        current: state.goalType,
        values: const [
          PreWorkoutGoalType.duration,
          PreWorkoutGoalType.distance,
        ],
        selectedIconScale: 1.0,
        iconAnimationType: AnimationType.onHover,
        customIconBuilder: (context, local, global) {
          final value = local.value;
          final isActive = global.current == value;
          return Center(
            child: Text(
              value == PreWorkoutGoalType.duration ? 'Duration' : 'Distance',
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
        indicatorSize: const Size.fromWidth(240),
        spacing: 0,
        style: ToggleStyle(
          backgroundColor: AppColors.secondary,
          borderColor: AppColors.secondary,
          borderRadius: BorderRadius.circular(26),
          indicatorColor: AppColors.primary,
          indicatorBorderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.transparent,
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        onChanged: (value) => cubit.updateGoalType(value),
      ),
    );
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
        _ValueWheel(
          min: 1,
          max: 120,
          step: 1,
          value: minutes.toDouble(),
          formatter: (value) => '${value.toInt()} min',
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
        _ValueWheel(
          min: 0.1,
          max: 50,
          step: 0.1,
          value: double.parse(value.toStringAsFixed(1)),
          formatter: (v) => '${v.toStringAsFixed(1)} km',
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

    context.read<WorkoutBloc>().add(
      WorkoutStarted(
        plan: state.selectedPlan!,
        initialSpeedKmh: state.targetSpeedKmh,
        initialInclinePercent: state.targetInclinePercent,
        deviceId: connectionState.connectedDeviceId,
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha((0.08 * 255).round()),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _LockedProgramNotice extends StatelessWidget {
  const _LockedProgramNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
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

class _ValueWheel extends StatefulWidget {
  const _ValueWheel({
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.formatter,
    required this.onChanged,
  });

  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;
  final String Function(double) formatter;

  @override
  State<_ValueWheel> createState() => _ValueWheelState();
}

class _ValueWheelState extends State<_ValueWheel> {
  late FixedExtentScrollController _controller;
  late int _currentIndex;

  int get _itemCount => ((widget.max - widget.min) / widget.step).round() + 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexFromValue(widget.value);
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant _ValueWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = _indexFromValue(widget.value);
    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      _controller.jumpToItem(_currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 60,
            child: Container(height: 1, color: AppColors.primary.withAlpha(80)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 90,
            child: Container(height: 1, color: AppColors.primary.withAlpha(80)),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 36,
            perspective: 0.002,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onChanged(_valueFromIndex(index));
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= _itemCount) return null;
                final value = _valueFromIndex(index);
                final isSelected = index == _currentIndex;
                return Center(
                  child: Text(
                    widget.formatter(value),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontSize: isSelected ? 28 : 18,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _indexFromValue(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    return ((clamped - widget.min) / widget.step).round();
  }

  double _valueFromIndex(int index) {
    final raw = widget.min + index * widget.step;
    final clamped = raw.clamp(widget.min, widget.max);
    final decimals = widget.step >= 1 ? 0 : 1;
    return double.parse(clamped.toStringAsFixed(decimals));
  }
}
