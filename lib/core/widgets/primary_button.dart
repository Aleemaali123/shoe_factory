import 'package:flutter/material.dart';

import '../motion/motion.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final spinner = const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
    return Pressable(
      enabled: !busy && onPressed != null,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: icon == null || busy
            ? ElevatedButton(
                onPressed: busy ? null : onPressed,
                child: busy ? spinner : Text(label))
            : ElevatedButton.icon(
                onPressed: onPressed, icon: Icon(icon), label: Text(label)),
      ),
    );
  }
}
