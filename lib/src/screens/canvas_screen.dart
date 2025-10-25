import 'package:flutter/material.dart';

import '../canvas/drawing_canvas.dart';
import '../canvas/stroke.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  List<Stroke> _strokes = <Stroke>[];
  Stroke? _inProgress;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4;

  void _startStroke(Offset position) {
    final Stroke stroke = Stroke(color: _selectedColor, width: _strokeWidth)
      ..addPoint(position);
    setState(() {
      _inProgress = stroke;
    });
  }

  void _appendPoint(Offset position) {
    if (_inProgress == null) {
      return;
    }
    setState(() {
      _inProgress!.addPoint(position);
    });
  }

  void _endStroke() {
    if (_inProgress == null || _inProgress!.isEmpty) {
      setState(() {
        _inProgress = null;
      });
      return;
    }
    setState(() {
      _strokes = List<Stroke>.from(_strokes)..add(_inProgress!);
      _inProgress = null;
    });
  }

  void _clearCanvas() {
    setState(() {
      _strokes = <Stroke>[];
      _inProgress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('드로잉 아이콘'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Container(
                  color: Colors.white,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (DragStartDetails details) =>
                        _startStroke(details.localPosition),
                    onPanUpdate: (DragUpdateDetails details) =>
                        _appendPoint(details.localPosition),
                    onPanEnd: (_) => _endStroke(),
                    onPanCancel: _endStroke,
                    child: DrawingCanvas(
                      strokes: _strokes,
                      inProgress: _inProgress,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _clearCanvas,
                    child: const Text('새로 만들기'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: FilledButton.tonal(
                    onPressed: null,
                    child: Text('색상 선택'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: FilledButton.tonal(
                    onPressed: null,
                    child: Text('지우기'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: FilledButton(
                    onPressed: null,
                    child: Text('아이콘 만들기'),
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
