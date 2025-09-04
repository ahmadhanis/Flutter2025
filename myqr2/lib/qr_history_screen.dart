import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myqr2/ScanHistoryItem.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrHistoryScreen extends StatefulWidget {
  const QrHistoryScreen({super.key});

  @override
  State<QrHistoryScreen> createState() => _QrHistoryScreenState();
}

class _QrHistoryScreenState extends State<QrHistoryScreen> {
  List<ScanHistoryItem> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyRaw = prefs.getStringList('scan_history') ?? [];

    setState(() {
      history =
          historyRaw
              .map((item) => ScanHistoryItem.fromJson(jsonDecode(item)))
              .toList()
              .reversed
              .toList();
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scan_history');
    setState(() {
      history = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body:
          history.isEmpty
              ? const Center(child: Text("No history yet."))
              : ListView.separated(
                itemCount: history.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(item.type),
                    subtitle: Text(item.data),
                    trailing: Text(
                      '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
    );
  }
}
