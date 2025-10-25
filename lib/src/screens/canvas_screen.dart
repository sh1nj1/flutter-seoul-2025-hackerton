import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

  Future<void> _selectColor() async {
    Color tempColor = _selectedColor;
    double tempWidth = _strokeWidth;
    final bool? applied = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('색상 선택'),
          content: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BlockPicker(
                      pickerColor: tempColor,
                      availableColors: _availableColors,
                      onColorChanged: (Color color) {
                        setDialogState(() {
                          tempColor = color;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('브러시 두께: ${tempWidth.toStringAsFixed(0)}'),
                    Slider(
                      min: 1,
                      max: 16,
                      value: tempWidth,
                      onChanged: (double value) {
                        setDialogState(() {
                          tempWidth = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('적용'),
            ),
          ],
        );
      },
    );

    if (applied == true) {
      setState(() {
        _selectedColor = tempColor;
        _strokeWidth = tempWidth;
      });
    }
  }

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

  void _undoStroke() {
    if (_strokes.isEmpty) {
      return;
    }
    setState(() {
      _strokes = List<Stroke>.from(_strokes)..removeLast();
    });
  }

  static const List<Color> _availableColors = <Color>[
    Colors.black,
    Colors.blueGrey,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

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
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _selectColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('색상 선택'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _undoStroke,
                    child: const Text('지우기'),
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
