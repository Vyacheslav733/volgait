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
  static const double _handleSize = 20;
  static const double _minCropSide = 60;
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
          SnackBar(
            content: const Text('Не удалось загрузить изображение'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Size _calculateImageDisplaySize(Size viewportSize, img.Image image) {
    final imageAspect = image.width / image.height;
    final viewportAspect = viewportSize.width / viewportSize.height;

    if (imageAspect > viewportAspect) {
      final height = viewportSize.width / imageAspect;
      return Size(viewportSize.width, height);
    } else {
      final width = viewportSize.height * imageAspect;
      return Size(width, viewportSize.height);
    }
  }

  Rect _getImageDisplayRect(Size viewportSize, Size imageDisplaySize) {
    final left = (viewportSize.width - imageDisplaySize.width) / 2;
    final top = (viewportSize.height - imageDisplaySize.height) / 2;
    return Rect.fromLTWH(
      left,
      top,
      imageDisplaySize.width,
      imageDisplaySize.height,
    );
  }

  Rect _getDefaultCropRect(Size viewportSize, Rect imageDisplayRect) {
    final padding = imageDisplayRect.shortestSide * 0.05;

    final left = (imageDisplayRect.left + padding)
        .clamp(imageDisplayRect.left, imageDisplayRect.right - _minCropSide);
    final top = (imageDisplayRect.top + padding)
        .clamp(imageDisplayRect.top, imageDisplayRect.bottom - _minCropSide);
    final right = (imageDisplayRect.right - padding)
        .clamp(imageDisplayRect.left + _minCropSide, imageDisplayRect.right);
    final bottom = (imageDisplayRect.bottom - padding)
        .clamp(imageDisplayRect.top + _minCropSide, imageDisplayRect.bottom);

    final width = right - left;
    final height = bottom - top;

    if (width < _minCropSide || height < _minCropSide) {
      final centerX = imageDisplayRect.left + imageDisplayRect.width / 2;
      final centerY = imageDisplayRect.top + imageDisplayRect.height / 2;
      final halfSize = _minCropSide / 2;

      return Rect.fromLTRB(
        (centerX - halfSize).clamp(
            imageDisplayRect.left, imageDisplayRect.right - _minCropSide),
        (centerY - halfSize).clamp(
            imageDisplayRect.top, imageDisplayRect.bottom - _minCropSide),
        (centerX + halfSize).clamp(
            imageDisplayRect.left + _minCropSide, imageDisplayRect.right),
        (centerY + halfSize).clamp(
            imageDisplayRect.top + _minCropSide, imageDisplayRect.bottom),
      );
    }

    return Rect.fromLTRB(left, top, right, bottom);
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

      final imageDisplaySize =
          _calculateImageDisplaySize(viewportSize, _decoded!);
      final imageDisplayRect =
          _getImageDisplayRect(viewportSize, imageDisplaySize);

      final Rect cropRect =
          _cropRect ?? _getDefaultCropRect(viewportSize, imageDisplayRect);

      final double scaleX = imageWidth / imageDisplaySize.width;
      final double scaleY = imageHeight / imageDisplaySize.height;

      final double adjustedLeft = (cropRect.left - imageDisplayRect.left)
          .clamp(0, imageDisplaySize.width);
      final double adjustedTop = (cropRect.top - imageDisplayRect.top)
          .clamp(0, imageDisplaySize.height);
      final double adjustedRight = (cropRect.right - imageDisplayRect.left)
          .clamp(0, imageDisplaySize.width);
      final double adjustedBottom = (cropRect.bottom - imageDisplayRect.top)
          .clamp(0, imageDisplaySize.height);

      final int left =
          (adjustedLeft * scaleX).floor().clamp(0, _decoded!.width - 1);
      final int top =
          (adjustedTop * scaleY).floor().clamp(0, _decoded!.height - 1);
      final int right =
          (adjustedRight * scaleX).ceil().clamp(1, _decoded!.width);
      final int bottom =
          (adjustedBottom * scaleY).ceil().clamp(1, _decoded!.height);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Фото успешно обрезано'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обрезки: $e'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Обрезка фото',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (context) {
                      final photo = context
                          .watch<PhotoProvider>()
                          .getPhotoById(widget.photoId);
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        const Text('Оригинал восстановлен'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                        icon: Icon(Icons.restore_rounded,
                            color: _saving || !canRestore
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3)
                                : Theme.of(context).colorScheme.primary),
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
                    icon: Icon(Icons.refresh_rounded,
                        color: _saving || decoded == null
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3)
                            : Theme.of(context).colorScheme.onSurface),
                    tooltip: 'Сбросить',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Перетащите углы для обрезки изображения',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: decoded == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Загрузка изображения...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final size = math.min(
                                  constraints.maxWidth, constraints.maxHeight) *
                              0.85;
                          final imageDisplaySize = _calculateImageDisplaySize(
                              Size(size, size), _decoded!);
                          final imageDisplayRect = _getImageDisplayRect(
                              Size(size, size), imageDisplaySize);

                          return StatefulBuilder(
                            builder: (context, setLocal) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SizedBox(
                                    key: _viewportKey,
                                    width: size,
                                    height: size,
                                    child: Stack(
                                      children: [
                                        Container(
                                          color: Colors.black.withOpacity(0.1),
                                        ),
                                        Center(
                                          child: InteractiveViewer(
                                            transformationController:
                                                _controller,
                                            minScale: 0.1,
                                            maxScale: 10,
                                            boundaryMargin:
                                                const EdgeInsets.all(
                                                    double.infinity),
                                            child: SizedBox(
                                              width: imageDisplaySize.width,
                                              height: imageDisplaySize.height,
                                              child: Image.memory(
                                                _bytes!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: ImageCropOverlay(
                                            imageDisplayRect: imageDisplayRect,
                                            initialRect: _cropRect ??
                                                _getDefaultCropRect(
                                                    Size(size, size),
                                                    imageDisplayRect),
                                            minSide: _minCropSide,
                                            handleSize: _handleSize,
                                            onChanged: (r) {
                                              setState(() => _cropRect = r);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || decoded == null ? null : _onCrop,
                      style: FilledButton.styleFrom(
                        backgroundColor: _saving || decoded == null
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3)
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: _saving || decoded == null
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5)
                            : Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Применить'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        final imageDisplaySize =
            _calculateImageDisplaySize(viewportSize, _decoded!);
        final imageDisplayRect =
            _getImageDisplayRect(viewportSize, imageDisplaySize);

        if (_initialRectImage != null) {
          final double imageWidth = _decoded!.width.toDouble();
          final double imageHeight = _decoded!.height.toDouble();

          final double scaleX = imageDisplaySize.width / imageWidth;
          final double scaleY = imageDisplaySize.height / imageHeight;

          final r = _initialRectImage!;
          _cropRect = Rect.fromLTRB(
            imageDisplayRect.left + r.left * scaleX,
            imageDisplayRect.top + r.top * scaleY,
            imageDisplayRect.left + r.right * scaleX,
            imageDisplayRect.top + r.bottom * scaleY,
          );
        } else {
          _cropRect = _getDefaultCropRect(viewportSize, imageDisplayRect);
        }

        _appliedInitialOverlay = true;
      }
    }
    return _cropRect;
  }
}

class ImageCropOverlay extends StatefulWidget {
  final Rect imageDisplayRect;
  final Rect? initialRect;
  final ValueChanged<Rect> onChanged;
  final double handleSize;
  final double minSide;

  const ImageCropOverlay({
    super.key,
    required this.imageDisplayRect,
    required this.initialRect,
    required this.onChanged,
    required this.handleSize,
    required this.minSide,
  });

  @override
  State<ImageCropOverlay> createState() => _ImageCropOverlayState();
}

class _ImageCropOverlayState extends State<ImageCropOverlay> {
  late Rect _rect;
  Offset? _dragStart;
  Rect? _rectStart;
  String? _activeHandle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rect = widget.initialRect ?? _initialRectFor();
  }

  Rect _initialRectFor() {
    final padding = widget.imageDisplayRect.shortestSide * 0.05;
    return Rect.fromLTWH(
      widget.imageDisplayRect.left + padding,
      widget.imageDisplayRect.top + padding,
      widget.imageDisplayRect.width - padding * 2,
      widget.imageDisplayRect.height - padding * 2,
    );
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

    r = Rect.fromLTRB(
      r.left.clamp(widget.imageDisplayRect.left, widget.imageDisplayRect.right),
      r.top.clamp(widget.imageDisplayRect.top, widget.imageDisplayRect.bottom),
      r.right
          .clamp(widget.imageDisplayRect.left, widget.imageDisplayRect.right),
      r.bottom
          .clamp(widget.imageDisplayRect.top, widget.imageDisplayRect.bottom),
    );

    if (r.width < widget.minSide) {
      final adjust = widget.minSide - r.width;
      if (_activeHandle == 'move') {
        r = Rect.fromLTWH(r.left, r.top, widget.minSide, r.height);
      } else if (_activeHandle == 'tl' || _activeHandle == 'bl') {
        r = Rect.fromLTRB(r.left - adjust, r.top, r.right, r.bottom);
      } else {
        r = Rect.fromLTRB(r.left, r.top, r.right + adjust, r.bottom);
      }
    }
    if (r.height < widget.minSide) {
      final adjust = widget.minSide - r.height;
      if (_activeHandle == 'move') {
        r = Rect.fromLTWH(r.left, r.top, r.width, widget.minSide);
      } else if (_activeHandle == 'tl' || _activeHandle == 'tr') {
        r = Rect.fromLTRB(r.left, r.top - adjust, r.right, r.bottom);
      } else {
        r = Rect.fromLTRB(r.left, r.top, r.right, r.bottom + adjust);
      }
    }

    r = Rect.fromLTRB(
      r.left.clamp(widget.imageDisplayRect.left,
          widget.imageDisplayRect.right - widget.minSide),
      r.top.clamp(widget.imageDisplayRect.top,
          widget.imageDisplayRect.bottom - widget.minSide),
      r.right.clamp(widget.imageDisplayRect.left + widget.minSide,
          widget.imageDisplayRect.right),
      r.bottom.clamp(widget.imageDisplayRect.top + widget.minSide,
          widget.imageDisplayRect.bottom),
    );

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
    return GestureDetector(
      onPanStart: (d) {
        if (_rect.contains(d.localPosition)) {
          _startDrag('move', d.globalPosition);
        }
      },
      onPanUpdate: (d) => _updateDrag(d.globalPosition),
      onPanEnd: (_) => _endDrag(),
      child: CustomPaint(
        painter: _ImageOverlayPainter(widget.imageDisplayRect, _rect),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageOverlayPainter extends CustomPainter {
  final Rect imageDisplayRect;
  final Rect cropRect;

  _ImageOverlayPainter(this.imageDisplayRect, this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final imageOverlayPaint = Paint()..color = Colors.black.withOpacity(0.4);
    final imagePath = Path()..addRect(imageDisplayRect);
    final imageHole = Path()..addRect(cropRect);
    final imageCombined =
        Path.combine(PathOperation.difference, imagePath, imageHole);
    canvas.drawPath(imageCombined, imageOverlayPaint);

    final outsideOverlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final outsidePath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final outsideCombined =
        Path.combine(PathOperation.difference, outsidePath, imagePath);
    canvas.drawPath(outsideCombined, outsideOverlayPaint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final borderGlow = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRect(cropRect, borderGlow);
    _drawDashedRect(canvas, cropRect, border, dash: 12, gap: 8);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(cropRect.left + cropRect.width / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.bottom),
      gridPaint,
    );

    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height * 2 / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height * 2 / 3),
      gridPaint,
    );
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
  bool shouldRepaint(covariant _ImageOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.imageDisplayRect != imageDisplayRect;
}
