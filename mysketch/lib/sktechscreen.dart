import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';

class SketchScreen extends StatefulWidget {
  const SketchScreen({super.key});

  @override
  State<SketchScreen> createState() => _SketchScreenState();
}

class _SketchScreenState extends State<SketchScreen>
    with TickerProviderStateMixin {
  late SignatureController _controller;
  late TransformationController _zoomController;
  double _zoomScale = 1.0;
  Color _selectedColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _zoomController = TransformationController();
    _zoomController.addListener(() {
      final matrix = _zoomController.value;
      setState(() {
        _zoomScale = matrix.getMaxScaleOnAxis();
      });
    });

    _initController();
  }

  void _initController() {
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: _selectedColor,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _changeColor(Color color) {
    setState(() {
      _selectedColor = color;
      final oldPoints = _controller.points;
      _controller.dispose();
      _controller = SignatureController(
        penStrokeWidth: 3,
        penColor: _selectedColor,
        exportBackgroundColor: Colors.white,
      )..points = oldPoints;
    });
  }

  void _clear() => _controller.clear();

  void _save() async {
    if (_controller.isNotEmpty) {
      Uint8List? image = await _controller.toPngBytes();
      if (image != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Saved Drawing'),
            content: Image.memory(image),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))
            ],
          ),
        );
      }
    }
  }

  void _zoomIn() {
    _setZoom(_zoomScale + 0.25);
  }

  void _zoomOut() {
    _setZoom((_zoomScale - 0.25).clamp(1.0, 4.0));
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  void _setZoom(double newZoom) {
    final scale = newZoom.clamp(1.0, 4.0);
    _zoomController.value = Matrix4.identity()..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _resetZoom,
                child: InteractiveViewer(
                  transformationController: _zoomController,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Signature(
                      key: ValueKey(_controller),
                      controller: _controller,
                      backgroundColor: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            // Zoom overlay
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Zoom: ${_zoomScale.toStringAsFixed(1)}x",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            // Toolbar
            // Toolbar: Replace this section in build()
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Color buttons
                      Row(
                        children: [
                          _buildColorButton(Colors.black),
                          _buildColorButton(Colors.red),
                          _buildColorButton(Colors.blue),
                          _buildColorButton(Colors.green),
                          _buildColorButton(Colors.orange),
                          _buildColorButton(Colors.purple),
                          _buildColorButton(Colors.brown),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Action buttons
                      Row(
                        children: [
                          IconButton(
                              onPressed: _zoomOut,
                              icon: const Icon(Icons.zoom_out)),
                          IconButton(
                              onPressed: _zoomIn,
                              icon: const Icon(Icons.zoom_in)),
                          IconButton(
                              onPressed: _resetZoom,
                              icon: const Icon(Icons.center_focus_strong)),
                          IconButton(
                              onPressed: _clear,
                              icon: const Icon(Icons.refresh)),
                          IconButton(
                              onPressed: _save, icon: const Icon(Icons.save)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => _changeColor(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
