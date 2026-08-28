import 'package:flutter/material.dart';
import 'package:mytanah/division.dart';
import 'package:mytanah/mytanahcalc.dart';
import 'sqlite_helper.dart';

class ViewTanahScreen extends StatefulWidget {
  const ViewTanahScreen({super.key});

  @override
  State<ViewTanahScreen> createState() => _ViewTanahScreenState();
}

class _ViewTanahScreenState extends State<ViewTanahScreen> {
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

  late Future<List<Map<String, dynamic>>> _tanahList;

  @override
  void initState() {
    super.initState();
    _loadTanah();
  }

  void _loadTanah() {
    _tanahList = SQLiteHelper().getAllTanah();
    setState(() {});
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        title: const Text('Padam Semua Data?'),
        content: const Text(
          'Adakah anda pasti ingin menghapus semua maklumat tanah? Tindakan ini tidak boleh diundur.',
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.close_rounded),
            label: const Text('Batal'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Padam'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await SQLiteHelper().deleteAllData();
              if (!mounted) return;
              Navigator.pop(context);
              _loadTanah();
              _showSnackBar('Semua rekod telah dipadam.');
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSingle(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        title: const Text('Padam Maklumat Ini?'),
        content: const Text('Adakah anda pasti ingin menghapus maklumat ini?'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.close_rounded),
            label: const Text('Batal'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Padam'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await SQLiteHelper().deleteGeranAndPembahagianById(id);
              if (!mounted) return;
              Navigator.pop(context);
              _loadTanah();
              _showSnackBar('Rekod telah dipadam.');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openRecord(Map<String, dynamic> tanah) async {
    final pembahagianList = await SQLiteHelper().getPembahagianByGeranId(
      tanah['id'],
    );
    if (!mounted) return;

    final divisions = pembahagianList.map<Division>((e) {
      return Division(
        numerator: e['pembilang'].toString(),
        denominator: e['penyebut'].toString(),
      );
    }).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyTanahCal(
          noGeran: tanah['no_geran'],
          noLot: tanah['no_lot'],
          cukai: double.tryParse(tanah['jumlah_cukai'].toString()),
          hektar: double.tryParse(tanah['jumlah_hektar'].toString()),
          divisions: divisions,
          pembahagianList: pembahagianList,
        ),
      ),
    );
    if (!mounted) return;
    _loadTanah();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _ViewTanahScreenState.isDark(context);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: _ViewTanahScreenState.background(context),
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xFF66BB6A) : _primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: _ViewTanahScreenState.surface(context),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _ViewTanahScreenState.surface(context),
          foregroundColor: _ViewTanahScreenState.strongText(context),
          surfaceTintColor: _ViewTanahScreenState.surface(context),
          title: const Text(
            'Senarai Geran',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: 'Muat semula',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadTanah,
            ),
            IconButton(
              tooltip: 'Padam semua',
              icon: const Icon(Icons.delete_forever_outlined),
              onPressed: _confirmDeleteAll,
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _tanahList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredState(
                icon: Icons.hourglass_empty_rounded,
                title: 'Memuatkan rekod',
                message: 'Sila tunggu sebentar.',
                showProgress: true,
              );
            }

            if (snapshot.hasError) {
              return _CenteredState(
                icon: Icons.error_outline_rounded,
                title: 'Ralat memuatkan rekod',
                message: snapshot.error.toString(),
              );
            }

            final data = snapshot.data;

            if (data == null || data.isEmpty) {
              return const _CenteredState(
                icon: Icons.folder_open_outlined,
                title: 'Tiada rekod geran',
                message: 'Rekod yang disimpan akan dipaparkan di sini.',
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final horizontalPadding = isWide ? 28.0 : 16.0;

                return RefreshIndicator(
                  onRefresh: () async => _loadTanah(),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      28,
                    ),
                    itemCount: data.length + 1,
                    separatorBuilder: (_, index) =>
                        SizedBox(height: index == 0 ? 16 : 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 920),
                            child: _RecordsHeader(total: data.length),
                          ),
                        );
                      }

                      final tanah = data[index - 1];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: _RecordCard(
                            tanah: tanah,
                            onOpen: () => _openRecord(tanah),
                            onDelete: () => _confirmDeleteSingle(tanah['id']),
                          ),
                        ),
                      );
                    },
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

class _RecordsHeader extends StatelessWidget {
  const _RecordsHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ViewTanahScreenState.surface(context),
        border: Border.all(color: _ViewTanahScreenState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _ViewTanahScreenState.softSurface(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_copy_outlined,
              color: _ViewTanahScreenState.accent(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekod Geran',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _ViewTanahScreenState.strongText(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$total rekod tersimpan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ViewTanahScreenState.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.tanah,
    required this.onOpen,
    required this.onDelete,
  });

  final Map<String, dynamic> tanah;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final noGeran = tanah['no_geran']?.toString() ?? '-';
    final noLot = tanah['no_lot']?.toString() ?? '-';
    final cukai = double.tryParse(tanah['jumlah_cukai'].toString()) ?? 0;
    final hektar = double.tryParse(tanah['jumlah_hektar'].toString()) ?? 0;

    return Material(
      color: _ViewTanahScreenState.surface(context),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _ViewTanahScreenState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _ViewTanahScreenState.softSurface(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      color: _ViewTanahScreenState.accent(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geran: $noGeran',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _ViewTanahScreenState.strongText(
                                  context,
                                ),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lot: $noLot',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _ViewTanahScreenState.mutedText(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Padam',
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: Colors.redAccent,
                    onPressed: onDelete,
                  ),
                  IconButton(
                    tooltip: 'Lihat butiran',
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: _ViewTanahScreenState.accent(context),
                    onPressed: onOpen,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(
                    icon: Icons.landscape_outlined,
                    label: 'Hektar',
                    value: hektar.toStringAsFixed(4),
                  ),
                  _MetricChip(
                    icon: Icons.payments_outlined,
                    label: 'Cukai',
                    value: 'RM ${cukai.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _ViewTanahScreenState.background(context),
        border: Border.all(color: _ViewTanahScreenState.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _ViewTanahScreenState.accent(context)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: _ViewTanahScreenState.mutedText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _ViewTanahScreenState.strongText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 42,
                color: _ViewTanahScreenState.accent(context),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _ViewTanahScreenState.strongText(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _ViewTanahScreenState.mutedText(context),
                ),
              ),
              if (showProgress) ...[
                const SizedBox(height: 18),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
