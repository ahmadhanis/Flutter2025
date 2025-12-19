import 'package:flutter/material.dart';

class Division {
  TextEditingController numeratorController;
  TextEditingController denominatorController;

  Division({String numerator = '', String denominator = ''})
    : numeratorController = TextEditingController(text: numerator),
      denominatorController = TextEditingController(text: denominator);

  double get fraction {
    double num = double.tryParse(numeratorController.text) ?? 0;
    double denom = double.tryParse(denominatorController.text) ?? 1;
    if (denom == 0) return 0;
    return num / denom;
  }

  // Factory to reconstruct from DB map
  factory Division.fromDatabase(Map<String, dynamic> map) {
    return Division(
      numerator: map['pembilang'].toString(),
      denominator: map['penyebut'].toString(),
    );
  }
}
