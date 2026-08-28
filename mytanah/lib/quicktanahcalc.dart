import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuickTanahCalc extends StatefulWidget {
  const QuickTanahCalc({super.key});

  @override
  State<QuickTanahCalc> createState() => _QuickTanahCalcState();
}

class _QuickTanahCalcState extends State<QuickTanahCalc> {
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

  static const double _factorEkar = 2.471054;
  static const double _factorRelung = 3.4749196;
  static const double _factorKakiPersegi = 107639;
  static const double _factorMeterPersegi = 10000;

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

  final TextEditingController _cukaiController = TextEditingController();
  final TextEditingController _hektarController = TextEditingController();
  final FocusNode _hektarFocusNode = FocusNode();
  final List<_QuickDivision> _divisions = [];

  double _cukai = 0;
  double _hektar = 0;

  @override
  void dispose() {
    _cukaiController.dispose();
    _hektarController.dispose();
    _hektarFocusNode.dispose();
    for (final division in _divisions) {
      division.dispose();
    }
    super.dispose();
  }

  void _updateCukai(String value) {
    setState(() => _cukai = double.tryParse(value) ?? 0);
  }

  void _updateHektar(String value) {
    setState(() => _hektar = double.tryParse(value) ?? 0);
  }

  void _addDivision() {
    if (_hektarController.text.trim().isEmpty) {
      _showSnackBar('Masukkan jumlah hektar dahulu.');
      _hektarFocusNode.requestFocus();
      return;
    }

    final totalFraction = _totalFraction;
    if (totalFraction >= 1 && _divisions.isNotEmpty) {
      _showSnackBar('Jumlah pecahan telah mencapai 100%.');
      return;
    }

    setState(() => _divisions.add(_QuickDivision()));
  }

  void _removeDivision(int index) {
    setState(() {
      final division = _divisions.removeAt(index);
      division.dispose();
    });
  }

