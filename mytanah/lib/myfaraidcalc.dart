import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// =========================
/// Models & Enums
/// =========================

enum Gender { male, female }

enum AssetUnit { percentOnly, rm, hektar }

enum Role { furud, asabah, radd, blocked, none }

class RelationOption {
  final String key;
  final String label;
  const RelationOption(this.key, this.label);
}

const relationOptions = <RelationOption>[
  RelationOption('suami', 'Suami'),
  RelationOption('isteri', 'Isteri'),
  RelationOption('anakL', 'Anak Lelaki'),
  RelationOption('anakP', 'Anak Perempuan'),
  RelationOption('cucuL', 'Cucu Lelaki (melalui anak lelaki)'),
  RelationOption('cucuP', 'Cucu Perempuan (melalui anak lelaki)'),
  RelationOption('bapa', 'Bapa'),
  RelationOption('ibu', 'Ibu'),
  RelationOption('datuk', 'Datuk (sebelah bapa)'),
  RelationOption('nenekIbu', 'Nenek (sebelah ibu)'),
  RelationOption('nenekBapa', 'Nenek (sebelah bapa)'),
  RelationOption('sb_seibuSebapa_L', 'Saudara Lelaki Seibu-sebapa'),
  RelationOption('ss_seibuSebapa_P', 'Saudara Perempuan Seibu-sebapa'),
  RelationOption('sb_sebapa_L', 'Saudara Lelaki Sebapa'),
  RelationOption('ss_sebapa_P', 'Saudara Perempuan Sebapa'),
  RelationOption('saudaraSeibu', 'Saudara Seibu'),
];

const femaleRelations = {
  'isteri',
  'ibu',
  'anakP',
  'cucuP',
  'nenekIbu',
  'nenekBapa',
  'ss_seibuSebapa_P',
  'ss_sebapa_P',
};
const maleRelations = {
  'suami',
  'bapa',
  'anakL',
  'cucuL',
  'datuk',
  'sb_seibuSebapa_L',
  'sb_sebapa_L',
};

class FaraidMember {
  FaraidMember({
    required this.nameController,
    required this.countController,
    required this.relationKey,
    required this.level,
    required this.gender,
    required this.alive,
  });

  final TextEditingController nameController;
  final TextEditingController countController;
  String relationKey;
  int level;
  Gender gender;
  bool alive;

  void dispose() {
    nameController.dispose();
    countController.dispose();
  }
}

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

/// =========================
/// Controller (state)
/// =========================

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

/// =========================
/// Main Screen
/// =========================

class MyFaraidCalc extends StatefulWidget {
  const MyFaraidCalc({super.key});
  @override
  State<MyFaraidCalc> createState() => _MyFaraidCalcState();
}

