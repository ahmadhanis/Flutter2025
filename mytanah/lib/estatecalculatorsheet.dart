import 'package:flutter/material.dart';
import 'package:mytanah/controllers/MembersController.dart';
import 'package:mytanah/controllers/amt.dart';
import 'package:mytanah/models/enums.dart';

class EstateCalculatorSheet extends StatefulWidget {
  final MembersController ctrl;
  const EstateCalculatorSheet({super.key, required this.ctrl});

  @override
  State<EstateCalculatorSheet> createState() => _EstateCalculatorSheetState();
}

class _EstateCalculatorSheetState extends State<EstateCalculatorSheet> {
  late final List<Amt> takAlih;
  late final List<Amt> alih;
  late final List<Amt> potongan;

  @override
  void initState() {
    super.initState();
    takAlih = [Amt('Tanah'), Amt('Rumah'), Amt('Bangunan')];
    alih = [
      Amt('Kenderaan'),
      Amt('Tabung Haji / TH'),
      Amt('Simpanan / Saving'),
      Amt('KWSP / EPF'),
      Amt('Hasil Sewa'),
      Amt('Pelaburan / Investment'),
      Amt('Saham / Unit Trust'),
      Amt('Emas / Gold'),
      Amt('Lain-lain Aset'),
    ];
    potongan = [
      Amt('Hutang'),
      Amt('Kos Pengkebumian'),
      Amt('Zakat/Cukai Tertunggak'),
      Amt('Wasiat (≤ 1/3)'),
      Amt('Lain-lain Potongan'),
    ];
  }

  double sumList(List<Amt> xs) => xs.fold(0.0, (s, x) => s + x.v);

  @override
  void dispose() {
    for (final a in [...takAlih, ...alih, ...potongan]) {
      a.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void recalc() => setState(() {});
    final totalTakAlih = sumList(takAlih);
    final totalAlih = sumList(alih);
    final totalPotongan = sumList(potongan);
    final grandTotal = (totalTakAlih + totalAlih) - totalPotongan;

    InputDecoration dec(String label) =>
        InputDecoration(labelText: label, prefixText: 'RM ', isDense: true);

    Widget moneyField(Amt a) => TextField(
      controller: a.c,
      decoration: dec(a.label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => recalc(),
    );

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
          // Header
          Row(
            children: [
              const Icon(Icons.calculate_outlined),
              const SizedBox(width: 8),
              Text(
                'Kalkulator Pusaka Bersih',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Body
          Expanded(
            child: ListView(
              children: [
                _sectionHeader(context, 'Harta Tak Alih'),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: takAlih
                      .map((a) => SizedBox(width: 280, child: moneyField(a)))
                      .toList(),
                ),
                _totChip(
                  context: context,
                  label: 'Jumlah Harta Tak Alih',
                  value: totalTakAlih,
                ),
                const SizedBox(height: 14),
                _sectionHeader(context, 'Harta Alih'),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: alih
                      .map((a) => SizedBox(width: 280, child: moneyField(a)))
                      .toList(),
                ),
                _totChip(
                  context: context,
                  label: 'Jumlah Harta Alih',
                  value: totalAlih,
                ),
                const SizedBox(height: 14),
                _sectionHeader(context, 'Potongan (Opsyenal)'),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: potongan
                      .map((a) => SizedBox(width: 280, child: moneyField(a)))
                      .toList(),
                ),
                _totChip(
                  context: context,
                  label: 'Jumlah Potongan',
                  value: totalPotongan,
                ),
                const SizedBox(height: 14),
                _grandTotal(context, grandTotal),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Footer buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    for (final a in [...takAlih, ...alih, ...potongan]) {
                      a.c.clear();
                    }
                    recalc();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Borang'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (widget.ctrl.unit.value != AssetUnit.rm) {
                      Navigator.of(context).maybePop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unit bukan RM. Tukar ke RM untuk guna kalkulator ini.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop(grandTotal);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Guna Nilai Ini'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Icon(
          Icons.folder_outlined,
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
    );
  }

  Widget _totChip({
    required BuildContext context,
    required String label,
    required double value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.summarize_outlined, size: 16),
          label: Text('$label: RM ${value.toStringAsFixed(2)}'),
        ),
      ),
    );
  }

  Widget _grandTotal(BuildContext context, double total) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined),
          const SizedBox(width: 8),
          const Text('Pusaka Bersih'),
          const Spacer(),
          Text(
            'RM ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
