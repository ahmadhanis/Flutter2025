import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class MyFaraidCalc extends StatefulWidget {
  const MyFaraidCalc({super.key});

  @override
  State<MyFaraidCalc> createState() => _MyFaraidCalcState();
}

class _MyFaraidCalcState extends State<MyFaraidCalc> {
  // Pusaka Bersih
  final TextEditingController _estateController = TextEditingController();
  AssetUnit _unit = AssetUnit.rm;

  // Si mati
  Gender _deceasedGender = Gender.male;

  // Dynamic members list
  final List<FaraidMember> _members = [];

  // For new member row (add form)
  final _newName = TextEditingController();
  final _newCount = TextEditingController(text: '1');
  String _newRelationKey = relationOptions.first.key;
  int _newLevel = 1;
  Gender _newGender = Gender.male;
  bool _newAlive = true;

  @override
  void dispose() {
    _estateController.dispose();
    _newName.dispose();
    _newCount.dispose();
    for (final m in _members) {
      m.nameController.dispose();
      m.countController.dispose();
    }
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _estateController.clear();
      _unit = AssetUnit.rm;
      _deceasedGender = Gender.male;
      _members.clear();
      _newName.clear();
      _newCount.text = '1';
      _newRelationKey = relationOptions.first.key;
      _newLevel = 1;
      _newGender = Gender.male;
      _newAlive = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skrin faraid direset.'),
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  void _addMember() {
    final count = int.tryParse(_newCount.text.trim());
    if (count == null || count < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bilangan tidak sah.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _members.add(
        FaraidMember(
          nameController: TextEditingController(text: _newName.text.trim()),
          countController: TextEditingController(text: count.toString()),
          relationKey: _newRelationKey,
          level: _newLevel,
          gender: _newGender,
          alive: _newAlive,
        ),
      );
      _newName.clear();
      _newCount.text = '1';
    });
  }