class _MyFaraidCalcState extends State<MyFaraidCalc> {
  late final MembersController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = MembersController();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(),
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kalkulator Faraid'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Kira',
              icon: const Icon(Icons.calculate_outlined),
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final res = _compute(ctrl);
                await _showResultPopup(context, ctrl, res);
              },
            ),
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                ctrl.reset();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Skrin direset.')));
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddWarisSheet(context, ctrl),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Tambah Waris'),
        ),
        body: AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            return LayoutBuilder(
              builder: (context, cons) {
                final isMed = cons.maxWidth >= 640;
                final isWide = cons.maxWidth >= 900;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionCard(
                            title: 'Pusaka Bersih & Si Mati',
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: isMed ? 280 : double.infinity,
                                  child: TextField(
                                    controller: ctrl.estateController,
                                    decoration: InputDecoration(
                                      labelText: switch (ctrl.unit.value) {
                                        AssetUnit.rm => 'Pusaka Bersih (RM)',
                                        AssetUnit.hektar =>
                                          'Pusaka Bersih (Hektar)',
                                        AssetUnit.percentOnly =>
                                          'Pusaka (pecahan sahaja)',
                                      },
                                      prefixText:
                                          ctrl.unit.value == AssetUnit.rm
                                          ? 'RM '
                                          : null,
                                      prefixIcon: Icon(switch (ctrl
                                          .unit
                                          .value) {
                                        AssetUnit.rm => Icons.payments_outlined,
                                        AssetUnit.hektar =>
                                          Icons.landscape_outlined,
                                        AssetUnit.percentOnly => Icons.percent,
                                      }),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                SizedBox(
                                  width: isMed ? 220 : double.infinity,
                                  child: DropdownButtonFormField<AssetUnit>(
                                    value: ctrl.unit.value,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Unit',
                                      prefixIcon: Icon(
                                        Icons.swap_horiz_rounded,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: AssetUnit.rm,
                                        child: Text('Ringgit (RM)'),
                                      ),
                                      DropdownMenuItem(
                                        value: AssetUnit.hektar,
                                        child: Text('Hektar'),
                                      ),
                                      DropdownMenuItem(
                                        value: AssetUnit.percentOnly,
                                        child: Text('Pecahan sahaja'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        ctrl.unit.value = v ?? AssetUnit.rm,
                                  ),
                                ),
                                SizedBox(
                                  width: isMed ? 220 : double.infinity,
                                  child: DropdownButtonFormField<Gender>(
                                    value: ctrl.deceasedGender.value,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Jantina Si Mati',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: Gender.male,
                                        child: Text('Lelaki'),
                                      ),
                                      DropdownMenuItem(
                                        value: Gender.female,
                                        child: Text('Perempuan'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        ctrl.deceasedGender.value =
                                            v ?? Gender.male,
                                  ),
                                ),
                                _miniChip(
                                  Icons.dataset_outlined,
                                  'Waris: ${ctrl.members.length} entri',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'Senarai Waris',
                            child: ctrl.members.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Belum ada waris. Tekan “Tambah Waris”.',
                                    ),
                                  )
                                : Column(
                                    children: List.generate(ctrl.members.length, (
                                      i,
                                    ) {
                                      final m = ctrl.members[i];
                                      final rel = relationOptions.firstWhere(
                                        (o) => o.key == m.relationKey,
                                        orElse: () => const RelationOption(
                                          'lain',
                                          'Lain-lain',
                                        ),
                                      );
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            10,
                                            8,
                                            10,
                                            10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Waris #${i + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    tooltip: 'Hapus',
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        ctrl.removeAt(i),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: [
                                                  _miniChip(
                                                    Icons.badge_outlined,
                                                    rel.label,
                                                  ),
                                                  _miniChip(
                                                    Icons.filter_2_outlined,
                                                    'Level ${m.level}',
                                                  ),
                                                  _miniChip(
                                                    Icons.wc_outlined,
                                                    m.gender == Gender.male
                                                        ? 'Lelaki'
                                                        : 'Perempuan',
                                                  ),
                                                  _miniChip(
                                                    Icons.onetwothree_outlined,
                                                    'Bil: ${m.countController.text}',
                                                  ),
                                                  _miniChip(
                                                    m.alive
                                                        ? Icons
                                                              .verified_user_outlined
                                                        : Icons.cancel_outlined,
                                                    m.alive
                                                        ? 'Hidup'
                                                        : 'Meninggal',
                                                  ),
                                                  if (m.nameController.text
                                                      .trim()
                                                      .isNotEmpty)
                                                    _miniChip(
                                                      Icons.notes,
                                                      m.nameController.text
                                                          .trim(),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// =========================
/// Add Waris Sheet (stateful)
/// =========================

Future<void> _openAddWarisSheet(
  BuildContext parentContext,
  MembersController ctrl,
) async {
  // Capture parent messenger safely
  final messenger = ScaffoldMessenger.of(parentContext);

  // Avoid focused parent fields interfering
  FocusManager.instance.primaryFocus?.unfocus();

  await showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AddWarisSheet(
      onSubmit: (member) {
        ctrl.add(member);
        // Close sheet first, then show snackbar from parent on next frame
        Navigator.of(ctx).maybePop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (parentContext.mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Waris ditambah.')),
            );
          }
        });
      },
    ),
  );
}

class _AddWarisSheet extends StatefulWidget {
  const _AddWarisSheet({required this.onSubmit});
  final void Function(FaraidMember member) onSubmit;

  @override
  State<_AddWarisSheet> createState() => _AddWarisSheetState();
}

class _AddWarisSheetState extends State<_AddWarisSheet> {
  String relKey = relationOptions.first.key;
  int level = 1;
  Gender gender = Gender.male;
  bool alive = true;
  final nameC = TextEditingController();
  final countC = TextEditingController(text: '1');

  @override
  void dispose() {
    nameC.dispose();
    countC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cons = MediaQuery.of(context).size;
    final isMed = cons.width >= 640;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1),
              const SizedBox(width: 8),
              Text(
                'Tambah Waris',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: relKey,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Waris',
                    prefixIcon: Icon(Icons.family_restroom_outlined),
                  ),
                  items: relationOptions
                      .map(
                        (o) => DropdownMenuItem(
                          value: o.key,
                          child: Text(o.label, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      relKey = v ?? relKey;
                      if (v != null && femaleRelations.contains(v)) {
                        gender = Gender.female;
                      } else if (v != null && maleRelations.contains(v)) {
                        gender = Gender.male;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: level,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    prefixIcon: Icon(Icons.filter_2_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                    DropdownMenuItem(value: 3, child: Text('3')),
                    DropdownMenuItem(value: 4, child: Text('4')),
                  ],
                  onChanged: (v) => setState(() => level = v ?? level),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Gender>(
                  value: gender,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jantina',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: Gender.male, child: Text('Lelaki')),
                    DropdownMenuItem(
                      value: Gender.female,
                      child: Text('Perempuan'),
                    ),
                  ],
                  onChanged: (v) => setState(() => gender = v ?? gender),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countC,
                  decoration: const InputDecoration(
                    labelText: 'Bilangan',
                    prefixIcon: Icon(Icons.onetwothree_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'Nama / Catatan (opsyenal)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                _InlineSwitch(
                  label: 'Masih hidup',
                  value: alive,
                  onChanged: (v) => setState(() => alive = v),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniChip(
                      Icons.badge_outlined,
                      relationOptions.firstWhere((o) => o.key == relKey).label,
                    ),
                    _miniChip(Icons.filter_2_outlined, 'Level $level'),
                    _miniChip(
                      Icons.wc_outlined,
                      gender == Gender.male ? 'Lelaki' : 'Perempuan',
                    ),
                    _miniChip(
                      Icons.onetwothree_outlined,
                      'Bil: ${countC.text}',
                    ),
                    _miniChip(
                      alive
                          ? Icons.verified_user_outlined
                          : Icons.cancel_outlined,
                      alive ? 'Hidup' : 'Meninggal',
                    ),
                    if (nameC.text.trim().isNotEmpty)
                      _miniChip(Icons.notes, nameC.text.trim()),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      nameC.clear();
                      countC.text = '1';
                      level = 1;
                      alive = true;
                      // auto-gender from relation
                      if (femaleRelations.contains(relKey)) {
                        gender = Gender.female;
                      } else if (maleRelations.contains(relKey)) {
                        gender = Gender.male;
                      }
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Borang'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final c = int.tryParse(countC.text.trim()) ?? 0;
                    if (c <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bilangan tidak sah.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    widget.onSubmit(
                      FaraidMember(
                        nameController: TextEditingController(text: nameC.text),
                        countController: TextEditingController(
                          text: c.toString(),
                        ),
                        relationKey: relKey,
                        level: level,
                        gender: gender,
                        alive: alive,
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Tambah'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// =========================
/// Result Popup + PDF
/// =========================

Future<void> _showResultPopup(
  BuildContext context,
  MembersController ctrl,
  ComputeResult res,
) async {
  final unit = ctrl.unit.value;
  final estate = double.tryParse(ctrl.estateController.text.trim());
  final hasEstate = (estate != null && estate > 0);
  final messenger = ScaffoldMessenger.of(context);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Keputusan Kiraan Faraid',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (res.awlApplied)
                    const Chip(
                      label: Text('‘Awl'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (res.raddApplied) const SizedBox(width: 6),
                  if (res.raddApplied)
                    const Chip(
                      label: Text('Radd'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _miniChip(
                    Icons.dataset_outlined,
                    'Waris: ${res.lines.length}',
                  ),
                  if (hasEstate)
                    _miniChip(
                      unit == AssetUnit.rm
                          ? Icons.payments_outlined
                          : unit == AssetUnit.hektar
                          ? Icons.landscape_outlined
                          : Icons.percent,
                      unit == AssetUnit.rm
                          ? 'Pusaka RM ${estate!.toStringAsFixed(2)}'
                          : unit == AssetUnit.hektar
                          ? 'Pusaka ${estate!.toStringAsFixed(7)} ha'
                          : 'Pecahan sahaja',
                    ),
                ],
              ),
              const Divider(height: 18),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemBuilder: (_, i) {
                    final l = res.lines[i];
                    final pct = (l.shareFraction * 100).toStringAsFixed(4);
                    final frac = _formatFraction(l.shareFraction);
                    final val = l.value;
                    final vStr = !hasEstate || val == null
                        ? null
                        : unit == AssetUnit.rm
                        ? 'RM ${val.toStringAsFixed(2)}'
                        : unit == AssetUnit.hektar
                        ? '${val.toStringAsFixed(7)} ha'
                        : val.toStringAsFixed(6);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _tag('Pecahan', frac),
                          _tag('%', pct),
                          if (vStr != null) _tag('Nilai', vStr),
                          _tag('Peranan', _roleLabel(l.role)),
                          if (l.note.isNotEmpty) _tag('Nota', l.note),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemCount: res.lines.length,
                ),
              ),
              if (res.blockedNotes.isNotEmpty) ...[
                const Divider(height: 18),
                Text(
                  'Waris Terhalang (Hijab)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                ...res.blockedNotes.map((n) => Text('• $n')),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final bytes = await _buildPdf(ctrl, res);
                        Navigator.of(ctx).maybePop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            Printing.sharePdf(
                              bytes: bytes,
                              filename: 'faraid_report.pdf',
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Kongsi PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final bytes = await _buildPdf(ctrl, res);
                        await Printing.layoutPdf(
                          onLayout: (_) async => bytes,
                          name: 'faraid_report.pdf',
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('PDF dihantar ke pencetak.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Cetak / Simpan PDF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).maybePop(),
                icon: const Icon(Icons.check),
                label: const Text('Tutup'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

pw.Widget _badge(String text) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: pw.BoxDecoration(
    color: PdfColor.fromInt(0xFFE8F5E9),
    borderRadius: pw.BorderRadius.circular(100),
    border: pw.Border.all(color: PdfColor.fromInt(0xFFB0BEC5)),
  ),
  child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
);

pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
  child: pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  ),
);

Future<Uint8List> _buildPdf(MembersController ctrl, ComputeResult res) async {
  final doc = pw.Document();
  final unit = ctrl.unit.value;
  final estate = double.tryParse(ctrl.estateController.text.trim());
  final hasEstate = estate != null && estate > 0;

  String fmtMoney(double v) => v.toStringAsFixed(2);
  String fmtLand(double v) => v.toStringAsFixed(7);
  String fmtPct(double v) => (v * 100).toStringAsFixed(4);
  String frac(double x) => _formatFraction(x);

  final header = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
      children: [
        _cell('No.', bold: true),
        _cell('Waris', bold: true),
        _cell('Pecahan (n/d)', bold: true),
        _cell('%', bold: true),
        _cell(
          hasEstate
              ? (unit == AssetUnit.rm
                    ? 'Nilai (RM)'
                    : unit == AssetUnit.hektar
                    ? 'Nilai (Hektar)'
                    : 'Nilai')
              : 'Nilai',
          bold: true,
        ),
        _cell('Peranan', bold: true),
        _cell('Nota', bold: true),
      ],
    ),
  ];

  final rows = <pw.TableRow>[];
  for (int i = 0; i < res.lines.length; i++) {
    final l = res.lines[i];
    final nilaiStr = !hasEstate || l.value == null
        ? '-'
        : unit == AssetUnit.rm
        ? 'RM ${fmtMoney(l.value!)}'
        : unit == AssetUnit.hektar
        ? fmtLand(l.value!)
        : l.value!.toStringAsFixed(6);
    rows.add(
      pw.TableRow(
        children: [
          _cell('${i + 1}'),
          _cell(l.displayName),
          _cell(frac(l.shareFraction)),
          _cell(fmtPct(l.shareFraction)),
          _cell(nilaiStr),
          _cell(_roleLabel(l.role)),
          _cell(l.note.isEmpty ? '-' : l.note),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 28),
        orientation: pw.PageOrientation.landscape,
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Halaman ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Laporan Kiraan Faraid',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Unit: ${ctrl.unit.value.name}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Row(
              children: [
                _badge('Waris: ${res.lines.length}'),
                if (hasEstate)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 6),
                    child: _badge(
                      unit == AssetUnit.rm
                          ? 'Pusaka RM ${fmtMoney(estate!)}'
                          : unit == AssetUnit.hektar
                          ? 'Pusaka ${fmtLand(estate!)} ha'
                          : 'Pecahan sahaja',
                    ),
                  ),
                if (res.awlApplied)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 6),
                    child: _badge('‘Awl'),
                  ),
                if (res.raddApplied)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 6),
                    child: _badge('Radd'),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [...header, ...rows],
        ),
      ],
    ),
  );

  return doc.save();
}

/// =========================
/// Compute (simplified engine inc. level-2)
/// =========================

ComputeResult _compute(MembersController ctrl) {
  final counts = <String, int>{};
  final blockedNotes = <String>[];

  for (final m in ctrl.members) {
    final c = int.tryParse(m.countController.text.trim()) ?? 0;
    if (!m.alive || c <= 0) continue;
    counts[m.relationKey] = (counts[m.relationKey] ?? 0) + c;
  }

  final deceasedMale = ctrl.deceasedGender.value == Gender.male;
  final suami = counts['suami'] ?? 0;
  final isteri = counts['isteri'] ?? 0;
  final anakL = counts['anakL'] ?? 0;
  final anakP = counts['anakP'] ?? 0;
  final bapa = counts['bapa'] ?? 0;
  final ibu = counts['ibu'] ?? 0;

  final fullBro = counts['sb_seibuSebapa_L'] ?? 0;
  final fullSis = counts['ss_seibuSebapa_P'] ?? 0;
  final conBro = counts['sb_sebapa_L'] ?? 0;
  final conSis = counts['ss_sebapa_P'] ?? 0;
  final uterine = counts['saudaraSeibu'] ?? 0;
  final siblingsAny = fullBro + fullSis + conBro + conSis + uterine;

  final cucuL = counts['cucuL'] ?? 0;
  final cucuP = counts['cucuP'] ?? 0;
  final datuk = counts['datuk'] ?? 0;
  final nenekIbu = counts['nenekIbu'] ?? 0;
  final nenekBapa = counts['nenekBapa'] ?? 0;

  final hasSon = anakL > 0;
  final hasChild = (anakL + anakP) > 0;
  final hasDescendantLine = hasChild || (cucuL + cucuP) > 0;

  if (hasSon) {
    if (cucuL + cucuP > 0)
      blockedNotes.add(
        'Cucu (melalui anak lelaki) terhalang oleh anak lelaki.',
      );
    if (fullBro + fullSis + conBro + conSis + uterine > 0) {
      blockedNotes.add('Saudara/saudari terhalang oleh anak lelaki.');
    }
  }
  if (bapa > 0 && datuk > 0) blockedNotes.add('Datuk terhalang oleh bapa.');
  if (hasChild || bapa > 0) {
    if (uterine > 0)
      blockedNotes.add('Saudara seibu terhalang oleh anak/bapa.');
  }
  if (ibu > 0 && (nenekIbu + nenekBapa) > 0)
    blockedNotes.add('Nenek terhalang oleh ibu.');

  final furud = <String, double>{};
  final asabah = <String, double>{};

  if (deceasedMale && isteri > 0) furud['isteri'] = hasChild ? 1 / 8 : 1 / 4;
  if (!deceasedMale && suami > 0) furud['suami'] = hasChild ? 1 / 4 : 1 / 2;

  if (ibu > 0) furud['ibu'] = (hasChild || siblingsAny >= 2) ? 1 / 6 : 1 / 3;

  if (bapa > 0) {
    if (hasChild) furud['bapa'] = 1 / 6;
  }

  if (anakP > 0 && anakL == 0) furud['anakP'] = anakP == 1 ? 1 / 2 : 2 / 3;

  if (!hasChild) {
    if (cucuP > 0 && cucuL == 0) {
      furud['cucuP'] = cucuP == 1 ? 1 / 2 : 2 / 3;
    }
  }

  if (ibu == 0) {
    if (nenekIbu > 0) furud['nenekIbu'] = 1 / 6;
    if (nenekBapa > 0) furud['nenekBapa'] = 1 / 6;
  }

  if (bapa == 0 && datuk > 0) {
    if (hasDescendantLine) {
      furud['datuk'] = 1 / 6;
    }
  }

  double ft = furud.values.fold(0.0, (s, v) => s + v);
  bool awl = false;
  if (ft > 1.0 + 1e-12) {
    final k = 1.0 / ft;
    awl = true;
    for (final kx in furud.keys.toList()) {
      furud[kx] = furud[kx]! * k;
    }
    ft = 1.0;
  }

  double residu = 1.0 - ft;

  if (residu > 1e-12) {
    if (anakL > 0) {
      final units = (2 * anakL) + anakP;
      if (units > 0) {
        asabah['anakL'] = residu * (2 * anakL) / units;
        if (anakP > 0) asabah['anakP'] = residu * (anakP) / units;
        residu = 0.0;
      }
    } else if (!hasChild && (cucuL > 0 || (cucuP > 0 && cucuL > 0))) {
      final units = (2 * cucuL) + cucuP;
      if (units > 0) {
        asabah['cucuL'] = residu * (2 * cucuL) / units;
        if (cucuP > 0) asabah['cucuP'] = residu * (cucuP) / units;
        residu = 0.0;
      }
    } else if (bapa > 0) {
      asabah['bapa'] = residu;
      residu = 0.0;
    } else if (datuk > 0) {
      asabah['datuk'] = residu;
      residu = 0.0;
    }
  }

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

  final byKey = <String, double>{};
  for (final e in furud.entries) {
    byKey[e.key] = (byKey[e.key] ?? 0) + e.value;
  }
  for (final e in asabah.entries) {
    byKey[e.key] = (byKey[e.key] ?? 0) + e.value;
  }

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

  void addIndividuals(String label, String key, int count, {String note = ''}) {
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

  if (!deceasedMale) addIndividuals('Suami', 'suami', suami);
  if (deceasedMale)
    addIndividuals('Isteri', 'isteri', isteri, note: 'Dibahagi sama rata');
  addIndividuals('Ibu', 'ibu', ibu);
  addIndividuals('Bapa', 'bapa', bapa);
  addIndividuals('Anak Lelaki', 'anakL', anakL);
  addIndividuals('Anak Perempuan', 'anakP', anakP);
  addIndividuals('Cucu Lelaki (melalui anak lelaki)', 'cucuL', cucuL);
  addIndividuals('Cucu Perempuan (melalui anak lelaki)', 'cucuP', cucuP);
  addIndividuals('Datuk (sebelah bapa)', 'datuk', datuk);
  addIndividuals('Nenek (sebelah ibu)', 'nenekIbu', nenekIbu);
  addIndividuals('Nenek (sebelah bapa)', 'nenekBapa', nenekBapa);

  return ComputeResult(
    lines: lines,
    blockedNotes: blockedNotes,
    awlApplied: awl,
    raddApplied: radd,
  );
}

/// =========================
/// UI bits
/// =========================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.topic_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _miniChip(IconData icon, String label) {
  return Builder(
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Chip(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        visualDensity: VisualDensity.compact,
        avatar: Icon(icon, size: 14, color: cs.onSecondaryContainer),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: cs.secondaryContainer,
        side: BorderSide(color: cs.outlineVariant),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    },
  );
}

class _InlineSwitch extends StatelessWidget {
  const _InlineSwitch({
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

/// =========================
/// Utilities
/// =========================

String _roleLabel(Role r) {
  switch (r) {
    case Role.furud:
      return 'Furud';
    case Role.asabah:
      return 'Asabah';
    case Role.radd:
      return 'Radd';
    case Role.blocked:
      return 'Terhalang';
    case Role.none:
      return '-';
  }
}

Widget _tag(String k, String v) {
  return Builder(
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text('$k: $v', style: Theme.of(context).textTheme.labelSmall),
      );
    },
  );
}

String _formatFraction(double x, {int maxDen = 48}) {
  int bestN = 0, bestD = 1;
  double bestErr = 1e9;
  for (int d = 1; d <= maxDen; d++) {
    final n = (x * d).round();
    final err = (x - n / d).abs();
    if (err < bestErr) {
      bestErr = err;
      bestN = n;
      bestD = d;
    }
  }
  int g = _gcd(bestN.abs(), bestD.abs());
  bestN ~/= g;
  bestD ~/= g;
  return '$bestN/$bestD';
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
