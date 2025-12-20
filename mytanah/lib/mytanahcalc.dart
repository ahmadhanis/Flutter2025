// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mytanah/division.dart';
import 'package:mytanah/sqlite_helper.dart';

// PDF & printing
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class MyTanahCal extends StatefulWidget {
  final String? noGeran;
  final String? noLot;
  final double? cukai;
  final double? hektar;
  final List<Division>? divisions;
  final List pembahagianList;

  const MyTanahCal({
    super.key,
    this.noGeran,
    this.noLot,
    this.cukai,
    this.hektar,
    this.divisions,
    required this.pembahagianList,
  });

  @override
  State<MyTanahCal> createState() => _MyTanahCalState();
}

class _MyTanahCalState extends State<MyTanahCal> {
  // Controllers
  final TextEditingController _cukaiController = TextEditingController();
  final TextEditingController _hektarController = TextEditingController();
  final TextEditingController _geranController = TextEditingController();
  final TextEditingController _lotController = TextEditingController();
  final FocusNode _hektarFocusNode = FocusNode();

  // State nilai
  double _cukai = 0;
  double _hektar = 0;

  // Faktor penukaran
  final double factorEkar = 2.471054;
  final double factorRelung = 3.4749196;
  final double factorKakiPersegi = 107639;
  final double factorMeterPersegi = 10000;
  bool _isMaklumatExpanded = true; // Add this to your state

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
    //if jumlah pecahan == 100% show snackbar

    if (_hektarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai hektar dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      FocusScope.of(context).requestFocus(_hektarFocusNode);
      _isMaklumatExpanded = true;
      return;
    }

