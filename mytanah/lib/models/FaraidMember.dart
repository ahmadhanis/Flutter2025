import 'package:flutter/material.dart';
import 'package:mytanah/models/enums.dart';

class FaraidMember {
  FaraidMember({
    required this.nameController,
    required this.countController,
    required this.relationKey,
    required this.gender,
    required this.alive,
  });

  final TextEditingController nameController;
  final TextEditingController countController;
  String relationKey;
  Gender gender;
  bool alive;

  void dispose() {
    nameController.dispose();
    countController.dispose();
  }
}
