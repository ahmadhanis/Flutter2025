import 'package:flutter/material.dart';

class Division {
  TextEditingController numeratorController;
  TextEditingController denominatorController;

  Division({String numerator = '', String denominator = ''})
      : numeratorController = TextEditingController(text: numerator),
        denominatorController = TextEditingController(text: denominator);

  // Compute the fraction value; if denominator is 0 or invalid, returns 0.
  double get fraction {
    double num = double.tryParse(numeratorController.text) ?? 0;
    double denom = double.tryParse(denominatorController.text) ?? 1;
    if (denom == 0) return 0;
    return num / denom;
  }
}