    final totalFraction = divisions.fold(0.0, (sum, d) => sum + d.fraction);
    print(totalFraction);
    if (totalFraction >= 1 && divisions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah pecahan melebihi 100%.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => divisions.add(Division()));
  }

  void _removeDivision(int index) => setState(() => divisions.removeAt(index));

  @override
  void initState() {
    super.initState();

    if (widget.noGeran != null) {
      _geranController.text = widget.noGeran!;
    }
    if (widget.noLot != null) {
      _lotController.text = widget.noLot!;
    }
    if (widget.cukai != null) {
      _cukaiController.text = widget.cukai!.toString();
    }
    if (widget.hektar != null) {
      _hektarController.text = widget.hektar!.toString();
    }
    if (widget.divisions != null) {
      divisions = widget.divisions!;
    }
    divisions = widget.pembahagianList.map<Division>((e) {
      print(e.toString());
      return Division(
        numerator: e['pembilang'].toString(),
        denominator: e['penyebut'].toString(),
      );
    }).toList();
    if (_hektarController.text.isNotEmpty) {
      _updateHektar(_hektarController.text);
      _updateCukai(_cukaiController.text);
    }
  }

  @override
  void dispose() {
    _cukaiController.dispose();
    _hektarController.dispose();
    _geranController.dispose();
    _lotController.dispose();
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
    final now = DateTime.now();
    final timestamp = DateFormat('dd/MM/yyyy hh:mm a').format(now);

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
          pw.SizedBox(height: 6),
          pw.Text(
            'Dicetak pada: $timestamp',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'No Geran: ${_geranController.text}  |  No Lot: ${_lotController.text}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
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
          pw.SizedBox(height: 18),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text(
            'Harta Pusaka Kedah Perlis',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '019-552 2842 (Hj. Rosli)',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '017-403 6962 (Huda)',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '013-593 6680 (Hidayah)',
            style: const pw.TextStyle(fontSize: 10),
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
              elevation: 3,
              //implement green tint background
              backgroundColor: const Color(0xFF2D6A4F).withValues(alpha: 0.5),
              title: const Text(
                'Pembahagian Tanah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Reset',
                  icon: const Icon(Icons.refresh_rounded, color: Colors.green),
                  onPressed: () {
                    //showdialog reset
                    confirmResetDialog();
                  },
                ),
                IconButton(
                  tooltip: 'Cetak/Export PDF',
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.blueGrey,
                  ),
                  onPressed: () {
                    //if baki no pembahagian is avaialble show dialog
                    if (divisions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tiada pembahagian tanah.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      //showdialog print pdf
                      showDialogPrintPDF();
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Kongsi PDF',
                  icon: const Icon(Icons.share_rounded, color: Colors.teal),
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
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),

            floatingActionButton: FloatingActionButton.extended(
              onPressed: _addDivision,
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                // final isMedium = constraints.maxWidth >= 640;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ===== INPUTS =====
                          ExpansionTileCard(
                            // initialPadding: const EdgeInsets.all(0),
                            // baseColor: Theme.of(context).colorScheme.surface,
                            initiallyExpanded: true,
                            elevation: 1.5,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),

                            title: Row(
                              children: const [
                                Icon(Icons.info_outline_rounded),
                                SizedBox(width: 10),
                                Text(
                                  'Maklumat Tanah',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              _isMaklumatExpanded
                                  ? Icons.expand_more
                                  : Icons.expand_less,
                            ),
                            onExpansionChanged: (value) {
                              setState(() {
                                _isMaklumatExpanded = value;
                              });
                            },
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                                child: Column(
                                  children: [
                                    // Row 1: No Geran & No Lot
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _geranController,
                                            decoration: InputDecoration(
                                              labelText: 'No Geran',
                                              hintText: 'cth: GM123',
                                              prefixIcon: const Icon(
                                                Icons.description_outlined,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _lotController,
                                            decoration: InputDecoration(
                                              labelText: 'No Lot',
                                              hintText: 'cth: Lot 456',
                                              prefixIcon: const Icon(
                                                Icons.map_outlined,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Row 2: Jumlah Cukai & Hektar
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _cukaiController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            onChanged: _updateCukai,
                                            decoration: InputDecoration(
                                              labelText: 'Jumlah Cukai',
                                              prefixText: 'RM ',
                                              hintText: 'cth: 1200.00',
                                              prefixIcon: const Icon(
                                                Icons.payments_outlined,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _hektarController,
                                            focusNode:
                                                _hektarFocusNode, // Attach focus node here
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            onChanged: _updateHektar,
                                            decoration: InputDecoration(
                                              labelText: 'Jumlah Hektar',
                                              hintText: 'cth: 1.5',
                                              prefixIcon: const Icon(
                                                Icons.landscape_outlined,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                    borderRadius: BorderRadius.circular(8),
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
                                        Table(
                                          columnWidths: const {
                                            0: IntrinsicColumnWidth(),
                                            1: FlexColumnWidth(),
                                          },
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          children: [
                                            _buildSummaryRowPembagi(
                                              Icons.landscape_outlined,
                                              'Hektar',
                                              divisionHektar.toStringAsFixed(
                                                10,
                                              ),
                                            ),
                                            _buildSummaryRowPembagi(
                                              Icons.square_foot_outlined,
                                              'Ekar',
                                              divisionEkar.toStringAsFixed(10),
                                            ),
                                            _buildSummaryRowPembagi(
                                              Icons.terrain_outlined,
                                              'Relung',
                                              divisionRelung.toStringAsFixed(
                                                10,
                                              ),
                                            ),
                                            _buildSummaryRowPembagi(
                                              Icons.grid_on_outlined,
                                              'Kaki Persegi',
                                              divisionKakiPersegi
                                                  .toStringAsFixed(7),
                                            ),
                                            _buildSummaryRowPembagi(
                                              Icons.straighten_outlined,
                                              'Meter Persegi',
                                              divisionMeterPersegi
                                                  .toStringAsFixed(0),
                                            ),
                                            if (_cukai > 0)
                                              _buildSummaryRowPembagi(
                                                Icons.payments_outlined,
                                                'Cukai (RM)',
                                                divisionTax.toStringAsFixed(2),
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
                          // ===== RINGKASAN COMPACT =====
                          ExpansionTileCard(
                            initiallyExpanded: false,
                            elevation: 1.5,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            title: Row(
                              children: const [
                                Icon(Icons.summarize_outlined),
                                SizedBox(width: 10),
                                Text(
                                  'Ringkasan Pembahagian',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader("1. Pecahan & Baki"),
                                    _buildSummaryTable([
                                      [
                                        "Jumlah Pecahan",
                                        "${totalFraction.toStringAsFixed(5)} (${(totalFraction * 100).toStringAsFixed(5)}%)",
                                      ],
                                      [
                                        "Baki Pecahan",
                                        totalFraction <= 1
                                            ? "${(1 - totalFraction).toStringAsFixed(4)} (${((1 - totalFraction) * 100).toStringAsFixed(4)}%)"
                                            : "❗ Melebihi 100% ",
                                      ],
                                    ], warningIndex: totalFraction > 1 ? 1 : null),

                                    const SizedBox(height: 20),

                                    _buildSectionHeader("2. Luas Kawasan"),
                                    _buildSummaryTable([
                                      ["Ekar", totalEkar.toStringAsFixed(7)],
                                      [
                                        "Relung",
                                        totalRelung.toStringAsFixed(7),
                                      ],
                                      [
                                        "Kaki Persegi",
                                        totalKakiPersegi.toStringAsFixed(7),
                                      ],
                                      [
                                        "Meter Persegi",
                                        totalMeterPersegi.toStringAsFixed(7),
                                      ],
                                    ]),

                                    const SizedBox(height: 20),

                                    if (hasTax) ...[
                                      _buildSectionHeader("3. Cukai"),
                                      _buildSummaryTable([
                                        [
                                          "Jumlah Cukai",
                                          "RM ${_cukai.toStringAsFixed(2)}",
                                        ],
                                        [
                                          "Cukai Diagih",
                                          "RM ${totalTaxAllocated.toStringAsFixed(2)}",
                                        ],
                                        [
                                          "Baki Cukai",
                                          "RM ${remainingTax.toStringAsFixed(2)}",
                                        ],
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text("Simpan Rekod"),
                            onPressed: () {
                              _showConfirmationDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
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

  TableRow _buildSummaryRowPembagi(IconData icon, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              // fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSummaryTable(List<List<String>> rows, {int? warningIndex}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isWarning = warningIndex == index;

          return TableRow(
            decoration: BoxDecoration(
              color: isWarning ? Colors.red.shade50 : Colors.transparent,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  row[0],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isWarning ? Colors.red : Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  row[1],
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isWarning ? Colors.red : Colors.black87,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void confirmResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Reset?'),
          ],
        ),
        content: const Text(
          'Adakah anda pasti ingin mereset semua maklumat pembahagian tanah? Tindakan ini tidak boleh dipulihkan.',
          style: TextStyle(height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('Batal'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cukaiController.clear();
                _hektarController.clear();
                _geranController.clear();
                _lotController.clear();
                _cukai = 0;
                _hektar = 0;
                divisions.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Skrin telah direset.'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  showDialogPrintPDF() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Print PDF?'),
          ],
        ),
        content: const Text(
          'Adakah anda pasti ingin mencetak skrin PDF?',
          style: TextStyle(height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('Batal'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _printPdf(
                totalFraction: divisions.fold(
                  0.0,
                  (sum, d) => sum + d.fraction,
                ),
                hektar: _hektar,
                cukai: _cukai,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    if (_geranController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan No Geran dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan Rekod'),
        content: const Text(
          'Adakah anda pasti ingin menyimpan maklumat ini ke pangkalan data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              print('SAVE');
              _saveToDatabase(); // Proceed to save
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _saveToDatabase() async {
    log('Saving to database...');
    final double? cukai = double.tryParse(_cukaiController.text);
    final double? hektar = double.tryParse(_hektarController.text);

    if (cukai == null || hektar == null || divisions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill in cukai, hektar, and at least one pembahagian",
          ),
        ),
      );
      return;
    }
    //print divisions
    // for (var d in divisions) {
    //   log("HELLO");
    //   log(d.numeratorController.text);
    //   log(d.denominatorController.text);
    // }

    try {
      // Save with dummy geran and lot, since you said only cukai/hektar/divisions are stored
      await SQLiteHelper().saveData(
        _geranController.text,
        _lotController.text,
        cukai,
        hektar,
        divisions,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Data saved successfully")));

      // Optional: clear inputs
    } catch (e) {
      log(e.toString());
      // String error = e.toString();
      if (e.toString().contains("Geran already exists")) {
        await SQLiteHelper().updateGeranAndPembahagian(
          _geranController.text,
          _lotController.text,
          cukai,
          hektar,
          divisions,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Geran updated successfully")),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving: ${e.toString()}")));
    }
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
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.input_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
