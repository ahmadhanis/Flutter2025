import 'package:flutter/material.dart';
import 'package:mytanah/models/FaraidMember.dart';
import 'package:mytanah/models/enums.dart';

class MembersController extends ChangeNotifier {
  final estateController = TextEditingController();
  final unit = ValueNotifier<AssetUnit>(AssetUnit.rm);
  final deceasedGender = ValueNotifier<Gender>(Gender.male);

  final members = <FaraidMember>[];

  void add(FaraidMember m) {
    members.add(m);
    notifyListeners();
  }

  void removeAt(int i) {
    members[i].dispose();
    members.removeAt(i);
    notifyListeners();
  }

  void reset() {
    for (final m in members) m.dispose();
    members.clear();
    estateController.clear();
    unit.value = AssetUnit.rm;
    deceasedGender.value = Gender.male;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final m in members) m.dispose();
    estateController.dispose();
    unit.dispose();
    deceasedGender.dispose();
    super.dispose();
  }
}
