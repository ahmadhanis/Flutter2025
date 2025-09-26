import 'package:mytanah/controllers/MembersController.dart';
import 'package:mytanah/models/ComputeResult.dart';
import 'package:mytanah/models/ResultHeirLine.dart';
import 'package:mytanah/models/enums.dart';

/// Encapsulates the faraid inheritance calculation
class FaraidEngine {
  /// Main entry point: compute shares based on the controller (UI inputs).
  static ComputeResult compute(MembersController ctrl) {
    final counts = <String, int>{};
    final blockedNotes = <String>[];

    for (final m in ctrl.members) {
      final c = int.tryParse(m.countController.text.trim()) ?? 0;
      if (!m.alive || c <= 0) continue;
      counts[m.relationKey] = (counts[m.relationKey] ?? 0) + c;
    }

    final deceasedMale = ctrl.deceasedGender.value == Gender.male;

    // Core heirs
    final suami = counts['suami'] ?? 0;
    final isteri = counts['isteri'] ?? 0;
    final bapa = counts['bapa'] ?? 0;
    final ibu = counts['ibu'] ?? 0;
    final anakL = counts['anakL'] ?? 0;
    final anakP = counts['anakP'] ?? 0;
    final cucuL = counts['cucuL'] ?? 0;
    final cucuP = counts['cucuP'] ?? 0;
    final cicitL = counts['cicitL'] ?? 0;
    final cicitP = counts['cicitP'] ?? 0;

    final hasChild = (anakL + anakP) > 0;
    final hasSon = anakL > 0;
    final hasGrandchildLine = (cucuL + cucuP) > 0;
    final hasGreatGCL = (cicitL + cicitP) > 0;

    // Hijab notes
    if (hasSon) {
      if (hasGrandchildLine) {
        blockedNotes.add(
          'Cucu (melalui anak lelaki) terhalang oleh anak lelaki.',
        );
      }
      if (hasGreatGCL) {
        blockedNotes.add(
          'Cicit (melalui cucu lelaki) terhalang oleh anak lelaki.',
        );
      }
    } else if (!hasChild && cucuL > 0) {
      if (hasGreatGCL) {
        blockedNotes.add(
          'Cicit (melalui cucu lelaki) terhalang oleh cucu lelaki.',
        );
      }
    }

    // Shares
    final furud = <String, double>{};
    final asabah = <String, double>{};

    // Spouses
    if (deceasedMale && isteri > 0) furud['isteri'] = hasChild ? 1 / 8 : 1 / 4;
    if (!deceasedMale && suami > 0) furud['suami'] = hasChild ? 1 / 4 : 1 / 2;

    // Mother
    if (ibu > 0) furud['ibu'] = hasChild ? 1 / 6 : 1 / 3;

    // Father
    if (bapa > 0 && hasChild) furud['bapa'] = 1 / 6;

    // Daughters (no sons)
    if (anakP > 0 && anakL == 0) {
      furud['anakP'] = anakP == 1 ? 1 / 2 : 2 / 3;
    }

    // Granddaughters (only if no children)
    if (!hasChild && cucuP > 0 && cucuL == 0) {
      furud['cucuP'] = cucuP == 1 ? 1 / 2 : 2 / 3;
    }

    // Great-granddaughters (only if no children & grandchildren)
    if (!hasChild && !hasGrandchildLine && cicitP > 0 && cicitL == 0) {
      furud['cicitP'] = cicitP == 1 ? 1 / 2 : 2 / 3;
    }

    // ‘Awl adjustment
    double ft = furud.values.fold(0.0, (s, v) => s + v);
    bool awl = false;
    if (ft > 1.0 + 1e-12) {
      final k = 1.0 / ft;
      awl = true;
      for (final key in furud.keys.toList()) {
        furud[key] = furud[key]! * k;
      }
      ft = 1.0;
    }

    // Residu distribution
    double residu = 1.0 - ft;
    if (residu > 1e-12) {
      if (anakL > 0) {
        final units = (2 * anakL) + anakP;
        if (units > 0) {
          asabah['anakL'] = residu * (2 * anakL) / units;
          if (anakP > 0) asabah['anakP'] = residu * anakP / units;
          residu = 0.0;
        }
      } else if (!hasChild && (cucuL > 0 || (cucuP > 0 && cucuL > 0))) {
        final units = (2 * cucuL) + cucuP;
        if (units > 0) {
          asabah['cucuL'] = residu * (2 * cucuL) / units;
          if (cucuP > 0) asabah['cucuP'] = residu * cucuP / units;
          residu = 0.0;
        }
      } else if (!hasChild &&
          !hasGrandchildLine &&
          (cicitL > 0 || (cicitP > 0 && cicitL > 0))) {
        final units = (2 * cicitL) + cicitP;
        if (units > 0) {
          asabah['cicitL'] = residu * (2 * cicitL) / units;
          if (cicitP > 0) asabah['cicitP'] = residu * cicitP / units;
          residu = 0.0;
        }
      } else if (bapa > 0) {
        asabah['bapa'] = residu;
        residu = 0.0;
      }
    }

    // Radd if residue remains
    bool radd = false;
    if (residu > 1e-12) {
      final pool = furud.keys
          .where((k) => k != 'suami' && k != 'isteri')
          .toList();
      final sum = pool.fold(0.0, (s, k) => s + (furud[k] ?? 0));
      if (sum > 1e-12) {
        for (final kx in pool) {
          furud[kx] = furud[kx]! + residu * (furud[kx]! / sum);
        }
        radd = true;
        residu = 0.0;
      }
    }

    // Combine furud & asabah
    final byKey = <String, double>{};
    for (final e in furud.entries) {
      byKey[e.key] = (byKey[e.key] ?? 0) + e.value;
    }
    for (final e in asabah.entries) {
      byKey[e.key] = (byKey[e.key] ?? 0) + e.value;
    }

    // Expand to individuals
    final lines = <ResultHeirLine>[];
    double? estate = double.tryParse(ctrl.estateController.text.trim());
    if (estate != null && estate <= 0) estate = null;

    Role roleOf(String k) {
      final f = furud[k] ?? 0.0;
      final a = asabah[k] ?? 0.0;
      if (f > 0 && a == 0) return Role.furud;
      if (f == 0 && a > 0) return Role.asabah;
      if (f > 0 && a > 0) return Role.asabah;
      return Role.none;
    }

    void addIndividuals(
      String label,
      String key,
      int count, {
      String note = '',
    }) {
      final total = byKey[key] ?? 0.0;
      if (total <= 1e-12 || count <= 0) return;
      final each = total / count;
      for (int i = 1; i <= count; i++) {
        final name = count > 1 ? '$label #$i' : label;
        lines.add(
          ResultHeirLine(
            displayName: name,
            shareFraction: each,
            role: roleOf(key),
            note: note,
            value: estate == null ? null : estate * each,
          ),
        );
      }
    }

    // Order of printing
    if (!deceasedMale) addIndividuals('Suami', 'suami', suami);
    if (deceasedMale) {
      addIndividuals('Isteri', 'isteri', isteri, note: 'Dibahagi sama rata');
    }
    addIndividuals('Ibu', 'ibu', ibu);
    addIndividuals('Bapa', 'bapa', bapa);
    addIndividuals('Anak Lelaki', 'anakL', anakL);
    addIndividuals('Anak Perempuan', 'anakP', anakP);
    addIndividuals('Cucu Lelaki (melalui anak lelaki)', 'cucuL', cucuL);
    addIndividuals('Cucu Perempuan (melalui anak lelaki)', 'cucuP', cucuP);
    addIndividuals('Cicit Lelaki (melalui cucu lelaki)', 'cicitL', cicitL);
    addIndividuals('Cicit Perempuan (melalui cucu lelaki)', 'cicitP', cicitP);

    return ComputeResult(
      lines: lines,
      blockedNotes: blockedNotes,
      awlApplied: awl,
      raddApplied: radd,
    );
  }
}
