import 'package:flutter/material.dart';

class PusakaBersihSheet extends StatefulWidget {
  const PusakaBersihSheet({super.key});

  @override
  State<PusakaBersihSheet> createState() => _PusakaBersihSheetState();
}

class _PusakaBersihSheetState extends State<PusakaBersihSheet> {
  final TextEditingController _hartaController = TextEditingController();
  final TextEditingController _hutangController = TextEditingController();
  final TextEditingController _kosController = TextEditingController();

  double _bersih = 0;

  void _recalc() {
    final harta = double.tryParse(_hartaController.text) ?? 0;
    final hutang = double.tryParse(_hutangController.text) ?? 0;
    final kos = double.tryParse(_kosController.text) ?? 0;
    setState(() {
      _bersih = harta - hutang - kos;
    });
  }

  @override
  void dispose() {
    _hartaController.dispose();
    _hutangController.dispose();
    _kosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // keyboard-safe
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _hartaController,
            decoration: const InputDecoration(labelText: 'Harta'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _recalc(),
          ),
          TextField(
            controller: _hutangController,
            decoration: const InputDecoration(labelText: 'Hutang'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _recalc(),
          ),
          TextField(
            controller: _kosController,
            decoration: const InputDecoration(labelText: 'Kos'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _recalc(),
          ),
          const SizedBox(height: 12),
          Text('Pusaka Bersih: $_bersih'),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _bersih),
            child: const Text('Gunakan Nilai Ini'),
          ),
        ],
      ),
    );
  }
}
