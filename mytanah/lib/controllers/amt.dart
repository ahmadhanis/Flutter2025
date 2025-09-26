import 'package:flutter/material.dart';

class Amt {
  Amt(this.label) : c = TextEditingController();
  final String label;
  final TextEditingController c;
  double get v => double.tryParse(c.text.trim()) ?? 0.0;
  void dispose() => c.dispose();
}
