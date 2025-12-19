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
      builder: (context) => AlertDialog(
        title: const Text('Padam Semua Data?'),
        content: const Text(
          'Adakah anda pasti ingin menghapus semua maklumat tanah? Tindakan ini tidak boleh diundur.',
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Padam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await SQLiteHelper().deleteAllData();
              Navigator.pop(context);
              _loadTanah();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSingle(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Maklumat Ini?'),
        content: const Text('Adakah anda pasti ingin menghapus maklumat ini?'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Padam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await SQLiteHelper().deleteGeranAndPembahagianById(id);
              Navigator.pop(context);
              _loadTanah();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Senarai Geran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2D6A4F).withValues(alpha: 0.5),
        actions: [
          IconButton(
            tooltip: "Padam Semua",
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: _confirmDeleteAll,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tanahList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ralat: ${snapshot.error}'));
          }

          final data = snapshot.data;

          if (data == null || data.isEmpty) {
            return const Center(child: Text('Tiada data tanah buat masa ini.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final tanah = data[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    'Geran: ${tanah['no_geran']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Lot: ${tanah['no_lot']}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Padam',
                        onPressed: () => _confirmDeleteSingle(tanah['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Lihat Butiran',
                        onPressed: () async {
                          final pembahagianList = await SQLiteHelper()
                              .getPembahagianByGeranId(tanah['id']);

                          final divisions = pembahagianList.map<Division>((e) {
                            return Division(
                              numerator: e['pembilang'].toString(),
                              denominator: e['penyebut'].toString(),
                            );
                          }).toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyTanahCal(
                                noGeran: tanah['no_geran'],
                                noLot: tanah['no_lot'],
                                cukai: double.tryParse(
                                  tanah['jumlah_cukai'].toString(),
                                ),
                                hektar: double.tryParse(
                                  tanah['jumlah_hektar'].toString(),
                                ),
                                divisions: divisions,
                                pembahagianList: pembahagianList,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
