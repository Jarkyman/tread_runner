import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ValueWheelPicker extends StatefulWidget {
  const ValueWheelPicker({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    this.height = 150,
    this.itemExtent = 36,
    this.labelBuilder,
  });

  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;
  final double height;
  final double itemExtent;
  final String Function(double value)? labelBuilder;

  @override
  State<ValueWheelPicker> createState() => _ValueWheelPickerState();
}

class _ValueWheelPickerState extends State<ValueWheelPicker> {
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
  void didUpdateWidget(covariant ValueWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _indexFromValue(widget.value);
    if (nextIndex != _currentIndex) {
      _currentIndex = nextIndex;
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
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: widget.height * 0.4,
            child: Container(height: 1, color: AppColors.primary.withAlpha(80)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: widget.height * 0.6,
            child: Container(height: 1, color: AppColors.primary.withAlpha(80)),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemExtent,
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
                    widget.labelBuilder?.call(value) ??
                        value.toStringAsFixed(widget.step >= 1 ? 0 : 1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontSize: isSelected ? 28 : 18,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
