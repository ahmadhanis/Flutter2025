// ignore_for_file: avoid_print

import 'dart:developer';

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
  static const Color _primary = Color(0xFF1B5E3A);
  static const Color _primarySoft = Color(0xFFE8F4ED);
  static const Color _background = Color(0xFFFAFCF8);
  static const Color _textStrong = Color(0xFF163225);
  static const Color _textMuted = Color(0xFF66756B);
  static const Color _darkBackground = Color(0xFF0F1F18);
  static const Color _darkSurface = Color(0xFF172820);
  static const Color _darkPrimarySoft = Color(0xFF243D31);
  static const Color _darkTextStrong = Color(0xFFEAF6EE);
  static const Color _darkTextMuted = Color(0xFFA8B8AD);
  static const Color _lightBorder = Color(0xFFDCE8DF);
  static const Color _darkBorder = Color(0xFF30483B);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context) ? _darkBackground : _background;
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? _darkSurface : Colors.white;
  }

  static Color softSurface(BuildContext context) {
    return isDark(context) ? _darkPrimarySoft : _primarySoft;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? _darkBorder : _lightBorder;
  }

  static Color strongText(BuildContext context) {
    return isDark(context) ? _darkTextStrong : _textStrong;
  }

  static Color mutedText(BuildContext context) {
    return isDark(context) ? _darkTextMuted : _textMuted;
  }

  static Color accent(BuildContext context) {
    return isDark(context) ? const Color(0xFFBDE8C8) : _primary;
  }

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
    required double totalekar,
    required double totalrelung,
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
            'Hektar: ${fmtD(hektar)} | Ekar: ${fmtD(totalekar)}  | Relong : ${fmtD(totalrelung)} |',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Jumlah Pecahan: ${fmtD(totalFraction)} '
            '(${(totalFraction * 100).toStringAsFixed(2)}%)'
            '${cukai > 0 ? '  |  Cukai: RM ${fmtMoney(cukai)}  |  Diagih: RM ${fmtMoney(totalTaxAllocated)}  |  Baki: RM ${fmtMoney(remainingTax)}' : ''}',
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
    required double totalekar,
    required double totalrelung,
  }) async {
    final bytes = await _buildPdfBytes(
      totalFraction: totalFraction,
      hektar: hektar,
      cukai: cukai,
      totalekar: totalekar,
      totalrelung: totalrelung,
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
    required double totalekar,
    required double totalrelung,
  }) async {
    final bytes = await _buildPdfBytes(
      totalFraction: totalFraction,
      hektar: hektar,
      cukai: cukai,
      totalekar: totalekar,
      totalrelung: totalrelung,
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
    final isDark = _MyTanahCalState.isDark(context);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: _MyTanahCalState.background(context),
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xFF66BB6A) : _primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: _MyTanahCalState.surface(context),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: _MyTanahCalState.surface(context),
        labelStyle: TextStyle(color: _MyTanahCalState.mutedText(context)),
        hintStyle: TextStyle(
          color: _MyTanahCalState.mutedText(context).withValues(alpha: 0.75),
        ),
        prefixIconColor: _MyTanahCalState.accent(context),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _MyTanahCalState.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: _MyTanahCalState.accent(context),
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          final double totalEkar = _hektar * factorEkar;
          final double totalRelung = _hektar * factorRelung;
          final double totalKakiPersegi = _hektar * factorKakiPersegi;
          final double totalMeterPersegi = _hektar * factorMeterPersegi;

          final double totalFraction = divisions.fold(
            0.0,
            (sum, d) => sum + d.fraction,
          );

          final bool hasTax = _cukai > 0;
          final double totalTaxAllocated = hasTax
              ? _cukai * totalFraction
              : 0.0;
          final double remainingTax = hasTax
              ? (_cukai - totalTaxAllocated)
              : 0.0;

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: _MyTanahCalState.surface(context),
              foregroundColor: _MyTanahCalState.strongText(context),
              surfaceTintColor: _MyTanahCalState.surface(context),
              title: const Text(
                'Pembahagian Tanah',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              actions: [
                IconButton(
                  tooltip: 'Reset',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: confirmResetDialog,
                ),
                IconButton(
                  tooltip: 'Cetak/Export PDF',
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  onPressed: () {
                    if (divisions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tiada pembahagian tanah.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      showDialogPrintPDF(totalEkar, totalRelung);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Kongsi PDF',
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => _sharePdf(
                    totalFraction: totalFraction,
                    hektar: _hektar,
                    cukai: _cukai,
                    totalekar: totalEkar,
                    totalrelung: totalRelung,
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _addDivision,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Bahagian'),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;
                final horizontalPadding = isWide ? 28.0 : 16.0;
                final summary = _buildSummaryPanel(
                  totalFraction: totalFraction,
                  totalEkar: totalEkar,
                  totalRelung: totalRelung,
                  totalKakiPersegi: totalKakiPersegi,
                  totalMeterPersegi: totalMeterPersegi,
                  totalTaxAllocated: totalTaxAllocated,
                  remainingTax: remainingTax,
                  hasTax: hasTax,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    96,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPageHeader(totalFraction),
                          const SizedBox(height: 18),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      _buildLandInfoSection(),
                                      const SizedBox(height: 16),
                                      _buildDivisionSection(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      summary,
                                      const SizedBox(height: 14),
                                      _buildSaveButton(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildLandInfoSection(),
                            const SizedBox(height: 16),
                            _buildDivisionSection(),
                            const SizedBox(height: 16),
                            summary,
                            const SizedBox(height: 14),
                            _buildSaveButton(),
                          ],
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

  Widget _buildPageHeader(double totalFraction) {
    final isComplete = (totalFraction - 1).abs() < 0.000001;
    final isOver = totalFraction > 1;
    final progress = totalFraction.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _MyTanahCalState.surface(context),
        border: Border.all(color: _MyTanahCalState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _MyTanahCalState.softSurface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.landscape_outlined,
                  color: _MyTanahCalState.accent(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalkulator Pembahagian',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _MyTanahCalState.strongText(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${divisions.length} bahagian direkodkan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MyTanahCalState.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _MyTanahCalState.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.redAccent : _MyTanahCalState.accent(context),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  isOver
                      ? 'Jumlah pecahan melebihi 100%'
                      : isComplete
                      ? 'Pembahagian lengkap'
                      : 'Baki ${(100 - (totalFraction * 100)).clamp(0, 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isOver
                        ? Colors.redAccent
                        : _MyTanahCalState.mutedText(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(totalFraction * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  color: _MyTanahCalState.strongText(context),
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandInfoSection() {
    return _ModernSection(
      title: 'Maklumat Tanah',
      icon: Icons.info_outline_rounded,
      child: ExpansionTile(
        initiallyExpanded: _isMaklumatExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: const Text(
          'Butiran geran, lot, cukai dan keluasan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Isi keluasan hektar sebelum tambah bahagian.'),
        onExpansionChanged: (value) {
          setState(() => _isMaklumatExpanded = value);
        },
        children: [
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final fieldWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _buildTextField(
                      controller: _geranController,
                      label: 'No Geran',
                      hint: 'cth: GM123',
                      icon: Icons.description_outlined,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _buildTextField(
                      controller: _lotController,
                      label: 'No Lot',
                      hint: 'cth: Lot 456',
                      icon: Icons.map_outlined,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _buildTextField(
                      controller: _cukaiController,
                      label: 'Jumlah Cukai',
                      hint: 'cth: 1200.00',
                      icon: Icons.payments_outlined,
                      prefixText: 'RM ',
                      onChanged: _updateCukai,
                      isNumber: true,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _buildTextField(
                      controller: _hektarController,
                      focusNode: _hektarFocusNode,
                      label: 'Jumlah Hektar',
                      hint: 'cth: 1.5',
                      icon: Icons.landscape_outlined,
                      onChanged: _updateHektar,
                      isNumber: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    String? prefixText,
    bool isNumber = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildDivisionSection() {
    return _ModernSection(
      title: 'Pembahagian',
      icon: Icons.call_split_outlined,
      trailing: FilledButton.icon(
        onPressed: _addDivision,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      child: divisions.isEmpty
          ? _EmptyDivisionState(onAdd: _addDivision)
          : Column(
              children: [
                for (int index = 0; index < divisions.length; index++) ...[
                  _buildDivisionCard(index),
                  if (index != divisions.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _buildDivisionCard(int index) {
    final d = divisions[index];
    final fraction = d.fraction;
    final divisionHektar = _hektar * fraction;
    final divisionEkar = divisionHektar * factorEkar;
    final divisionRelung = divisionHektar * factorRelung;
    final divisionKakiPersegi = divisionHektar * factorKakiPersegi;
    final divisionMeterPersegi = divisionHektar * factorMeterPersegi;
    final divisionTax = (_cukai > 0) ? (_cukai * fraction) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _MyTanahCalState.surface(context),
        border: Border.all(color: _MyTanahCalState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _MyTanahCalState.softSurface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: _MyTanahCalState.accent(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bahagian ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _MyTanahCalState.strongText(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hapus bahagian',
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.redAccent,
                onPressed: () => _removeDivision(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final fieldWidth = isWide
                  ? (constraints.maxWidth - 44) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _buildTextField(
                      controller: d.numeratorController,
                      label: 'Pembilang',
                      hint: 'cth: 1',
                      icon: Icons.exposure_plus_1_outlined,
                      isNumber: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (isWide)
                    const SizedBox(
                      width: 24,
                      child: Center(
                        child: Text(
                          '/',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: fieldWidth,
                    child: _buildTextField(
                      controller: d.denominatorController,
                      label: 'Penyebut',
                      hint: 'cth: 8',
                      icon: Icons.exposure_zero_outlined,
                      isNumber: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _MyTanahCalState.softSurface(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.percent_rounded,
                  color: _MyTanahCalState.accent(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pecahan',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _MyTanahCalState.strongText(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  fraction.toStringAsFixed(10),
                  style: TextStyle(
                    color: _MyTanahCalState.strongText(context),
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildSummaryRowPembagi(
                Icons.landscape_outlined,
                'Hektar',
                divisionHektar.toStringAsFixed(10),
              ),
              _buildSummaryRowPembagi(
                Icons.square_foot_outlined,
                'Ekar',
                divisionEkar.toStringAsFixed(10),
              ),
              _buildSummaryRowPembagi(
                Icons.terrain_outlined,
                'Relung',
                divisionRelung.toStringAsFixed(10),
              ),
              _buildSummaryRowPembagi(
                Icons.grid_on_outlined,
                'Kaki Persegi',
                divisionKakiPersegi.toStringAsFixed(7),
              ),
              _buildSummaryRowPembagi(
                Icons.straighten_outlined,
                'Meter Persegi',
                divisionMeterPersegi.toStringAsFixed(0),
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
    );
  }

  Widget _buildSummaryPanel({
    required double totalFraction,
    required double totalEkar,
    required double totalRelung,
    required double totalKakiPersegi,
    required double totalMeterPersegi,
    required double totalTaxAllocated,
    required double remainingTax,
    required bool hasTax,
  }) {
    return _ModernSection(
      title: 'Ringkasan',
      icon: Icons.summarize_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Pecahan & Baki'),
          _buildSummaryTable([
            [
              'Jumlah Pecahan',
              '${totalFraction.toStringAsFixed(5)} (${(totalFraction * 100).toStringAsFixed(2)}%)',
            ],
            [
              'Baki Pecahan',
              totalFraction <= 1
                  ? '${(1 - totalFraction).toStringAsFixed(4)} (${((1 - totalFraction) * 100).toStringAsFixed(2)}%)'
                  : 'Melebihi 100%',
            ],
          ], warningIndex: totalFraction > 1 ? 1 : null),
          const SizedBox(height: 18),
          _buildSectionHeader('Luas Kawasan'),
          _buildSummaryTable([
            ['Hektar', _hektar.toStringAsFixed(7)],
            ['Ekar', totalEkar.toStringAsFixed(7)],
            ['Relung', totalRelung.toStringAsFixed(7)],
            ['Kaki Persegi', totalKakiPersegi.toStringAsFixed(7)],
            ['Meter Persegi', totalMeterPersegi.toStringAsFixed(7)],
          ]),
          if (hasTax) ...[
            const SizedBox(height: 18),
            _buildSectionHeader('Cukai'),
            _buildSummaryTable([
              ['Jumlah Cukai', 'RM ${_cukai.toStringAsFixed(2)}'],
              ['Cukai Diagih', 'RM ${totalTaxAllocated.toStringAsFixed(2)}'],
              ['Baki Cukai', 'RM ${remainingTax.toStringAsFixed(2)}'],
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.save_outlined),
        label: const Text('Simpan Rekod'),
        onPressed: () => _showConfirmationDialog(context),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
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
              Icon(icon, size: 18, color: _MyTanahCalState.accent(context)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _MyTanahCalState.strongText(context),
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
            style: TextStyle(
              fontSize: 14,
              // fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: _MyTanahCalState.strongText(context),
              fontFeatures: const [FontFeature.tabularFigures()],
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: _MyTanahCalState.strongText(context),
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
              color: isWarning
                  ? Colors.redAccent.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  row[0],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isWarning
                        ? Colors.redAccent
                        : _MyTanahCalState.mutedText(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  row[1],
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isWarning
                        ? Colors.redAccent
                        : _MyTanahCalState.strongText(context),
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

  showDialogPrintPDF(double totalEkar, double totalRelung) {
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
                totalekar: totalEkar,
                totalrelung: totalRelung,
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

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Data saved successfully")));

      // Optional: clear inputs
    } catch (e) {
      log(e.toString());
      // String error = e.toString();
      if (!mounted) return;
      if (e.toString().contains("Geran already exists")) {
        await SQLiteHelper().updateGeranAndPembahagian(
          _geranController.text,
          _lotController.text,
          cukai,
          hektar,
          divisions,
        );
        if (!mounted) return;
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

class _ModernSection extends StatelessWidget {
  const _ModernSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MyTanahCalState.surface(context),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _MyTanahCalState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _MyTanahCalState.softSurface(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: _MyTanahCalState.accent(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _MyTanahCalState.strongText(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyDivisionState extends StatelessWidget {
  const _EmptyDivisionState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: _MyTanahCalState.background(context),
        border: Border.all(color: _MyTanahCalState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.call_split_outlined,
            size: 38,
            color: _MyTanahCalState.accent(context),
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada pembahagian',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _MyTanahCalState.strongText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambah bahagian pertama selepas masukkan jumlah hektar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _MyTanahCalState.mutedText(context),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Bahagian'),
          ),
        ],
      ),
    );
  }
}