  void _removeMember(int index) {
    setState(() {
      _members[index].nameController.dispose();
      _members[index].countController.dispose();
      _members.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        filled: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      chipTheme: const ChipThemeData(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelPadding: EdgeInsets.symmetric(horizontal: 6),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        horizontalTitleGap: 8,
        minLeadingWidth: 20,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kalkulator Faraid (UI Flow)'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Reset',
              onPressed: _resetAll,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Kira Faraid',
              icon: const Icon(Icons.calculate_outlined),
              onPressed: _computeAndShowPopup,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addMember,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Tambah Waris'),
        ),
        body: LayoutBuilder(
          builder: (context, cons) {
            final isWide = cons.maxWidth >= 900;
            final isMed = cons.maxWidth >= 640;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== SECTION: Pusaka & Si Mati =====
                      _SectionCard(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        title: 'Pusaka Bersih & Si Mati',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            // Pusaka Bersih
                            SizedBox(
                              width: isMed ? 280 : double.infinity,
                              child: TextField(
                                controller: _estateController,
                                decoration: InputDecoration(
                                  labelText: _unit == AssetUnit.rm
                                      ? 'Pusaka Bersih (RM)'
                                      : _unit == AssetUnit.hektar
                                      ? 'Pusaka Bersih (Hektar)'
                                      : 'Pusaka (pecahan sahaja)',
                                  prefixText: _unit == AssetUnit.rm
                                      ? 'RM '
                                      : null,
                                  hintText: _unit == AssetUnit.rm
                                      ? 'cth: 250000.00'
                                      : _unit == AssetUnit.hektar
                                      ? 'cth: 1.75'
                                      : 'Isikan jika mahu (opsyenal)',
                                  prefixIcon: Icon(
                                    _unit == AssetUnit.rm
                                        ? Icons.payments_outlined
                                        : _unit == AssetUnit.hektar
                                        ? Icons.landscape_outlined
                                        : Icons.percent,
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            // Unit
                            SizedBox(
                              width: isMed ? 220 : double.infinity,
                              child: DropdownButtonFormField<AssetUnit>(
                                value: _unit,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  prefixIcon: Icon(Icons.swap_horiz_rounded),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: AssetUnit.rm,
                                    child: Text('Ringgit (RM)'),
                                  ),
                                  DropdownMenuItem(
                                    value: AssetUnit.hektar,
                                    child: Text('Hektar (tanah)'),
                                  ),
                                  DropdownMenuItem(
                                    value: AssetUnit.percentOnly,
                                    child: Text('Pecahan sahaja'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _unit = v ?? AssetUnit.rm),
                              ),
                            ),
                            // Jantina si mati
                            SizedBox(
                              width: isMed ? 220 : double.infinity,
                              child: DropdownButtonFormField<Gender>(
                                value: _deceasedGender,
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
                                onChanged: (v) => setState(
                                  () => _deceasedGender = v ?? Gender.male,
                                ),
                              ),
                            ),
                            // Summary chips
                            _MiniChipsWrap(
                              children: [
                                _miniChip(
                                  Icons.dataset_outlined,
                                  'Waris: ${_members.length} entri',
                                ),
                                _miniChip(
                                  Icons.group_outlined,
                                  'Bil. Individu: ${_members.fold<int>(0, (s, m) => s + (int.tryParse(m.countController.text) ?? 0))}',
                                ),
                                _miniChip(
                                  Icons.person_outline,
                                  'Si Mati: ${_deceasedGender == Gender.male ? 'Lelaki' : 'Perempuan'}',
                                ),
                                _miniChip(
                                  _unit == AssetUnit.rm
                                      ? Icons.payments_outlined
                                      : _unit == AssetUnit.hektar
                                      ? Icons.landscape_outlined
                                      : Icons.percent,
                                  'Unit: ${_unit.name}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ===== SECTION: Add Member (inline form) =====
                      _SectionCard(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        title: 'Tambah Waris',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: _openAddWarisSheet,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Tambah Waris'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ===== SECTION: Members List =====
                      _SectionCard(
                        color: Colors.white,
                        title: 'Senarai Waris',
                        child: _members.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Belum ada waris. Tambah menggunakan borang di atas.',
                                ),
                              )
                            : Column(
                                children: List.generate(_members.length, (i) {
                                  final m = _members[i];
                                  final rel = relationOptions.firstWhere(
                                    (o) => o.key == m.relationKey,
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
                                      borderRadius: BorderRadius.circular(12),
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
                                                  fontWeight: FontWeight.w600,
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
                                                    _removeMember(i),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: [
                                              // Relation
                                              // Relation (Jenis Waris) — overflow-safe
                                              SizedBox(
                                                width: isMed
                                                    ? 220
                                                    : double.infinity,
                                                child: DropdownButtonFormField<String>(
                                                  value: m.relationKey,
                                                  isExpanded:
                                                      true, // <-- penting
                                                  menuMaxHeight: 420,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Jenis Waris',
                                                    prefixIcon: Icon(
                                                      Icons
                                                          .family_restroom_outlined,
                                                    ),
                                                  ),
                                                  // Pastikan TEKS TERPILIH dalam field tidak overflow
                                                  selectedItemBuilder:
                                                      (
                                                        context,
                                                      ) => relationOptions.map((
                                                        o,
                                                      ) {
                                                        return Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Text(
                                                            o.label,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        );
                                                      }).toList(),
                                                  // Item dalam popup menu — elakkan overflow juga
                                                  items: relationOptions.map((
                                                    o,
                                                  ) {
                                                    return DropdownMenuItem(
                                                      value: o.key,
                                                      child: Text(
                                                        o.label,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        // style: const TextStyle(fontSize: 13), // <-- uncomment jika perlu lebih padat
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (v) => setState(
                                                    () => m.relationKey =
                                                        v ?? m.relationKey,
                                                  ),
                                                ),
                                              ),

                                              // Level
                                              SizedBox(
                                                width: isMed
                                                    ? 120
                                                    : double.infinity,
                                                child: DropdownButtonFormField<int>(
                                                  value: m.level,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Level',
                                                        prefixIcon: Icon(
                                                          Icons
                                                              .filter_2_outlined,
                                                        ),
                                                      ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 1,
                                                      child: Text('1'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 2,
                                                      child: Text('2'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 3,
                                                      child: Text('3'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 4,
                                                      child: Text('4'),
                                                    ),
                                                  ],
                                                  onChanged: (v) => setState(
                                                    () =>
                                                        m.level = v ?? m.level,
                                                  ),
                                                ),
                                              ),
                                              // Gender
                                              SizedBox(
                                                width: isMed
                                                    ? 160
                                                    : double.infinity,
                                                child:
                                                    DropdownButtonFormField<
                                                      Gender
                                                    >(
                                                      value: m.gender,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Jantina',
                                                            prefixIcon: Icon(
                                                              Icons.wc_outlined,
                                                            ),
                                                          ),
                                                      items: const [
                                                        DropdownMenuItem(
                                                          value: Gender.male,
                                                          child: Text('Lelaki'),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: Gender.female,
                                                          child: Text(
                                                            'Perempuan',
                                                          ),
                                                        ),
                                                      ],
                                                      onChanged: (v) =>
                                                          setState(
                                                            () => m.gender =
                                                                v ?? m.gender,
                                                          ),
                                                    ),
                                              ),
                                              // Count
                                              SizedBox(
                                                width: isMed
                                                    ? 120
                                                    : double.infinity,
                                                child: TextField(
                                                  controller: m.countController,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Bilangan',
                                                    prefixIcon: Icon(
                                                      Icons
                                                          .onetwothree_outlined,
                                                    ),
                                                  ),
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(),
                                                ),
                                              ),
                                              // Name/note
                                              SizedBox(
                                                width: isWide
                                                    ? 280
                                                    : double.infinity,
                                                child: TextField(
                                                  controller: m.nameController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Nama / Catatan',
                                                        prefixIcon: Icon(
                                                          Icons
                                                              .note_alt_outlined,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              // Alive
                                              _InlineSwitch(
                                                label: 'Masih hidup',
                                                value: m.alive,
                                                onChanged: (v) =>
                                                    setState(() => m.alive = v),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Quick compact chips summary for each member
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
                                                m.alive ? 'Hidup' : 'Meninggal',
                                              ),
                                              if (m.nameController.text
                                                  .trim()
                                                  .isNotEmpty)
                                                _miniChip(
                                                  Icons.notes,
                                                  m.nameController.text.trim(),
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
        ),
      ),
    );
  }

  Future<void> _computeAndShowPopup() async {
    final res = _computeFaraidFromUi();
    if (res.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiada waris sah untuk dikira.')),
      );
      return;
    }

    final currency = _unit == AssetUnit.rm;
    final land = _unit == AssetUnit.hektar;
    final estateValue = double.tryParse(_estateController.text.trim());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
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
                        Chip(
                          label: const Text('‘Awl'),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (res.raddApplied) const SizedBox(width: 6),
                      if (res.raddApplied)
                        Chip(
                          label: const Text('Radd'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text('Waris: ${res.lines.length}'),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (estateValue != null && estateValue > 0)
                        Chip(
                          label: Text(
                            'Pusaka Bersih: ${currency
                                ? "RM "
                                : land
                                ? ""
                                : ""}'
                            '${estateValue.toStringAsFixed(currency ? 2 : 4)}'
                            '${land ? " hektar" : ""}',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const Divider(height: 18),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: res.lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (_, i) {
                        final l = res.lines[i];
                        final pct = (l.shareFraction * 100).toStringAsFixed(4);
                        final frac = _formatFraction(l.shareFraction);
                        final valueStr =
                            (estateValue != null &&
                                estateValue > 0 &&
                                l.value != null)
                            ? (currency
                                  ? 'RM ${l.value!.toStringAsFixed(2)}'
                                  : land
                                  ? '${l.value!.toStringAsFixed(7)} hektar'
                                  : l.value!.toStringAsFixed(6))
                            : null;

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
                              if (valueStr != null) _tag('Nilai', valueStr),
                              _tag('Peranan', _roleLabel(l.role)),
                              if (l.note.isNotEmpty) _tag('Nota', l.note),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (res.blockedHeirsNotes.isNotEmpty) ...[
                    const Divider(height: 18),
                    Text(
                      'Waris Terhalang (Hijab)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    ...res.blockedHeirsNotes.map((n) => Text('• $n')),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareFaraidPdf(res),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Kongsi PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _printFaraidPdf(res),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Cetak / Simpan PDF'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.check),
                    label: const Text('Tutup'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _printFaraidPdf(_Result res) async {
    final bytes = await _buildFaraidPdfBytes(res);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'faraid_report.pdf',
    );
  }

  Future<void> _shareFaraidPdf(_Result res) async {
    final bytes = await _buildFaraidPdfBytes(res);
    await Printing.sharePdf(bytes: bytes, filename: 'faraid_report.pdf');
  }

  Future<Uint8List> _buildFaraidPdfBytes(_Result res) async {
    final doc = pw.Document();

    final currency = _unit == AssetUnit.rm;
    final land = _unit == AssetUnit.hektar;
    final estateValue = double.tryParse(_estateController.text.trim());
    final hasEstate = estateValue != null && estateValue > 0;

    String fmtMoney(double v) => v.toStringAsFixed(2);
    String fmtLand(double v) => v.toStringAsFixed(7);
    String fmtPct(double v) => (v * 100).toStringAsFixed(4);
    String frac(double x, {int maxDen = 48}) =>
        _formatFraction(x, maxDen: maxDen);

    // Build header row
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
        children: [
          _pdfCell('No.', bold: true),
          _pdfCell('Waris', bold: true),
          _pdfCell('Pecahan (n/d)', bold: true),
          _pdfCell('%', bold: true),
          _pdfCell(
            hasEstate
                ? (currency
                      ? 'Nilai (RM)'
                      : land
                      ? 'Nilai (Hektar)'
                      : 'Nilai')
                : 'Nilai',
            bold: true,
          ),
          _pdfCell('Peranan', bold: true),
          _pdfCell('Nota', bold: true),
        ],
      ),
    ];

    // Body
    for (int i = 0; i < res.lines.length; i++) {
      final l = res.lines[i];
      final nilaiStr = !hasEstate || l.value == null
          ? '-'
          : currency
          ? 'RM ${fmtMoney(l.value!)}'
          : land
          ? fmtLand(l.value!)
          : l.value!.toStringAsFixed(6);

      rows.add(
        pw.TableRow(
          children: [
            _pdfCell('${i + 1}'),
            _pdfCell(l.displayName),
            _pdfCell(frac(l.shareFraction)),
            _pdfCell(fmtPct(l.shareFraction)),
            _pdfCell(nilaiStr),
            _pdfCell(_roleLabel(l.role)),
            _pdfCell(l.note.isEmpty ? '-' : l.note),
          ],
        ),
      );
    }

    // Summary badge line
    final summaryChips = <pw.Widget>[_badge('Waris: ${res.lines.length}')];
    if (hasEstate) {
      final estateText = currency
          ? 'Pusaka Bersih: RM ${fmtMoney(estateValue!)}'
          : land
          ? 'Pusaka Bersih: ${fmtLand(estateValue!)} hektar'
          : 'Pusaka Bersih: ${estateValue!.toStringAsFixed(6)}';
      summaryChips.add(_badge(estateText));
    }
    if (res.awlApplied) summaryChips.add(_badge('‘Awl'));
    if (res.raddApplied) summaryChips.add(_badge('Radd'));

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
                    'Si Mati: ${_deceasedGender == Gender.male ? 'Lelaki' : 'Perempuan'}   '
                    '|   Unit: ${_unit.name}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                children: summaryChips
                    .map(
                      (w) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 6),
                        child: w,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ],
      ),
    );

    return doc.save();
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

  pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  // Quick fraction formatter for display only
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
      default:
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

  _Result _computeFaraidFromUi() {
    // 1) Collate counts (alive only)
    final counts = <String, int>{};
    final blockedNotes = <String>[];
    for (final m in _members) {
      final c = int.tryParse(m.countController.text.trim()) ?? 0;
      if (!m.alive || c <= 0) continue;
      counts[m.relationKey] = (counts[m.relationKey] ?? 0) + c;
    }

    final deceasedMale = _deceasedGender == Gender.male;
    final deceasedFemale = _deceasedGender == Gender.female;

    // Common keys
    final suami = counts['suami'] ?? 0;
    final isteri = counts['isteri'] ?? 0;
    final anakL = counts['anakL'] ?? 0;
    final anakP = counts['anakP'] ?? 0;
    final bapa = counts['bapa'] ?? 0;
    final ibu = counts['ibu'] ?? 0;

    // Siblings (for ibu rule)
    final fullBro = counts['sb_seibuSebapa_L'] ?? 0;
    final fullSis = counts['ss_seibuSebapa_P'] ?? 0;
    final conBro = counts['sb_sebapa_L'] ?? 0;
    final conSis = counts['ss_sebapa_P'] ?? 0;
    final uterine = counts['saudaraSeibu'] ?? 0;
    final siblingsAny = fullBro + fullSis + conBro + conSis + uterine;

    // Level-2
    final cucuL = counts['cucuL'] ?? 0; // cucu lelaki melalui anak lelaki
    final cucuP = counts['cucuP'] ?? 0; // cucu perempuan melalui anak lelaki
    final datuk = counts['datuk'] ?? 0; // datuk sebelah bapa
    final nenekBapa = counts['nenekBapa'] ?? 0; // nenek sebelah bapa
    final nenekIbu = counts['nenekIbu'] ?? 0; // nenek sebelah ibu

    final hasSon = anakL > 0;
    final hasChild = (anakL + anakP) > 0;
    final hasDescendants =
        hasChild || (cucuL + cucuP) > 0; // keturunan lelaki line

    // 2) Hijab (notes only; blocking is implicit via not assigning shares)
    if (hasSon) {
      if (cucuL + cucuP > 0) {
        blockedNotes.add(
          'Cucu (melalui anak lelaki) terhalang oleh anak lelaki.',
        );
      }
      if (fullBro + fullSis + conBro + conSis + uterine > 0) {
        blockedNotes.add('Saudara/saudari terhalang oleh anak lelaki.');
      }
    }
    if (bapa > 0 && datuk > 0) {
      blockedNotes.add('Datuk (sebelah bapa) terhalang oleh bapa.');
    }
    if (hasChild || bapa > 0) {
      if (uterine > 0)
        blockedNotes.add('Saudara seibu terhalang oleh anak/bapa.');
    }
    if (ibu > 0 && (nenekBapa + nenekIbu) > 0) {
      blockedNotes.add('Nenek terhalang oleh ibu.');
    }

    // 3) Shares (group totals) — furud & asabah
    final furud = <String, double>{};
    final asabah = <String, double>{};

    // Spouse
    if (deceasedMale && isteri > 0) {
      furud['isteri'] = hasChild ? (1 / 8) : (1 / 4); // split equally later
    }
    if (deceasedFemale && suami > 0) {
      furud['suami'] = hasChild ? (1 / 4) : (1 / 2);
    }

    // Ibu (1/3; turun 1/6 jika ada anak / >=2 saudara)
    if (ibu > 0) {
      final ibuShare = (hasChild || siblingsAny >= 2) ? (1 / 6) : (1 / 3);
      furud['ibu'] = ibuShare;
    }

    // Bapa
    if (bapa > 0) {
      if (hasChild) {
        furud['bapa'] = 1 / 6; // may also take residu later
      } else {
        // no fixed share; bapa berpotensi asabah nanti
      }
    }

    // Anak perempuan (tiada anak lelaki)
    if (anakP > 0 && anakL == 0) {
      furud['anakP'] = (anakP == 1) ? (1 / 2) : (2 / 3);
    }

    // --- Level-2 Furud (bila layak) ---

    // Cucu perempuan (melalui anak lelaki) — hanya jika TIADA anak (lelaki/perempuan)
    if (anakL + anakP == 0) {
      if (cucuP > 0 && cucuL == 0) {
        // share seperti anak perempuan
        furud['cucuP'] = (cucuP == 1) ? (1 / 2) : (2 / 3);
      }
      // (Nota lanjutan “tamam 2/3” tidak dimasukkan di patch ringkas ini)
    }

    // Nenek — hanya jika ibu tiada
    if (ibu == 0) {
      if (nenekIbu > 0) furud['nenekIbu'] = 1 / 6;
      if (nenekBapa > 0)
        furud['nenekBapa'] =
            1 / 6; // ringkas; perincian hijab nenek boleh ditambah
    }

    // Datuk (sebelah bapa) — hanya jika bapa tiada
    if (bapa == 0 && datuk > 0) {
      if (hasDescendants) {
        // Ada keturunan lelaki-line → datuk dapat 1/6 (dan mungkin residu)
        furud['datuk'] = 1 / 6;
      } else {
        // Tanpa keturunan → datuk akan jadi asabah (residu) nanti
      }
    }

    // 4) ‘Awl jika perlu
    double furudTotal = furud.values.fold(0.0, (s, v) => s + v);
    bool awlApplied = false;
    if (furudTotal > 1.0 + 1e-12) {
      final k = 1.0 / furudTotal;
      awlApplied = true;
      for (final kx in furud.keys.toList()) {
        furud[kx] = furud[kx]! * k;
      }
      furudTotal = 1.0;
    }

    // 5) Residu → Asabah (tertib)
    double residu = 1.0 - furudTotal;

    if (residu > 1e-12) {
      // a) Anak lelaki (± anak perempuan) 2:1
      if (anakL > 0) {
        final units = (2 * anakL) + anakP;
        if (units > 0) {
          final anakLShare = residu * (2 * anakL) / units;
          final anakPShare = residu * (anakP) / units;
          if (anakLShare > 0)
            asabah['anakL'] = (asabah['anakL'] ?? 0) + anakLShare;
          if (anakPShare > 0)
            asabah['anakP'] = (asabah['anakP'] ?? 0) + anakPShare;
          residu = 0.0;
        }
      }
      // b) Jika TIADA anak → cucu melalui anak lelaki 2:1
      else if ((anakL + anakP) == 0 &&
          (cucuL > 0 || (cucuP > 0 && cucuL > 0))) {
        final units = (2 * cucuL) + cucuP;
        if (units > 0) {
          final cucuLShare = residu * (2 * cucuL) / units;
          final cucuPShare = residu * (cucuP) / units;
          if (cucuLShare > 0)
            asabah['cucuL'] = (asabah['cucuL'] ?? 0) + cucuLShare;
          if (cucuPShare > 0)
            asabah['cucuP'] = (asabah['cucuP'] ?? 0) + cucuPShare;
          residu = 0.0;
        }
      }
      // c) Bapa ambil residu jika ada
      else if (bapa > 0) {
        asabah['bapa'] = (asabah['bapa'] ?? 0) + residu;
        residu = 0.0;
      }
      // d) Datuk (jika bapa tiada)
      else if (datuk > 0) {
        asabah['datuk'] = (asabah['datuk'] ?? 0) + residu;
        residu = 0.0;
      }
      // (Lapisan seterusnya — saudara lelaki, dsb. — boleh ditambah kemudian)
    }

    // 6) Radd jika masih ada residu & tiada asabah ambil
    bool raddApplied = false;
    if (residu > 1e-12) {
      // Pool radd: ashabul furud kecuali pasangan (kebiasaan tempatan)
      final poolKeys = furud.keys
          .where((k) => k != 'suami' && k != 'isteri')
          .toList();
      final poolSum = poolKeys.fold(0.0, (s, k) => s + (furud[k] ?? 0));
      if (poolSum > 1e-12) {
        for (final kx in poolKeys) {
          final add = residu * (furud[kx]! / poolSum);
          furud[kx] = furud[kx]! + add;
        }
        raddApplied = true;
        residu = 0.0;
      }
    }

    // 7) Final per relation key
    final finalByKey = <String, double>{};
    for (final e in furud.entries) {
      finalByKey[e.key] = (finalByKey[e.key] ?? 0) + e.value;
    }
    for (final e in asabah.entries) {
      finalByKey[e.key] = (finalByKey[e.key] ?? 0) + e.value;
    }

    // 8) Expand to individual lines
    final lines = <_ResultHeirLine>[];
    double? estate = double.tryParse(_estateController.text.trim());
    if (estate != null && estate <= 0) estate = null;

    Role roleOf(String key) {
      final f = furud[key] ?? 0.0;
      final a = asabah[key] ?? 0.0;
      if (f > 0 && a == 0) return Role.furud;
      if (f == 0 && a > 0) return Role.asabah;
      if (f > 0 && a > 0) return Role.asabah; // e.g. bapa 1/6 + residu
      return Role.none;
    }

    void addLinesSplitEqually(
      String label,
      String key,
      int count, {
      String note = '',
    }) {
      final share = finalByKey[key] ?? 0.0;
      if (share <= 1e-12 || count <= 0) return;
      final each = share / count;
      for (int i = 1; i <= count; i++) {
        final name = count > 1 ? '$label #$i' : label;
        lines.add(
          _ResultHeirLine(
            displayName: name,
            shareFraction: each,
            role: roleOf(key),
            note: note,
            value: (estate != null) ? estate * each : null,
          ),
        );
      }
    }

    // Spouses
    if (deceasedFemale) addLinesSplitEqually('Suami', 'suami', suami);
    if (deceasedMale)
      addLinesSplitEqually(
        'Isteri',
        'isteri',
        isteri,
        note: 'Dibahagi sama rata',
      );

    // Parents
    addLinesSplitEqually('Ibu', 'ibu', ibu);
    addLinesSplitEqually('Bapa', 'bapa', bapa);

    // Children
    addLinesSplitEqually('Anak Lelaki', 'anakL', anakL);
    addLinesSplitEqually('Anak Perempuan', 'anakP', anakP);

    // Level-2
    addLinesSplitEqually('Cucu Lelaki (melalui anak lelaki)', 'cucuL', cucuL);
    addLinesSplitEqually(
      'Cucu Perempuan (melalui anak lelaki)',
      'cucuP',
      cucuP,
    );
    addLinesSplitEqually('Datuk (sebelah bapa)', 'datuk', datuk);
    addLinesSplitEqually('Nenek (sebelah ibu)', 'nenekIbu', nenekIbu);
    addLinesSplitEqually('Nenek (sebelah bapa)', 'nenekBapa', nenekBapa);

    return _Result(
      lines: lines,
      blockedHeirsNotes: blockedNotes,
      awlApplied: awlApplied,
      raddApplied: raddApplied,
    );
  }

  void _openAddWarisSheet() {
    const femaleRelations = {
      'ibu',
      'nenek',
      'isteri',
      'anak_perempuan',
      'cucu_perempuan',
      'saudara_perempuan',
    };

    const maleRelations = {
      'bapa',
      'datuk',
      'suami',
      'anak_lelaki',
      'cucu_lelaki',
      'saudara_lelaki',
    };
    // seed from your inline defaults
    String relKey = _newRelationKey;
    int level = _newLevel;
    Gender gender = _newGender;
    bool alive = _newAlive;
    final nameC = TextEditingController(text: _newName.text);
    final countC = TextEditingController(text: _newCount.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                media.viewInsets.bottom + 12,
              ),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_add_alt_1),
                          const SizedBox(width: 8),
                          Text(
                            'Tambah Waris',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.of(ctx).maybePop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView(
                          controller: controller,
                          children: [
                            // Jenis Waris
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: relKey,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Waris',
                                prefixIcon: Icon(
                                  Icons.family_restroom_outlined,
                                ),
                              ),
                              items: relationOptions
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o.key,
                                      child: Text(
                                        o.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setSheetState(() {
                                  relKey = v ?? relKey;
                                  if (v != null &&
                                      femaleRelations.contains(v)) {
                                    gender = Gender.female;
                                  } else if (v != null &&
                                      maleRelations.contains(v)) {
                                    gender = Gender.male;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),

                            // Level
                            DropdownButtonFormField<int>(
                              value: level,
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
                              onChanged: (v) =>
                                  setSheetState(() => level = v ?? level),
                            ),
                            const SizedBox(height: 10),

                            // Jantina
                            DropdownButtonFormField<Gender>(
                              value: gender,
                              decoration: const InputDecoration(
                                labelText: 'Jantina',
                                prefixIcon: Icon(Icons.wc_outlined),
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
                                  setSheetState(() => gender = v ?? gender),
                            ),
                            const SizedBox(height: 10),

                            // Bilangan
                            TextField(
                              controller: countC,
                              decoration: const InputDecoration(
                                labelText: 'Bilangan',
                                prefixIcon: Icon(Icons.onetwothree_outlined),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                            const SizedBox(height: 10),

                            // Nama / Catatan
                            TextField(
                              controller: nameC,
                              decoration: const InputDecoration(
                                labelText: 'Nama / Catatan (opsyenal)',
                                prefixIcon: Icon(Icons.note_alt_outlined),
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                            const SizedBox(height: 10),

                            // Alive
                            _InlineSwitch(
                              label: 'Masih hidup',
                              value: alive,
                              onChanged: (v) => setSheetState(() => alive = v),
                            ),
                            const SizedBox(height: 12),

                            // Preview chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _miniChip(
                                  Icons.badge_outlined,
                                  relationOptions
                                      .firstWhere((o) => o.key == relKey)
                                      .label,
                                ),
                                _miniChip(
                                  Icons.filter_2_outlined,
                                  'Level $level',
                                ),
                                _miniChip(
                                  Icons.wc_outlined,
                                  gender == Gender.male
                                      ? 'Lelaki'
                                      : 'Perempuan',
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

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  nameC.clear();
                                  countC.text = '1';
                                  level = 1;
                                  alive = true;
                                  // auto gender again from relation
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
                                final count =
                                    int.tryParse(countC.text.trim()) ?? -1;
                                if (count <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Bilangan tidak sah.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _members.add(
                                    FaraidMember(
                                      nameController: TextEditingController(
                                        text: nameC.text,
                                      ),
                                      countController: TextEditingController(
                                        text: count.toString(),
                                      ),
                                      relationKey: relKey,
                                      level: level,
                                      gender: gender,
                                      alive: alive,
                                    ),
                                  );
                                  // persist defaults (optional)
                                  _newRelationKey = relKey;
                                  _newLevel = level;
                                  _newGender = gender;
                                  _newAlive = alive;
                                  _newName.text = '';
                                  _newCount.text = '1';
                                });
                                Navigator.of(ctx).maybePop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Waris ditambah.'),
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
                  );
                },
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // optional: dispose temp controllers
      nameC.dispose();
      countC.dispose();
    });
  }
}

/// ======= Models & helpers =======

enum Gender { male, female }

enum AssetUnit { percentOnly, rm, hektar }

enum Role { furud, asabah, radd, blocked, none }

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

  String relationKey; // from relationOptions keys
  int level; // generational/priority level (1..n)
  Gender gender;
  bool alive;
}

class RelationOption {
  final String key;
  final String label;
  const RelationOption(this.key, this.label);
}

// Common relations (boleh tambah/ubah ikut keperluan)
const List<RelationOption> relationOptions = [
  RelationOption('suami', 'Suami'),
  RelationOption('isteri', 'Isteri'),
  RelationOption('anakL', 'Anak Lelaki'),
  RelationOption('anakP', 'Anak Perempuan'),
  RelationOption('cucuL', 'Cucu Lelaki (melalui anak lelaki)'),
  RelationOption('cucuP', 'Cucu Perempuan (melalui anak lelaki)'),
  RelationOption('bapa', 'Bapa'),
  RelationOption('ibu', 'Ibu'),
  RelationOption('datuk', 'Datuk (sebelah bapa)'),
  RelationOption('nenekBapa', 'Nenek (sebelah bapa)'),
  RelationOption('nenekIbu', 'Nenek (sebelah ibu)'),
  RelationOption('sb_seibuSebapa_L', 'Saudara Lelaki Seibu-sebapa'),
  RelationOption('ss_seibuSebapa_P', 'Saudara Perempuan Seibu-sebapa'),
  RelationOption('sb_sebapa_L', 'Saudara Lelaki Sebapa'),
  RelationOption('ss_sebapa_P', 'Saudara Perempuan Sebapa'),
  RelationOption('saudaraSeibu', 'Saudara Seibu'),
];

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.color,
  });
  final String title;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
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

class _MiniChipsWrap extends StatelessWidget {
  const _MiniChipsWrap({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: children);
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
        labelText: 'Status',
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 18),
          const SizedBox(width: 6),
          Text(label),
          const SizedBox(width: 6),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// Lightweight result models for popup
class _ResultHeirLine {
  _ResultHeirLine({
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

class _Result {
  _Result({
    required this.lines,
    required this.blockedHeirsNotes,
    required this.awlApplied,
    required this.raddApplied,
  });
  final List<_ResultHeirLine> lines;
  final List<String> blockedHeirsNotes;
  final bool awlApplied;
  final bool raddApplied;
}
