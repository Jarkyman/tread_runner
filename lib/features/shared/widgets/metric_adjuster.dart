import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'app_card.dart';
import 'rounded_icon_button.dart';

enum MetricAdjusterStyle { card, inline }

class MetricAdjuster extends StatelessWidget {
  const MetricAdjuster({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.style = MetricAdjusterStyle.card,
    this.decimals,
    this.valueFormatter,
  });

  final String title;
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final bool enabled;
  final MetricAdjusterStyle style;
  final int? decimals;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (style == MetricAdjusterStyle.inline) {
      return _InlineLayout(
        title: title,
        valueLabel: _valueLabel(),
        enabled: enabled,
        onDecrement: () => _handleChange(-step),
        onIncrement: () => _handleChange(step),
      );
    }
    return AppCard(
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
              RoundedIconButton(
                icon: Icons.remove,
                onPressed: enabled ? () => _handleChange(-step) : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _valueLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              RoundedIconButton(
                icon: Icons.add,
                onPressed: enabled ? () => _handleChange(step) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _valueLabel() =>
      valueFormatter?.call(value) ??
      '${value.toStringAsFixed(decimals ?? (step >= 1 ? 0 : 1))} $unit';

  void _handleChange(double delta) {
    if (!enabled) return;
    final newValue = (value + delta).clamp(min, max);
    final precision = decimals ?? (step >= 1 ? 0 : 1);
    final normalized = double.parse(newValue.toStringAsFixed(precision));
    onChanged(normalized);
  }
}

class _InlineLayout extends StatelessWidget {
  const _InlineLayout({
    required this.title,
    required this.valueLabel,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String title;
  final String valueLabel;
  final bool enabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
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
                const SizedBox(height: 6),
                Text(
                  valueLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              RoundedIconButton(
                icon: Icons.remove,
                size: 44,
                onPressed: enabled ? onDecrement : null,
              ),
              const SizedBox(width: 12),
              RoundedIconButton(
                icon: Icons.add,
                size: 44,
                onPressed: enabled ? onIncrement : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
