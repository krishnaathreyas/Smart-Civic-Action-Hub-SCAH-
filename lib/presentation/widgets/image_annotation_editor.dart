// presentation/widgets/image_annotation_editor.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ImageAnnotationEditor extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageAnnotationEditor({super.key, required this.imageBytes});

  @override
  State<ImageAnnotationEditor> createState() => _ImageAnnotationEditorState();
}

class _Stroke {
  _Stroke(this.points, this.color, this.width);
  final List<Offset> points;
  final Color color;
  final double width;
}

class _ImageAnnotationEditorState extends State<ImageAnnotationEditor> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  Color _currentColor = Colors.red;
  double _currentWidth = 4.0;

  void _onPanStart(DragStartDetails details) {
    final box = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final point = box.globalToLocal(details.globalPosition);
    setState(
      () => _strokes.add(_Stroke([point], _currentColor, _currentWidth)),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || _strokes.isEmpty) return;
    final point = box.globalToLocal(details.globalPosition);
    setState(() => _strokes.last.points.add(point));
  }

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  void _clear() {
    if (_strokes.isNotEmpty) setState(() => _strokes.clear());
  }

  Future<void> _save() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(bytes);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotate Photo'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: _clear,
            icon: const Icon(Icons.layers_clear),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 8),
                _colorDot(Colors.red),
                _colorDot(Colors.blue),
                _colorDot(Colors.green),
                _colorDot(Colors.yellow.shade700),
                _colorDot(Colors.black),
                const Spacer(),
                Slider(
                  value: _currentWidth,
                  min: 2,
                  max: 12,
                  divisions: 5,
                  label: _currentWidth.toStringAsFixed(0),
                  onChanged: (v) => setState(() => _currentWidth = v),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.memory(widget.imageBytes, fit: BoxFit.contain),
                      CustomPaint(
                        painter: _AnnotationPainter(_strokes),
                        size: Size.infinite,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    final selected = _currentColor.value == color.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => setState(() => _currentColor = color),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.grey.shade300,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _AnnotationPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (int i = 0; i < s.points.length - 1; i++) {
        final p1 = s.points[i];
        final p2 = s.points[i + 1];
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
