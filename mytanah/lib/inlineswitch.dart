import 'package:flutter/material.dart';

class InlineSwitch extends StatelessWidget {
  const InlineSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.heart_broken, size: 18),
          const SizedBox(width: 6),
          Text(label),
          const SizedBox(width: 6),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
