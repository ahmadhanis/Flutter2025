import 'package:flutter/material.dart';
import 'dart:math';

class KiraLuasPepenjuru extends StatefulWidget {
  const KiraLuasPepenjuru({super.key});

  @override
  State<KiraLuasPepenjuru> createState() => _KiraLuasPepenjuruState();
}

class _KiraLuasPepenjuruState extends State<KiraLuasPepenjuru> {
  final List<int> _penjuruOptions = [3, 4, 5, 6, 7, 8];
  int _selectedPenjuru = 3;
  List<TextEditingController> _lengthControllers = [];

  final List<Color> _lineColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
  ];

  // Conversion factors (from Meter Persegi)
  final double factorHektar = 1 / 10000;
  final double factorEkar = 1 / 4046.86;
  final double factorRelung = 1 / 2887.5;
  final double factorKakiPersegi = 10.7639;

  @override
  void initState() {
    super.initState();
    _initializeLengthControllers();
  }

  void _initializeLengthControllers() {
    _lengthControllers = List.generate(_selectedPenjuru, (index) => TextEditingController());
  }

  void _updatePenjuru(int value) {
    setState(() {
      _selectedPenjuru = value;
      _initializeLengthControllers();
    });
  }

  double _calculateArea() {
    if (_lengthControllers.any((controller) => controller.text.isEmpty)) return 0.0;

    List<double> sides = _lengthControllers.map((c) => double.tryParse(c.text) ?? 0).toList();

    if (_selectedPenjuru == 3) {
      // Heron's formula for triangle
      double s = (sides[0] + sides[1] + sides[2]) / 2;
      return sqrt(s * (s - sides[0]) * (s - sides[1]) * (s - sides[2]));
    } else {
      // Approximate polygon area formula using perimeter * apothem / 2
      double perimeter = sides.reduce((a, b) => a + b);
      double apothem = sides[0] / (2 * tan(pi / _selectedPenjuru));
      return (perimeter * apothem) / 2;
    }
  }

  @override
  void dispose() {
    for (var controller in _lengthControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double areaMeterPersegi = _calculateArea();
    double areaHektar = areaMeterPersegi * factorHektar;
    double areaEkar = areaMeterPersegi * factorEkar;
    double areaRelung = areaMeterPersegi * factorRelung;
    double areaKakiPersegi = areaMeterPersegi * factorKakiPersegi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kira Luas Penjuru'),
         backgroundColor: Colors.lightGreen,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown for number of corners
            DropdownButtonFormField<int>(
              initialValue: _selectedPenjuru,
              decoration: InputDecoration(
                labelText: 'Pilih Jumlah Penjuru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              items: _penjuruOptions.map((penjuru) {
                return DropdownMenuItem(value: penjuru, child: Text('$penjuru Penjuru'));
              }).toList(),
              onChanged: (value) {
                _updatePenjuru(value!);
              },
            ),
            const SizedBox(height: 16),

            // Length inputs for each side (always in meters)
            Column(
              children: List.generate(_selectedPenjuru, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: _lengthControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Panjang Sisi ${index + 1} (Meter)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      filled: true,
                      fillColor: _lineColors[index % _lineColors.length].withOpacity(0.2),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => setState(() {}),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Drawing the polygon (Scaled Proportionally)
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: PolygonPainter(_selectedPenjuru, _lengthControllers, _lineColors),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Area Calculation Results
            Text(
              'Luas Kawasan:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _buildConversionRow('Meter Persegi', areaMeterPersegi.toStringAsFixed(7)),
            _buildConversionRow('Hektar', areaHektar.toStringAsFixed(7)),
            _buildConversionRow('Ekar', areaEkar.toStringAsFixed(7)),
            _buildConversionRow('Relung', areaRelung.toStringAsFixed(7)),
            _buildConversionRow('Kaki Persegi', areaKakiPersegi.toStringAsFixed(7)),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final int sides;
  final List<TextEditingController> lengthControllers;
  final List<Color> lineColors;

  PolygonPainter(this.sides, this.lengthControllers, this.lineColors);

  @override
  void paint(Canvas canvas, Size size) {
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double maxLength = lengthControllers.map((c) => double.tryParse(c.text) ?? 0).reduce((a, b) => a > b ? a : b);
    double scaleFactor = (size.width / 2.2) / (maxLength > 0 ? maxLength : 1);

    List<Offset> points = [];

    for (int i = 0; i < sides; i++) {
      double angle = (2 * pi / sides) * i;
      double length = (double.tryParse(lengthControllers[i].text) ?? maxLength) * scaleFactor;
      double x = centerX + length * cos(angle);
      double y = centerY + length * sin(angle);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < sides; i++) {
      Paint paint = Paint()
        ..color = lineColors[i % lineColors.length]
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(points[i], points[(i + 1) % sides], paint);
    }
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) => true;
}
