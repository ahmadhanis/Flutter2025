import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytanah/division.dart';

// PDF & printing
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class MyTanahCal extends StatefulWidget {
  const MyTanahCal({super.key});

  @override
  State<MyTanahCal> createState() => _MyTanahCalState();
}

class _MyTanahCalState extends State<MyTanahCal> {
  // Controllers
  final TextEditingController _cukaiController = TextEditingController();
  final TextEditingController _hektarController = TextEditingController();

  // State nilai
  double _cukai = 0;
  double _hektar = 0;

  // Faktor penukaran
  final double factorEkar = 2.471054;
  final double factorRelung = 3.4749196;
  final double factorKakiPersegi = 107639;
  final double factorMeterPersegi = 10000;

  // Senarai pembahagian dinamik
  List<Division> divisions = [];

  // Kemas kini nilai cukai dan hektar
  void _updateCukai(String value) => setState(() {
    _cukai = double.tryParse(value) ?? 0;
  });
  void _updateHektar(String value) => setState(() {
    _hektar = double.tryParse(value) ?? 0;
  });

  // Tambah/Buang pembahagian
  void _addDivision() {
    if (_hektarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai hektar dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => divisions.add(Division()));
  }

  void _removeDivision(int index) => setState(() => divisions.removeAt(index));

  @override
  void dispose() {
    _cukaiController.dispose();
    _hektarController.dispose();
    for (var d in divisions) {
      d.numeratorController.dispose();
      d.denominatorController.dispose();
    }
    super.dispose();
  }

