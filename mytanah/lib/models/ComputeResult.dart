// ignore:
// ignore_for_file: file_names

import 'package:mytanah/models/ResultHeirLine.dart';

class ComputeResult {
  ComputeResult({
    required this.lines,
    required this.blockedNotes,
    required this.awlApplied,
    required this.raddApplied,
  });
  final List<ResultHeirLine> lines;
  final List<String> blockedNotes;
  final bool awlApplied;
  final bool raddApplied;
}
