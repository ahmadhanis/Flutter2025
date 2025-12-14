// ignore_for_file: file_names

import 'package:mytanah/models/enums.dart';

class ResultHeirLine {
  ResultHeirLine({
    required this.displayName,
    required this.shareFraction,
    required this.role,
    required this.note,
    this.value,
  });
  final String displayName;
  final double shareFraction;
  final Role role;
  final String note;
  final double? value;
}