  // ========= PRINT TO PDF =========
  Future<Uint8List> _buildPdfBytes({
    required double totalFraction,
    required double hektar,
    required double cukai,
  }) async {
    final doc = pw.Document();
    String fmtD(double v, {int f = 7}) => v.toStringAsFixed(f);
    String fmtMoney(double v) => v.toStringAsFixed(2);

    // ---------- Header: merged "Pecahan (n/d)" ----------
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
        children: [
          _cell('No.', bold: true),
          _cell('Pecahan (n/d)', bold: true),
          _cell('Pecahan', bold: true),
          _cell('Hektar', bold: true),
          _cell('Ekar', bold: true),
          _cell('Relung', bold: true),
          _cell('Kaki Persegi', bold: true),
          _cell('Meter Persegi', bold: true),
          _cell('Cukai (RM)', bold: true),
        ],
      ),
    ];

    for (int i = 0; i < divisions.length; i++) {
      final d = divisions[i];
      final numTxt = d.numeratorController.text.trim();
      final denTxt = d.denominatorController.text.trim();
      final fracNd = (numTxt.isEmpty || denTxt.isEmpty)
          ? '-'
          : '$numTxt/$denTxt';

      final fraction = d.fraction;
      final divisionHektar = hektar * fraction;
      final divisionEkar = divisionHektar * factorEkar;
      final divisionRelung = divisionHektar * factorRelung;
      final divisionKakiPersegi = divisionHektar * factorKakiPersegi;
      final divisionMeterPersegi = divisionHektar * factorMeterPersegi;
      final divisionTax = (cukai > 0) ? (cukai * fraction) : 0.0;

      rows.add(
        pw.TableRow(
          children: [
            _cell('${i + 1}'),
            _cell(fracNd),
            _cell(fraction.isFinite ? fmtD(fraction) : '0'),
            _cell(fmtD(divisionHektar)),
            _cell(fmtD(divisionEkar)),
            _cell(fmtD(divisionRelung)),
            _cell(divisionKakiPersegi.toStringAsFixed(0)),
            _cell(divisionMeterPersegi.toStringAsFixed(0)),
            _cell('RM ${fmtMoney(divisionTax)}'),
          ],
        ),
      );
    }

    final totalTaxAllocated = cukai > 0 ? cukai * totalFraction : 0.0;
    final remainingTax = cukai > 0 ? (cukai - totalTaxAllocated) : 0.0;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(30, 24, 30, 28),
          orientation: pw.PageOrientation.landscape,
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Laporan Pembahagian Tanah',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Ringkasan: Hektar=${fmtD(hektar)}  |  Jumlah Pecahan=${fmtD(totalFraction)} '
            '(${(totalFraction * 100).toStringAsFixed(2)}%)'
            '${cukai > 0 ? '  |  Cukai=RM ${fmtMoney(cukai)}  |  Diagih=RM ${fmtMoney(totalTaxAllocated)}  |  Baki=RM ${fmtMoney(remainingTax)}' : ''}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey500),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _printPdf({
    required double totalFraction,
    required double hektar,
    required double cukai,
  }) async {
    final bytes = await _buildPdfBytes(
      totalFraction: totalFraction,
      hektar: hektar,
      cukai: cukai,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'laporan_pembahagian_tanah.pdf',
    );
  }

  Future<void> _sharePdf({
    required double totalFraction,
    required double hektar,
    required double cukai,
  }) async {
    final bytes = await _buildPdfBytes(
      totalFraction: totalFraction,
      hektar: hektar,
      cukai: cukai,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'laporan_pembahagian_tanah.pdf',
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true, // compact inputs
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
      child: Builder(
        builder: (context) {
          // Kira penukaran jumlah untuk keseluruhan kawasan
          final double totalEkar = _hektar * factorEkar;
          final double totalRelung = _hektar * factorRelung;
          final double totalKakiPersegi = _hektar * factorKakiPersegi;
          final double totalMeterPersegi = _hektar * factorMeterPersegi;

          // Kira jumlah pecahan
          final double totalFraction = divisions.fold(
            0.0,
            (sum, d) => sum + d.fraction,
          );

          // Cukai
          final bool hasTax = _cukai > 0;
          final double totalTaxAllocated = hasTax
              ? _cukai * totalFraction
              : 0.0;
          final double remainingTax = hasTax
              ? (_cukai - totalTaxAllocated)
              : 0.0;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Pembahagian Tanah'),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Reset',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _cukaiController.clear();
                      _hektarController.clear();
                      _cukai = 0;
                      _hektar = 0;
                      divisions.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skrin telah direset.'),
                        duration: Duration(milliseconds: 1200),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Cetak/Export PDF',
                  onPressed: () => _printPdf(
                    totalFraction: divisions.fold(
                      0.0,
                      (sum, d) => sum + d.fraction,
                    ),
                    hektar: _hektar,
                    cukai: _cukai,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
                IconButton(
                  tooltip: 'Kongsi PDF',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _sharePdf(
                    totalFraction: divisions.fold(
                      0.0,
                      (sum, d) => sum + d.fraction,
                    ),
                    hektar: _hektar,
                    cukai: _cukai,
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _addDivision,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pembahagian'),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isMedium = constraints.maxWidth >= 640;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ===== INPUTS =====
                          _SectionCard(
                            title: 'Input',
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                SizedBox(
                                  width: isMedium ? 280 : double.infinity,
                                  child: TextField(
                                    controller: _cukaiController,
                                    decoration: const InputDecoration(
                                      labelText: 'Jumlah Cukai (RM)',
                                      prefixText: 'RM ',
                                      hintText: 'cth: 1200.00',
                                      prefixIcon: Icon(Icons.payments_outlined),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: _updateCukai,
                                  ),
                                ),
                                SizedBox(
                                  width: isMedium ? 280 : double.infinity,
                                  child: TextField(
                                    controller: _hektarController,
                                    decoration: const InputDecoration(
                                      labelText: 'Jumlah Hektar',
                                      hintText: 'cth: 1.5',
                                      prefixIcon: Icon(
                                        Icons.landscape_outlined,
                                      ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: _updateHektar,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ===== RINGKASAN COMPACT =====
                          _SectionCard(
                            title: 'Ringkasan',
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MiniChip(
                                  icon: Icons.pie_chart_outline_rounded,
                                  label:
                                      'Pecahan: ${totalFraction.toStringAsFixed(4)} '
                                      '(${(totalFraction * 100).toStringAsFixed(2)}%)',
                                ),
                                if (totalFraction <= 1)
                                  _MiniChip(
                                    icon: Icons.incomplete_circle_outlined,
                                    label:
                                        'Baki: ${(1 - totalFraction).toStringAsFixed(4)} '
                                        '(${((1 - totalFraction) * 100).toStringAsFixed(2)}%)',
                                  )
                                else
                                  _MiniChip.error(
                                    icon: Icons.warning_amber_rounded,
                                    label: 'Pecahan > 100%',
                                  ),
                                _MiniChip(
                                  icon: Icons.square_foot_outlined,
                                  label:
                                      'Ekar: ${totalEkar.toStringAsFixed(7)}',
                                ),
                                _MiniChip(
                                  icon: Icons.terrain_outlined,
                                  label:
                                      'Relung: ${totalRelung.toStringAsFixed(7)}',
                                ),
                                _MiniChip(
                                  icon: Icons.grid_on_outlined,
                                  label:
                                      'Kp²: ${totalKakiPersegi.toStringAsFixed(7)}',
                                ),
                                _MiniChip(
                                  icon: Icons.straighten_outlined,
                                  label:
                                      'm²: ${totalMeterPersegi.toStringAsFixed(7)}',
                                ),
                                if (hasTax)
                                  _MiniChip(
                                    icon: Icons.payments_outlined,
                                    label:
                                        'Cukai: RM ${_cukai.toStringAsFixed(2)}',
                                  ),
                                if (hasTax)
                                  _MiniChip(
                                    icon: Icons.call_split_outlined,
                                    label:
                                        'Diagih: RM ${totalTaxAllocated.toStringAsFixed(2)}',
                                  ),
                                if (hasTax)
                                  _MiniChip(
                                    icon: Icons.pending_outlined,
                                    label:
                                        'Baki: RM ${remainingTax.toStringAsFixed(2)}',
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ===== PEMBAHAGIAN (COMPACT) =====
                          _SectionCard(
                            title: 'Pembahagian',
                            child: Column(
                              children: List.generate(divisions.length, (
                                index,
                              ) {
                                final d = divisions[index];

                                final fraction = d.fraction;
                                final divisionHektar = _hektar * fraction;
                                final divisionEkar =
                                    divisionHektar * factorEkar;
                                final divisionRelung =
                                    divisionHektar * factorRelung;
                                final divisionKakiPersegi =
                                    divisionHektar * factorKakiPersegi;
                                final divisionMeterPersegi =
                                    divisionHektar * factorMeterPersegi;
                                final divisionTax = (_cukai > 0)
                                    ? (_cukai * fraction)
                                    : 0.0;

                                // COMPACT CARD: tiny paddings, inline inputs, chips summary
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
                                        // Header row: title + delete
                                        Row(
                                          children: [
                                            Text(
                                              'Pembahagian ${index + 1}',
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
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _removeDivision(index),
                                            ),
                                          ],
                                        ),

                                        // Inline inputs + fraction
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 120,
                                                  child: TextField(
                                                    controller:
                                                        d.numeratorController,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Pembilang',
                                                          isDense: true,
                                                        ),
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                    onChanged: (_) =>
                                                        setState(() {}),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  '/',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 120,
                                                  child: TextField(
                                                    controller:
                                                        d.denominatorController,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Penyebut',
                                                          isDense: true,
                                                        ),
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                    onChanged: (_) =>
                                                        setState(() {}),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            // Pecahan turun ke baris baru
                                            Text(
                                              'Pecahan: ${fraction.toStringAsFixed(10)}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelLarge,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),
                                        // Compact metrics as small chips
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _MiniChip(
                                              icon: Icons.landscape_outlined,
                                              label:
                                                  'Ha ${divisionHektar.toStringAsFixed(10)}',
                                            ),
                                            _MiniChip(
                                              icon: Icons.square_foot_outlined,
                                              label:
                                                  'Ekar ${divisionEkar.toStringAsFixed(10)}',
                                            ),
                                            _MiniChip(
                                              icon: Icons.terrain_outlined,
                                              label:
                                                  'Relung ${divisionRelung.toStringAsFixed(10)}',
                                            ),
                                            _MiniChip(
                                              icon: Icons.grid_on_outlined,
                                              label:
                                                  'Kp² ${divisionKakiPersegi.toStringAsFixed(7)}',
                                            ),
                                            _MiniChip(
                                              icon: Icons.straighten_outlined,
                                              label:
                                                  'm² ${divisionMeterPersegi.toStringAsFixed(0)}',
                                            ),
                                            if (_cukai > 0)
                                              _MiniChip(
                                                icon: Icons.payments_outlined,
                                                label:
                                                    'Cukai RM ${divisionTax.toStringAsFixed(2)}',
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

                          const SizedBox(height: 64), // space for FAB
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ===== Helper UI widgets =====

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    this.isError = false,
    this.enableTapCopyAlso =
        false, // optional: tap-to-copy fallback (web/desktop)
  });

  factory _MiniChip.error({
    required IconData icon,
    required String label,
    bool enableTapCopyAlso = false,
  }) => _MiniChip(
    icon: icon,
    label: label,
    isError: true,
    enableTapCopyAlso: enableTapCopyAlso,
  );

  final IconData icon;
  final String label;
  final bool isError;
  final bool enableTapCopyAlso;

  void _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: label));
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Disalin: $label'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isError ? cs.errorContainer : cs.secondaryContainer;
    final fg = isError ? cs.onErrorContainer : cs.onSecondaryContainer;

    final chip = Chip(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 14, color: fg),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: bg,
      side: BorderSide(color: cs.outlineVariant),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    // Make the chip copyable on long press (and optional tap)
    return Tooltip(
      message: 'Long press to copy',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onLongPress: () => _copy(context),
        onTap: enableTapCopyAlso ? () => _copy(context) : null, // optional
        borderRadius: BorderRadius.circular(20),
        splashColor: fg.withOpacity(0.12),
        highlightColor: Colors.transparent,
        child: chip,
      ),
    );
  }
}
