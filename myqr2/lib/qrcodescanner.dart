import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myqr2/ScanHistoryItem.dart';
import 'package:myqr2/qr_history_screen.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter_contacts/flutter_contacts.dart' as contacts;

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrText;
  String qrType = '';

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) {
      if (mounted && qrText == null) {
        controller?.pauseCamera();
        setState(() {
          qrText = scanData.code;
          qrType = _detectType(qrText!);
          _saveToHistory(qrText!, qrType);
        });
        _showActionSheet();
      }
    });
  }

  String _detectType(String data) {
    final uri = Uri.tryParse(data);
    if (data.toLowerCase().startsWith('http')) return 'Link';
    if (data.toLowerCase().startsWith('mailto:')) return 'Email';
    if (data.toLowerCase().startsWith('tel:')) return 'Phone Number';
    if (data.contains('BEGIN:VCARD')) return 'Contact';
    if (data.contains('BEGIN:VEVENT')) return 'Event/Calendar';
    if (data.contains('Street') ||
        data.contains('Jalan') ||
        data.contains('Ave'))
      return 'Address';
    if (uri != null && uri.scheme.isNotEmpty) return 'Link';
    return 'Text';
  }

  void _restartScan() {
    controller?.resumeCamera();
    setState(() {
      qrText = null;
      qrType = '';
    });
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<Widget> actions = [];

        switch (qrType) {
          case 'Link':
            actions.add(
              _buildSheetButton('Open Link', Icons.link, () {
                launchUrl(
                  Uri.parse(qrText!),
                  mode: LaunchMode.externalApplication,
                );
                Navigator.pop(context);
              }),
            );
            break;

          case 'Phone Number':
            actions.add(
              _buildSheetButton('Call Number', Icons.phone, () {
                launchUrl(Uri.parse(qrText!));
                Navigator.pop(context);
              }),
            );
            break;

          case 'Email':
            actions.add(
              _buildSheetButton('Send Email', Icons.email, () {
                launchUrl(Uri.parse(qrText!));
                Navigator.pop(context);
              }),
            );
            break;

          case 'Contact':
            actions.add(
              _buildSheetButton('Save Contact', Icons.person_add, () async {
                if (await Permission.contacts.request().isGranted) {
                  final lines = qrText!.split('\n');
                  final name =
                      lines
                          .firstWhere((l) => l.contains('FN:'))
                          .split(':')
                          .last
                          .trim();
                  final telLine = lines.firstWhere(
                    (l) => l.contains('TEL:'),
                    orElse: () => '',
                  );
                  final phone =
                      telLine.isNotEmpty ? telLine.split(':').last.trim() : '';
                  if (await contacts.FlutterContacts.requestPermission()) {
                    // Build contact
                    final contact =
                        contacts.Contact()
                          ..name.first = name
                          ..phones =
                              phone.isNotEmpty
                                  ? [
                                    contacts.Phone(
                                      phone,
                                      label: contacts.PhoneLabel.mobile,
                                    ),
                                  ]
                                  : [];

                    // Save to contacts
                    await contacts.FlutterContacts.insertContact(contact);

                    // Go back to previous screen
                    Navigator.pop(context);
                  } else {
                    // Show permission denied message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Permission to access contacts denied'),
                      ),
                    );
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contact saved!")),
                  );
                }
              }),
            );
            break;

          case 'Address':
            actions.add(
              _buildSheetButton('Open in Maps', Icons.map, () {
                final encoded = Uri.encodeComponent(qrText!);
                final mapUrl =
                    'https://www.google.com/maps/search/?api=1&query=$encoded';
                launchUrl(Uri.parse(mapUrl));
                Navigator.pop(context);
              }),
            );
            break;

          case 'Event/Calendar':
            actions.add(
              _buildSheetButton('Add to Calendar', Icons.calendar_today, () {
                final now = DateTime.now();
                final event = calendar.Event(
                  title: 'Scanned QR Event',
                  description: qrText!,
                  location: 'QR Location',
                  startDate: now,
                  endDate: now.add(const Duration(hours: 1)),
                );
                calendar.Add2Calendar.addEvent2Cal(event);
                Navigator.pop(context);
              }),
            );
            break;

          default:
            actions.add(
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No specific action available for this QR type."),
              ),
            );
        }

        actions.add(
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartScan();
            },
            child: const Text('Scan Another'),
          ),
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: actions),
          ),
        );
      },
    );
  }

  Future<void> _saveToHistory(String data, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('scan_history') ?? [];

    final newItem = ScanHistoryItem(
      data: data,
      type: type,
      timestamp: DateTime.now(),
    );

    history.add(jsonEncode(newItem.toJson()));

    // Limit to last 50 scans
    if (history.length > 50) {
      history.removeAt(0);
    }

    await prefs.setStringList('scan_history', history);
  }

  Widget _buildSheetButton(String label, IconData icon, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        actions: [
          if (qrText != null)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              onPressed: _restartScan,
              tooltip: 'Rescan',
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: theme.primaryColor,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 8,
                  cutOutSize: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child:
                  qrText == null
                      ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Scan a QR code to see the result',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 12),
                          CircularProgressIndicator(),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Scanned Result",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Type: $qrType",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                qrText!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showActionSheet,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("Take Action"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
