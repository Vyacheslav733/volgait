import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/src/services/photo_provider.dart';

class CropPhotoScreen extends StatefulWidget {
  final String photoId;
  const CropPhotoScreen({super.key, required this.photoId});

  @override
  State<CropPhotoScreen> createState() => _CropPhotoScreenState();
}

class _CropPhotoScreenState extends State<CropPhotoScreen> {
  final TransformationController _controller = TransformationController();
  Uint8List? _bytes;
  img.Image? _decoded;
  bool _saving = false;
  final GlobalKey _viewportKey = GlobalKey();

  Rect? _cropRect;
  static const double _handleSize = 16;
  static const double _minCropSide = 40;
  Rect? _initialRectImage;
  bool _appliedInitialOverlay = false;

  String? _originalFilePath;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _ensureInitialOverlay();
        });
      }
    });
  }

  Future<void> _load() async {
    final photo = context.read<PhotoProvider>().getPhotoById(widget.photoId);
    if (photo == null) {
      return;
    }

    try {
      Uint8List bytes;
      final String loadPath;

      if (photo.originalPath != null && photo.originalPath!.isNotEmpty) {
        loadPath = photo.originalPath!;
        _originalFilePath = photo.originalPath;
      } else if (photo.path.startsWith('assets/')) {
        loadPath = photo.path;
        _originalFilePath = photo.path;
      } else {
        loadPath = photo.path;
        _originalFilePath = photo.path;
      }

      if (loadPath.startsWith('assets/')) {
        bytes = (await rootBundle.load(loadPath)).buffer.asUint8List();
      } else {
        bytes = await File(loadPath).readAsBytes();
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Unsupported image');

      setState(() {
        _bytes = bytes;
        _decoded = decoded;
        if (photo.lastCropRect != null && photo.lastCropRect!.length == 4) {
          final r = photo.lastCropRect!;
          _initialRectImage = Rect.fromLTWH(r[0], r[1], r[2], r[3]);
          _appliedInitialOverlay = false;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить изображение')),
        );
        Navigator.pop(context);
      }
    }
  }

  Rect _getDefaultCropRect(Size viewportSize) {
    final padding = viewportSize.shortestSide * 0.1;
    return Rect.fromLTWH(
      padding,
      padding,
      viewportSize.width - padding * 2,
      viewportSize.height - padding * 2,
    );
  }

  Future<void> _onCrop() async {
    if (_decoded == null) return;

    final photoProvider = context.read<PhotoProvider>();
    final photo = photoProvider.getPhotoById(widget.photoId);
    if (photo == null) return;

    setState(() => _saving = true);

    try {
      final Directory appDir = Directory.current;
      final Directory croppedDir =
          Directory(p.join(appDir.path, 'cropped_photos'));
      if (!await croppedDir.exists()) {
        await croppedDir.create(recursive: true);
      }

      final String name = _originalFilePath != null
          ? p.basenameWithoutExtension(_originalFilePath!)
          : 'cropped';
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath =
          p.join(croppedDir.path, '${name}_$timestamp.jpg');

      final renderBox =
          _viewportKey.currentContext!.findRenderObject() as RenderBox;
      final viewportSize = renderBox.size;
      final double imageWidth = _decoded!.width.toDouble();
      final double imageHeight = _decoded!.height.toDouble();

      final Rect cropRect = _cropRect ?? _getDefaultCropRect(viewportSize);

      final double scaleX = imageWidth / viewportSize.width;
      final double scaleY = imageHeight / viewportSize.height;

      final int left =
          (cropRect.left * scaleX).floor().clamp(0, _decoded!.width - 1);
      final int top =
          (cropRect.top * scaleY).floor().clamp(0, _decoded!.height - 1);
      final int right =
          (cropRect.right * scaleX).ceil().clamp(1, _decoded!.width);
      final int bottom =
          (cropRect.bottom * scaleY).ceil().clamp(1, _decoded!.height);

      int width = right - left;
      int height = bottom - top;

      if (width <= 0) width = 1;
      if (height <= 0) height = 1;

      debugPrint('Crop area: $left,$top ${width}x$height');

      final cropped = img.copyCrop(_decoded!,
          x: left, y: top, width: width, height: height);

      final outBytes = img.encodeJpg(cropped, quality: 95);
      await File(outputPath).writeAsBytes(outBytes);

      photoProvider.updatePhoto(
        widget.photoId,
        path: outputPath,
        originalPath: _originalFilePath,
        lastCropRect: [
          left.toDouble(),
          top.toDouble(),
          width.toDouble(),
          height.toDouble()
        ],
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обрезки: $e')),
        );
      }
      debugPrint('Crop error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoded = _decoded;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обрезка фото'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) {
              final photo =
                  context.watch<PhotoProvider>().getPhotoById(widget.photoId);
              final canRestore = (photo?.originalPath != null &&
                  photo!.originalPath!.isNotEmpty &&
                  photo.path != photo.originalPath);
              return IconButton(
                onPressed: _saving || !canRestore
                    ? null
                    : () {
                        context
                            .read<PhotoProvider>()
                            .restoreOriginal(widget.photoId);
                        Navigator.of(context).maybePop(true);
                      },
                icon: const Icon(Icons.restore),
                tooltip: 'Восстановить оригинал',
              );
            },
          ),
          IconButton(
            onPressed: _saving || decoded == null
                ? null
                : () {
                    _controller.value = Matrix4.identity();
                  },
            icon: const Icon(Icons.refresh),
            tooltip: 'Сбросить',
          ),
          IconButton(
            onPressed: _saving || decoded == null ? null : _onCrop,
            icon: const Icon(Icons.check),
            tooltip: 'Готово',
          ),
        ],
      ),
      body: Center(
        child: decoded == null
            ? const CircularProgressIndicator()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      math.min(constraints.maxWidth, constraints.maxHeight) *
                          0.9;
                  return StatefulBuilder(
                    builder: (context, setLocal) {
                      return SizedBox(
                        key: _viewportKey,
                        width: size,
                        height: size,
                        child: Stack(
                          children: [
                            ClipRect(
                              child: InteractiveViewer(
                                transformationController: _controller,
                                minScale: 0.1,
                                maxScale: 10,
                                boundaryMargin:
                                    const EdgeInsets.all(double.infinity),
                                child: Image.memory(
                                  _bytes!,
                                  fit: BoxFit.fill,
                                  width: size,
                                  height: size,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CropOverlay(
                                initialRect: _cropRect ??
                                    _getDefaultCropRect(Size(size, size)),
                                minSide: _minCropSide,
                                handleSize: _handleSize,
                                onChanged: (r) {
                                  setState(() => _cropRect = r);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Rect? _ensureInitialOverlay() {
    if (!_appliedInitialOverlay &&
        _decoded != null &&
        _viewportKey.currentContext != null) {
      final renderBox =
          _viewportKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final viewportSize = renderBox.size;

        if (_initialRectImage != null) {
          final double imageWidth = _decoded!.width.toDouble();
          final double imageHeight = _decoded!.height.toDouble();

          final double scaleX = viewportSize.width / imageWidth;
          final double scaleY = viewportSize.height / imageHeight;

          final r = _initialRectImage!;
          _cropRect = Rect.fromLTRB(
            r.left * scaleX,
            r.top * scaleY,
            r.right * scaleX,
            r.bottom * scaleY,
          );
        } else {
          _cropRect = _getDefaultCropRect(viewportSize);
        }

        _appliedInitialOverlay = true;
      }
    }
    return _cropRect;
  }
}

class CropOverlay extends StatefulWidget {
  final Rect? initialRect;
  final ValueChanged<Rect> onChanged;
  final double handleSize;
  final double minSide;

  const CropOverlay({
    super.key,
    required this.initialRect,
    required this.onChanged,
    required this.handleSize,
    required this.minSide,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  late Rect _rect;
  Offset? _dragStart;
  Rect? _rectStart;
  String? _activeHandle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
    _rect = widget.initialRect ?? _initialRectFor(size);
  }

  Rect _initialRectFor(Size size) {
    final padding = size.shortestSide * 0.1;
    final r = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    return r;
  }

  void _notify() => widget.onChanged(_rect);

  void _startDrag(String handle, Offset globalPos) {
    _activeHandle = handle;
    final box = context.findRenderObject() as RenderBox;
    _dragStart = box.globalToLocal(globalPos);
    _rectStart = _rect;
  }

  void _updateDrag(Offset globalPos) {
    if (_dragStart == null || _rectStart == null || _activeHandle == null) {
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(globalPos);
    final delta = localPos - _dragStart!;
    var r = _rectStart!;
    final bounds = (context.findRenderObject() as RenderBox).size;

    switch (_activeHandle) {
      case 'move':
        r = r.shift(delta);
        break;
      case 'tl':
        r = Rect.fromLTRB(
            (r.left + delta.dx), (r.top + delta.dy), r.right, r.bottom);
        break;
      case 'tr':
        r = Rect.fromLTRB(
            r.left, (r.top + delta.dy), (r.right + delta.dx), r.bottom);
        break;
      case 'bl':
        r = Rect.fromLTRB(
            (r.left + delta.dx), r.top, r.right, (r.bottom + delta.dy));
        break;
      case 'br':
        r = Rect.fromLTRB(
            r.left, r.top, (r.right + delta.dx), (r.bottom + delta.dy));
        break;
    }

    if (r.width < widget.minSide) {
      final adjust = widget.minSide - r.width;
      if (_activeHandle == 'move') {
        r = Rect.fromLTWH(r.left, r.top, widget.minSide, r.height);
      } else if (_activeHandle == 'tl' || _activeHandle == 'bl') {
        r = r.translate(-adjust, 0).inflate(0);
        r = Rect.fromLTRB(r.left, r.top, r.left + widget.minSide, r.bottom);
      } else {
        r = Rect.fromLTRB(r.right - widget.minSide, r.top, r.right, r.bottom);
      }
    }
    if (r.height < widget.minSide) {
      final adjust = widget.minSide - r.height;
      if (_activeHandle == 'move') {
        r = Rect.fromLTWH(r.left, r.top, r.width, widget.minSide);
      } else if (_activeHandle == 'tl' || _activeHandle == 'tr') {
        r = r.translate(0, -adjust);
        r = Rect.fromLTRB(r.left, r.top, r.right, r.top + widget.minSide);
      } else {
        r = Rect.fromLTRB(r.left, r.bottom - widget.minSide, r.right, r.bottom);
      }
    }

    final dx = r.left < 0
        ? -r.left
        : r.right > bounds.width
            ? bounds.width - r.right
            : 0.0;
    final dy = r.top < 0
        ? -r.top
        : r.bottom > bounds.height
            ? bounds.height - r.bottom
            : 0.0;
    r = r.shift(Offset(dx, dy));

    setState(() => _rect = r);
    _notify();
  }

  void _endDrag() {
    _activeHandle = null;
    _dragStart = null;
    _rectStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_rect.size == Size.zero) {
          _rect = _initialRectFor(
              Size(constraints.maxWidth, constraints.maxHeight));
        }

        return GestureDetector(
          onPanStart: (d) {
            if (_rect.contains(d.localPosition)) {
              _startDrag('move', d.globalPosition);
            }
          },
          onPanUpdate: (d) => _updateDrag(d.globalPosition),
          onPanEnd: (_) => _endDrag(),
          child: CustomPaint(
            painter: _OverlayPainter(_rect),
            child: Stack(
              children: [
                _buildHandle(_rect.topLeft, 'tl'),
                _buildHandle(_rect.topRight, 'tr'),
                _buildHandle(_rect.bottomLeft, 'bl'),
                _buildHandle(_rect.bottomRight, 'br'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle(Offset center, String id) {
    final size = widget.handleSize;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (d) => _startDrag(id, d.globalPosition),
        onPanUpdate: (d) => _updateDrag(d.globalPosition),
        onPanEnd: (_) => _endDrag(),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect rect;
  _OverlayPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black54;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRect(rect);
    final combined = Path.combine(PathOperation.difference, path, hole);
    canvas.drawPath(combined, overlayPaint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawDashedRect(canvas, rect, border, dash: 8, gap: 6);
  }

  void _drawDashedRect(Canvas canvas, Rect r, Paint paint,
      {double dash = 6, double gap = 4}) {
    void drawSide(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      double covered = 0;
      while (covered < total) {
        final start = a + dir * covered;
        final end = a + dir * math.min(covered + dash, total);
        canvas.drawLine(start, end, paint);
        covered += dash + gap;
      }
    }

    drawSide(r.topLeft, r.topRight);
    drawSide(r.topRight, r.bottomRight);
    drawSide(r.bottomRight, r.bottomLeft);
    drawSide(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      oldDelegate.rect != rect;
}
