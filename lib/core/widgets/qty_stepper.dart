import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QtyStepper extends StatelessWidget {
  const QtyStepper(
      {super.key,
      required this.value,
      required this.onChanged,
      this.min = 1,
      this.max = 5});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.remove, value > min, () => onChanged(value - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        _button(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _button(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.paleGreen : const Color(0xFFF7F8F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 16, color: enabled ? AppColors.ink : AppColors.line),
      ),
    );
  }
}
