import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DurationDistanceToggle<T> extends StatelessWidget {
  const DurationDistanceToggle({
    super.key,
    required this.durationValue,
    required this.distanceValue,
    required this.currentValue,
    required this.onChanged,
    this.durationLabel = 'Duration',
    this.distanceLabel = 'Distance',
  });

  final T durationValue;
  final T distanceValue;
  final T currentValue;
  final ValueChanged<T> onChanged;
  final String durationLabel;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AnimatedToggleSwitch<T>.size(
        current: currentValue,
        values: [durationValue, distanceValue],
        selectedIconScale: 1.0,
        iconAnimationType: AnimationType.onHover,
        indicatorSize: const Size.fromWidth(240),
        spacing: 0,
        customIconBuilder: (context, local, global) {
          final value = local.value;
          final isActive = value == global.current;
          return Center(
            child: Text(
              value == durationValue ? durationLabel : distanceLabel,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
        style: ToggleStyle(
          backgroundColor: AppColors.secondary,
          borderRadius: BorderRadius.circular(24),
          borderColor: AppColors.secondary,
          indicatorColor: Colors.white,
          indicatorBorderRadius: BorderRadius.circular(24),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