  void _reset() {
    setState(() {
      _cukaiController.clear();
      _hektarController.clear();
      _cukai = 0;
      _hektar = 0;
      for (final division in _divisions) {
        division.dispose();
      }
      _divisions.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  double get _totalFraction {
    return _divisions.fold(0.0, (sum, division) => sum + division.fraction);
  }

  bool get _canExport => _hektar > 0 && _divisions.isNotEmpty;

  void _showExportRequiredMessage() {
    _showSnackBar('Masukkan hektar dan sekurang-kurangnya satu pembahagian.');
  }

  Future<Uint8List> _buildPdfBytes() async {
    final doc = pw.Document();
    final totalFraction = _totalFraction;
    final totalEkar = _hektar * _factorEkar;
    final totalRelung = _hektar * _factorRelung;
    final totalKakiPersegi = _hektar * _factorKakiPersegi;
    final totalMeterPersegi = _hektar * _factorMeterPersegi;
    final totalTaxAllocated = _cukai * totalFraction;
    final remainingTax = _cukai - totalTaxAllocated;
    final timestamp = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F4ED)),
        children: [
          _pdfCell('Bahagian', bold: true),
          _pdfCell('Pecahan', bold: true),
          _pdfCell('Hektar', bold: true),
          _pdfCell('Ekar', bold: true),
          _pdfCell('Relung', bold: true),
          _pdfCell('Kaki Persegi', bold: true),
          _pdfCell('Meter Persegi', bold: true),
          _pdfCell('Cukai', bold: true),
        ],
      ),
      for (int index = 0; index < _divisions.length; index++)
        _buildPdfDivisionRow(index),
    ];

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 28),
          orientation: pw.PageOrientation.landscape,
        ),
        build: (context) => [
          pw.Text(
            'Kalkulator Pantas Pembahagian Tanah',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Dijana pada: $timestamp',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey500),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: rows,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Ringkasan',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey500),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(1.8),
            },
            children: [
              _buildPdfSummaryRow(
                'Jumlah Pecahan',
                '${totalFraction.toStringAsFixed(5)} (${(totalFraction * 100).toStringAsFixed(2)}%)',
              ),
              _buildPdfSummaryRow(
                'Baki Pecahan',
                totalFraction <= 1
                    ? '${(1 - totalFraction).toStringAsFixed(4)} (${((1 - totalFraction) * 100).toStringAsFixed(2)}%)'
                    : 'Melebihi 100%',
              ),
              _buildPdfSummaryRow('Jumlah Hektar', _hektar.toStringAsFixed(7)),
              _buildPdfSummaryRow('Ekar', totalEkar.toStringAsFixed(7)),
              _buildPdfSummaryRow('Relung', totalRelung.toStringAsFixed(7)),
              _buildPdfSummaryRow(
                'Kaki Persegi',
                totalKakiPersegi.toStringAsFixed(0),
              ),
              _buildPdfSummaryRow(
                'Meter Persegi',
                totalMeterPersegi.toStringAsFixed(0),
              ),
              if (_cukai > 0) ...[
                _buildPdfSummaryRow(
                  'Jumlah Cukai',
                  'RM ${_cukai.toStringAsFixed(2)}',
                ),
                _buildPdfSummaryRow(
                  'Cukai Diagih',
                  'RM ${totalTaxAllocated.toStringAsFixed(2)}',
                ),
                _buildPdfSummaryRow(
                  'Baki Cukai',
                  'RM ${remainingTax.toStringAsFixed(2)}',
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.TableRow _buildPdfDivisionRow(int index) {
    final division = _divisions[index];
    final fraction = division.fraction;
    final divisionHektar = _hektar * fraction;
    final divisionEkar = divisionHektar * _factorEkar;
    final divisionRelung = divisionHektar * _factorRelung;
    final divisionKakiPersegi = divisionHektar * _factorKakiPersegi;
    final divisionMeterPersegi = divisionHektar * _factorMeterPersegi;
    final divisionTax = _cukai * fraction;
    final numerator = division.numeratorController.text.trim();
    final denominator = division.denominatorController.text.trim();
    final fractionText = numerator.isEmpty || denominator.isEmpty
        ? fraction.toStringAsFixed(10)
        : '$numerator/$denominator (${fraction.toStringAsFixed(10)})';

    return pw.TableRow(
      children: [
        _pdfCell('${index + 1}'),
        _pdfCell(fractionText),
        _pdfCell(divisionHektar.toStringAsFixed(7)),
        _pdfCell(divisionEkar.toStringAsFixed(7)),
        _pdfCell(divisionRelung.toStringAsFixed(7)),
        _pdfCell(divisionKakiPersegi.toStringAsFixed(0)),
        _pdfCell(divisionMeterPersegi.toStringAsFixed(0)),
        _pdfCell('RM ${divisionTax.toStringAsFixed(2)}'),
      ],
    );
  }

  pw.TableRow _buildPdfSummaryRow(String label, String value) {
    return pw.TableRow(
      children: [_pdfCell(label, bold: true), _pdfCell(value)],
    );
  }

  static pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (!_canExport) {
      _showExportRequiredMessage();
      return;
    }

    final bytes = await _buildPdfBytes();
    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'kalkulator_pantas_pembahagian.pdf',
    );
  }

  Future<void> _sharePdf() async {
    if (!_canExport) {
      _showExportRequiredMessage();
      return;
    }

    final bytes = await _buildPdfBytes();
    if (!mounted) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'kalkulator_pantas_pembahagian.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _QuickTanahCalcState.isDark(context);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: _QuickTanahCalcState.background(context),
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xFF66BB6A) : _primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: _QuickTanahCalcState.surface(context),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: _QuickTanahCalcState.surface(context),
        labelStyle: TextStyle(color: _QuickTanahCalcState.mutedText(context)),
        hintStyle: TextStyle(
          color: _QuickTanahCalcState.mutedText(
            context,
          ).withValues(alpha: 0.75),
        ),
        prefixIconColor: _QuickTanahCalcState.accent(context),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _QuickTanahCalcState.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: _QuickTanahCalcState.accent(context),
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );

    final totalFraction = _totalFraction;
    final totalEkar = _hektar * _factorEkar;
    final totalRelung = _hektar * _factorRelung;
    final totalKakiPersegi = _hektar * _factorKakiPersegi;
    final totalMeterPersegi = _hektar * _factorMeterPersegi;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _QuickTanahCalcState.surface(context),
          foregroundColor: _QuickTanahCalcState.strongText(context),
          surfaceTintColor: _QuickTanahCalcState.surface(context),
          title: const Text(
            'Kalkulator Pantas',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: 'Generate PDF',
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: _generatePdf,
            ),
            IconButton(
              tooltip: 'Share PDF',
              icon: const Icon(Icons.share_rounded),
              onPressed: _sharePdf,
            ),
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reset,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addDivision,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;
            final horizontalPadding = isWide ? 28.0 : 16.0;
            final summary = _SummarySection(
              totalFraction: totalFraction,
              totalEkar: totalEkar,
              totalRelung: totalRelung,
              totalKakiPersegi: totalKakiPersegi,
              totalMeterPersegi: totalMeterPersegi,
              totalTaxAllocated: _cukai * totalFraction,
              remainingTax: _cukai - (_cukai * totalFraction),
              hasTax: _cukai > 0,
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
                      _QuickHeader(
                        totalFraction: totalFraction,
                        divisionCount: _divisions.length,
                      ),
                      const SizedBox(height: 18),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _InputSection(
                                    cukaiController: _cukaiController,
                                    hektarController: _hektarController,
                                    hektarFocusNode: _hektarFocusNode,
                                    onCukaiChanged: _updateCukai,
                                    onHektarChanged: _updateHektar,
                                  ),
                                  const SizedBox(height: 16),
                                  _DivisionSection(
                                    divisions: _divisions,
                                    hektar: _hektar,
                                    cukai: _cukai,
                                    onAdd: _addDivision,
                                    onRemove: _removeDivision,
                                    onChanged: () => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(flex: 4, child: summary),
                          ],
                        )
                      else ...[
                        _InputSection(
                          cukaiController: _cukaiController,
                          hektarController: _hektarController,
                          hektarFocusNode: _hektarFocusNode,
                          onCukaiChanged: _updateCukai,
                          onHektarChanged: _updateHektar,
                        ),
                        const SizedBox(height: 16),
                        _DivisionSection(
                          divisions: _divisions,
                          hektar: _hektar,
                          cukai: _cukai,
                          onAdd: _addDivision,
                          onRemove: _removeDivision,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        summary,
                      ],
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
}

