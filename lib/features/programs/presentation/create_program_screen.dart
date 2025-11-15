import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/programs/programs_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/duration_distance_toggle.dart';
import '../../shared/widgets/metric_adjuster.dart';
import '../../shared/widgets/value_wheel_picker.dart';
import '../create_program_cubit.dart';

class CreateProgramScreen extends StatelessWidget {
  const CreateProgramScreen({super.key});

  static const routeName = '/create-program';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateProgramCubit(
        context.read<ProgramsRepository>(),
      ),
      child: const _CreateProgramView(),
    );
  }
}

class _CreateProgramView extends StatelessWidget {
  const _CreateProgramView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateProgramCubit, CreateProgramState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
        if (state.didSave) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Create Program',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: state.isSaving
                    ? null
                    : () => context.read<CreateProgramCubit>().saveProgram(),
                child: state.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Program Name',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: state.name,
                        onChanged:
                            context.read<CreateProgramCubit>().updateName,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Custom Program',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: AppColors.secondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ColorPicker(
                      selectedColor: state.colorValue,
                      selectedIconCodePoint: state.iconCodePoint,
                      onColorSelected:
                          context.read<CreateProgramCubit>().updateColor,
                      onIconSelected:
                          context.read<CreateProgramCubit>().updateIcon,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                for (final section in state.sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SectionCard(section: section),
                  ),
                _AddSectionButton(
                  onTap: context.read<CreateProgramCubit>().addSection,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selectedColor,
    required this.selectedIconCodePoint,
    required this.onColorSelected,
    required this.onIconSelected,
  });

  final int selectedColor;
  final int selectedIconCodePoint;
  final ValueChanged<int> onColorSelected;
  final ValueChanged<int> onIconSelected;

  static const _palette = [
    0xFF34D399,
    0xFFF87171,
    0xFF60A5FA,
    0xFFFBBF24,
    0xFF8B5CF6,
    0xFFEC4899,
  ];

  static const _icons = [
    Icons.directions_run,
    Icons.fitness_center,
    Icons.show_chart,
    Icons.bolt,
    Icons.terrain,
    Icons.flag,
  ];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPicker(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Color(selectedColor),
          shape: BoxShape.circle,
        ),
        child: Icon(
          IconData(selectedIconCodePoint, fontFamily: 'MaterialIcons'),
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          title: const Text(
            'Select Color & Icon',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _palette.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () {
                      onColorSelected(color);
                      Navigator.of(dialogCtx).pop();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = icon.codePoint == selectedIconCodePoint;
                  return GestureDetector(
                    onTap: () {
                      onIconSelected(icon.codePoint);
                      Navigator.of(dialogCtx).pop();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final ProgramSection section;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateProgramCubit>();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Section ${section.id + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.repeat, color: Colors.white70),
                onPressed: () => _showRepeatDialog(context, section),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => cubit.removeSection(section.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricAdjuster(
            title: 'Speed',
            value: section.speedKmh,
            unit: 'km/h',
            min: 1,
            max: 20,
            step: 0.1,
            style: MetricAdjusterStyle.inline,
            onChanged: (value) =>
                cubit.setSpeedValue(section.id, value),
          ),
          const SizedBox(height: 12),
          MetricAdjuster(
            title: 'Incline',
            value: section.inclinePercent.toDouble(),
            unit: '%',
            min: 0,
            max: 15,
            step: 1,
            decimals: 0,
            style: MetricAdjusterStyle.inline,
            onChanged: (value) =>
                cubit.setInclineValue(section.id, value),
          ),
          const SizedBox(height: 16),
          DurationDistanceToggle<ProgramSectionGoalType>(
            durationValue: ProgramSectionGoalType.duration,
            distanceValue: ProgramSectionGoalType.distance,
            currentValue: section.goalType,
            onChanged: (value) => cubit.updateGoalType(section.id, value),
          ),
          const SizedBox(height: 12),
          if (section.goalType == ProgramSectionGoalType.duration)
            _DurationPicker(
              value: section.durationMinutes,
              onChanged: (minutes) => cubit.updateDuration(section.id, minutes),
            )
          else
            _DistancePicker(
              value: section.distanceMeters,
              onChanged: (meters) => cubit.updateDistance(section.id, meters),
            ),
        ],
      ),
    );
  }

  Future<void> _showRepeatDialog(
    BuildContext context,
    ProgramSection section,
  ) async {
    final cubit = context.read<CreateProgramCubit>();
    int temp = section.repeatCount;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) {
            return StatefulBuilder(
              builder: (ctx, setStateDialog) {
                return AlertDialog(
                  backgroundColor: AppColors.secondary,
                  title: const Text(
                    'Repeat Section',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: () {
                          setStateDialog(
                            () => temp = max(1, temp - 1),
                          );
                        },
                      ),
                      Text(
                        '$temp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          setStateDialog(
                            () => temp = min(99, temp + 1),
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: const Text('Apply'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
    if (confirmed) {
      cubit.updateRepeat(section.id, temp);
    }
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(1, 90);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ValueWheelPicker(
          min: 1,
          max: 90,
          step: 1,
          value: normalized.toDouble(),
          labelBuilder: (minutes) => '${minutes.toInt()} min',
          onChanged: (minutes) => onChanged(minutes.toInt()),
        ),
      ],
    );
  }
}

class _DistancePicker extends StatelessWidget {
  const _DistancePicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final kilometers = (value / 1000).clamp(0.1, 50.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distance',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ValueWheelPicker(
          min: 0.1,
          max: 50,
          step: 0.1,
          value: double.parse(kilometers.toStringAsFixed(1)),
          labelBuilder: (value) =>
              value >= 1 ? '${value.toStringAsFixed(1)} km' : '${(value * 1000).round()} m',
          onChanged: (km) => onChanged((km * 1000).round()),
        ),
      ],
    );
  }
}

class _AddSectionButton extends StatelessWidget {
  const _AddSectionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Add New Section',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
