import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../canvas/drawing_canvas.dart';
import '../canvas/stroke.dart';
import '../config/gemini_config.dart';
import '../services/icon_generator.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  List<Stroke> _strokes = <Stroke>[];
  Stroke? _inProgress;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4;
  bool _isGenerating = false;
  Uint8List? _generatedIcon;
  String? _lastPrompt;
  IconGenerator? _iconGenerator;

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

  Future<void> _handleGenerateIcon() async {
    if (!GeminiConfig.hasKey) {
      _showSnackBar('Gemini API 키를 설정한 뒤 다시 시도하세요.');
      return;
    }
    if (!_hasDrawing) {
      _showSnackBar('캔버스에 스케치를 추가한 뒤 아이콘을 생성하세요.');
      return;
    }

    final String initialPrompt = _lastPrompt ?? _defaultPrompt;
    final TextEditingController controller =
        TextEditingController(text: initialPrompt);
    final String? prompt = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('아이콘 만들기'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '생성 프롬프트를 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('생성'),
            ),
          ],
        );
      },
    );

    if (prompt == null || prompt.isEmpty) {
      return;
    }

    await _commitInProgressStroke();
    final Uint8List? sketchBytes = await _captureCanvasPng();
    if (sketchBytes == null) {
      _showSnackBar('캔버스를 이미지로 변환하지 못했습니다. 다시 시도하세요.');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      _iconGenerator ??= IconGenerator();
      final Uint8List result = await _iconGenerator!
          .generateIcon(prompt: prompt, sketchBytes: sketchBytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _generatedIcon = result;
        _lastPrompt = prompt;
      });
    } catch (error) {
      _showSnackBar('아이콘 생성 중 오류가 발생했습니다: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _commitInProgressStroke() async {
    if (_inProgress != null && !_inProgress!.isEmpty) {
      setState(() {
        _strokes = List<Stroke>.from(_strokes)..add(_inProgress!);
        _inProgress = null;
      });
    }
  }

  Future<Uint8List?> _captureCanvasPng() async {
    final RenderObject? renderObject = _canvasKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return null;
    }
    final ui.Image image =
        await renderObject.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  bool get _hasDrawing =>
      _strokes.isNotEmpty || (_inProgress != null && !_inProgress!.isEmpty);

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      body: Stack(
        children: <Widget>[
          Column(
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
                        child: RepaintBoundary(
                          key: _canvasKey,
                          child: DrawingCanvas(
                            strokes: _strokes,
                            inProgress: _inProgress,
                          ),
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
                    Expanded(
                      child: FilledButton(
                        onPressed: _isGenerating ? null : _handleGenerateIcon,
                        child: Text(
                          _generatedIcon == null ? '아이콘 만들기' : '다시 만들기',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isGenerating)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        '아이콘 생성 중...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const String _defaultPrompt =
    '사용자가 그린 스케치를 참고해 감각적인 앱 아이콘을 만들어 주세요. 단색 배경과 높은 대비를 유지하고, 선을 매끄럽게 정리해 주세요.';
