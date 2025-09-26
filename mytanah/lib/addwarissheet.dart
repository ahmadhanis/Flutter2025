import 'package:flutter/material.dart';
import 'package:mytanah/inlineswitch.dart';
import 'package:mytanah/models/FaraidMember.dart';
import 'package:mytanah/models/enums.dart';
import 'package:mytanah/myfaraidcalc.dart';

class AddWarisSheet extends StatefulWidget {
  AddWarisSheet({required this.onSubmit});
  final void Function(FaraidMember member) onSubmit;

  @override
  State<AddWarisSheet> createState() => _AddWarisSheetState();
}

class _AddWarisSheetState extends State<AddWarisSheet> {
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
                InlineSwitch(
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
}