class _QuickHeader extends StatelessWidget {
  const _QuickHeader({
    required this.totalFraction,
    required this.divisionCount,
  });

  final double totalFraction;
  final int divisionCount;

  @override
  Widget build(BuildContext context) {
    final isComplete = (totalFraction - 1).abs() < 0.000001;
    final isOver = totalFraction > 1;
    final progress = totalFraction.clamp(0.0, 1.0);

    return _ModernSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.speed_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kiraan Pantas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _QuickTanahCalcState.strongText(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$divisionCount bahagian, tanpa simpan rekod',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _QuickTanahCalcState.mutedText(context),
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
              backgroundColor: _QuickTanahCalcState.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver
                    ? Colors.redAccent
                    : _QuickTanahCalcState.accent(context),
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
                        : _QuickTanahCalcState.mutedText(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(totalFraction * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  color: _QuickTanahCalcState.strongText(context),
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
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.cukaiController,
    required this.hektarController,
    required this.hektarFocusNode,
    required this.onCukaiChanged,
    required this.onHektarChanged,
  });

  final TextEditingController cukaiController;
  final TextEditingController hektarController;
  final FocusNode hektarFocusNode;
  final ValueChanged<String> onCukaiChanged;
  final ValueChanged<String> onHektarChanged;

  @override
  Widget build(BuildContext context) {
    return _ModernSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'Asas Kiraan', icon: Icons.tune_rounded),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final fieldWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _NumberField(
                      controller: cukaiController,
                      label: 'Jumlah Cukai',
                      hint: 'cth: 1200.00',
                      prefixText: 'RM ',
                      icon: Icons.payments_outlined,
                      onChanged: onCukaiChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _NumberField(
                      controller: hektarController,
                      focusNode: hektarFocusNode,
                      label: 'Jumlah Hektar',
                      hint: 'cth: 1.5',
                      icon: Icons.landscape_outlined,
                      onChanged: onHektarChanged,
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
}

class _DivisionSection extends StatelessWidget {
  const _DivisionSection({
    required this.divisions,
    required this.hektar,
    required this.cukai,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_QuickDivision> divisions;
  final double hektar;
  final double cukai;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _ModernSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'Quick Add Pembahagian',
            icon: Icons.call_split_outlined,
            trailing: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            ),
          ),
          const SizedBox(height: 14),
          if (divisions.isEmpty)
            _EmptyQuickState(onAdd: onAdd)
          else
            Column(
              children: [
                for (int index = 0; index < divisions.length; index++) ...[
                  _QuickDivisionCard(
                    index: index,
                    division: divisions[index],
                    hektar: hektar,
                    cukai: cukai,
                    onRemove: () => onRemove(index),
                    onChanged: onChanged,
                  ),
                  if (index != divisions.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _QuickDivisionCard extends StatelessWidget {
  const _QuickDivisionCard({
    required this.index,
    required this.division,
    required this.hektar,
    required this.cukai,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _QuickDivision division;
  final double hektar;
  final double cukai;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final fraction = division.fraction;
    final divisionHektar = hektar * fraction;
    final divisionEkar = divisionHektar * _QuickTanahCalcState._factorEkar;
    final divisionRelung = divisionHektar * _QuickTanahCalcState._factorRelung;
    final divisionKakiPersegi =
        divisionHektar * _QuickTanahCalcState._factorKakiPersegi;
    final divisionMeterPersegi =
        divisionHektar * _QuickTanahCalcState._factorMeterPersegi;
    final divisionTax = cukai * fraction;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _QuickTanahCalcState.surface(context),
        border: Border.all(color: _QuickTanahCalcState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _NumberBadge(value: index + 1),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bahagian ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _QuickTanahCalcState.strongText(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hapus bahagian',
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.redAccent,
                onPressed: onRemove,
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
                    child: _NumberField(
                      controller: division.numeratorController,
                      label: 'Pembilang',
                      hint: 'cth: 1',
                      icon: Icons.exposure_plus_1_outlined,
                      onChanged: (_) => onChanged(),
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
                    child: _NumberField(
                      controller: division.denominatorController,
                      label: 'Penyebut',
                      hint: 'cth: 8',
                      icon: Icons.exposure_zero_outlined,
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _OutputTable(
            rows: [
              _OutputRow('Pecahan', fraction.toStringAsFixed(10)),
              _OutputRow('Cukai', 'RM ${divisionTax.toStringAsFixed(2)}'),
              _OutputRow('Hektar', divisionHektar.toStringAsFixed(7)),
              _OutputRow('Ekar', divisionEkar.toStringAsFixed(7)),
              _OutputRow('Relung', divisionRelung.toStringAsFixed(7)),
              _OutputRow(
                'Kaki Persegi',
                divisionKakiPersegi.toStringAsFixed(0),
              ),
              _OutputRow(
                'Meter Persegi',
                divisionMeterPersegi.toStringAsFixed(0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.totalFraction,
    required this.totalEkar,
    required this.totalRelung,
    required this.totalKakiPersegi,
    required this.totalMeterPersegi,
    required this.totalTaxAllocated,
    required this.remainingTax,
    required this.hasTax,
  });

  final double totalFraction;
  final double totalEkar;
  final double totalRelung;
  final double totalKakiPersegi;
  final double totalMeterPersegi;
  final double totalTaxAllocated;
  final double remainingTax;
  final bool hasTax;

  @override
  Widget build(BuildContext context) {
    return _ModernSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'Output Ringkas', icon: Icons.insights),
          const SizedBox(height: 14),
          _OutputTable(
            rows: [
              _OutputRow(
                'Jumlah Pecahan',
                '${totalFraction.toStringAsFixed(5)} (${(totalFraction * 100).toStringAsFixed(2)}%)',
              ),
              _OutputRow(
                'Baki Pecahan',
                totalFraction <= 1
                    ? '${(1 - totalFraction).toStringAsFixed(4)} (${((1 - totalFraction) * 100).toStringAsFixed(2)}%)'
                    : 'Melebihi 100%',
                isWarning: totalFraction > 1,
              ),
              _OutputRow('Ekar', totalEkar.toStringAsFixed(7)),
              _OutputRow('Relung', totalRelung.toStringAsFixed(7)),
              _OutputRow('Kaki Persegi', totalKakiPersegi.toStringAsFixed(0)),
              _OutputRow('Meter Persegi', totalMeterPersegi.toStringAsFixed(0)),
              if (hasTax) ...[
                _OutputRow(
                  'Cukai Diagih',
                  'RM ${totalTaxAllocated.toStringAsFixed(2)}',
                ),
                _OutputRow(
                  'Baki Cukai',
                  'RM ${remainingTax.toStringAsFixed(2)}',
                  isWarning: remainingTax < 0,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernSurface extends StatelessWidget {
  const _ModernSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _QuickTanahCalcState.surface(context),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _QuickTanahCalcState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, this.trailing});

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBox(icon: icon, size: 36, iconSize: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _QuickTanahCalcState.strongText(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.size = 46, this.iconSize = 24});

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _QuickTanahCalcState.softSurface(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: _QuickTanahCalcState.accent(context),
        size: iconSize,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.focusNode,
    this.prefixText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _QuickTanahCalcState.softSurface(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: _QuickTanahCalcState.accent(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OutputTable extends StatelessWidget {
  const _OutputTable({required this.rows});

  final List<_OutputRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _QuickTanahCalcState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.15),
          1: FlexColumnWidth(1.45),
        },
        border: TableBorder(
          horizontalInside: BorderSide(
            color: _QuickTanahCalcState.border(context),
          ),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: _QuickTanahCalcState.softSurface(context),
            ),
            children: [
              _OutputCell('Output', isHeader: true),
              _OutputCell('Nilai', isHeader: true, alignEnd: true),
            ],
          ),
          for (final row in rows)
            TableRow(
              decoration: BoxDecoration(
                color: row.isWarning
                    ? Colors.redAccent.withValues(alpha: 0.08)
                    : _QuickTanahCalcState.surface(context),
              ),
              children: [
                _OutputCell(row.label, isWarning: row.isWarning),
                _OutputCell(
                  row.value,
                  alignEnd: true,
                  isStrong: true,
                  isWarning: row.isWarning,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OutputCell extends StatelessWidget {
  const _OutputCell(
    this.text, {
    this.alignEnd = false,
    this.isHeader = false,
    this.isStrong = false,
    this.isWarning = false,
  });

  final String text;
  final bool alignEnd;
  final bool isHeader;
  final bool isStrong;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? Colors.redAccent
        : isHeader || isStrong
        ? _QuickTanahCalcState.strongText(context)
        : _QuickTanahCalcState.mutedText(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: TextStyle(
          color: color,
          fontWeight: isHeader || isStrong ? FontWeight.w800 : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _OutputRow {
  const _OutputRow(this.label, this.value, {this.isWarning = false});

  final String label;
  final String value;
  final bool isWarning;
}

class _EmptyQuickState extends StatelessWidget {
  const _EmptyQuickState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: _QuickTanahCalcState.background(context),
        border: Border.all(color: _QuickTanahCalcState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flash_on_outlined,
            size: 38,
            color: _QuickTanahCalcState.accent(context),
          ),
          const SizedBox(height: 10),
          Text(
            'Tambah pecahan pertama',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _QuickTanahCalcState.strongText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan pembilang dan penyebut untuk lihat output terus.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _QuickTanahCalcState.mutedText(context),
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

class _QuickDivision {
  _QuickDivision();

  final TextEditingController numeratorController = TextEditingController();
  final TextEditingController denominatorController = TextEditingController();

  double get fraction {
    final numerator = double.tryParse(numeratorController.text) ?? 0;
    final denominator = double.tryParse(denominatorController.text) ?? 1;
    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  void dispose() {
    numeratorController.dispose();
    denominatorController.dispose();
  }
}
