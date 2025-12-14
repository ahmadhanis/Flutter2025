import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mytanah/addwarissheet.dart';
import 'package:mytanah/controllers/MembersController.dart' hide Gender;
import 'package:mytanah/engine/faraid_engine.dart';
import 'package:mytanah/estatecalculatorsheet.dart';
import 'package:mytanah/models/ComputeResult.dart';
import 'package:mytanah/models/enums.dart';
import 'package:mytanah/sectioncard.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// =========================
/// Models & Enums
/// =========================

class RelationOption {
  final String key;
  final String label;
  const RelationOption(this.key, this.label);
}

const relationOptions = <RelationOption>[
  RelationOption('suami', 'Suami'),
  RelationOption('isteri', 'Isteri'),
  RelationOption('bapa', 'Bapa'),
  RelationOption('ibu', 'Ibu'),
  RelationOption('anakL', 'Anak Lelaki'),
  RelationOption('anakP', 'Anak Perempuan'),
  RelationOption('cucuL', 'Cucu Lelaki (melalui anak lelaki)'),
  RelationOption('cucuP', 'Cucu Perempuan (melalui anak lelaki)'),
  RelationOption('cicitL', 'Cicit Lelaki (melalui cucu lelaki)'),
  RelationOption('cicitP', 'Cicit Perempuan (melalui cucu lelaki)'),
];

const femaleRelations = {'isteri', 'ibu', 'anakP', 'cucuP', 'cicitP'};

const maleRelations = {'suami', 'bapa', 'anakL', 'cucuL', 'cicitL'};

/// =========================
/// Controller (state)
/// =========================

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

                final res = FaraidEngine.compute(ctrl); // ✅ use the new engine
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
                // final isWide = cons.maxWidth >= 900;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionCard(
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
                                      suffixIcon: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: const Size(
                                            0,
                                            40,
                                          ), // shrink height
                                        ),
                                        onPressed: () =>
                                            _openEstateCalculatorSheet(
                                              context,
                                              ctrl,
                                            ),
                                        icon: const Icon(
                                          Icons.calculate_rounded,
                                          color: Colors.redAccent,
                                        ),
                                        label: const Text('Kira'),
                                      ),
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
                                    initialValue: ctrl.unit.value,
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
                                    initialValue: ctrl.deceasedGender.value,
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
                          SectionCard(
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

  Future<void> _openEstateCalculatorSheet(
    BuildContext parentContext,
    MembersController ctrl,
  ) async {
    final result = await showModalBottomSheet<double>(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => EstateCalculatorSheet(ctrl: ctrl),
    );

    if (result != null && parentContext.mounted) {
      ctrl.estateController.text = result.toStringAsFixed(2);
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Pusaka Bersih dikemas kini.')),
      );
    }
  }

  // Build entry model

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
      builder: (ctx) => AddWarisSheet(
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
                          ? 'Pusaka RM ${estate.toStringAsFixed(2)}'
                          : unit == AssetUnit.hektar
                          ? 'Pusaka ${estate.toStringAsFixed(7)} ha'
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
                          ? 'Pusaka RM ${fmtMoney(estate)}'
                          : unit == AssetUnit.hektar
                          ? 'Pusaka ${fmtLand(estate)} ha'
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
