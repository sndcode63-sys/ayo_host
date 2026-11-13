import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Vehicle photo editor: the host places the AYO plate (white "AYO" on brand red)
/// exactly over the vehicle's real number plate. The plate is then drawn permanently
/// into the photo at the photo's real resolution and THAT image is uploaded, so the
/// AYO plate shows everywhere the photo is displayed (app, customer app, web).
///
/// Gestures on the photo: drag = move, pinch = resize, two-finger twist = rotate.
class AyoPlateEditorDialog extends StatefulWidget {
  const AyoPlateEditorDialog({
    super.key,
    required this.imageFile,
    this.title = 'Place AYO Plate on Vehicle',
    this.slotName,
  });

  final File imageFile;
  final String title;
  final String? slotName;

  static Future<File?> show(
    BuildContext context, {
    required File imageFile,
    String title = 'Place AYO Plate on Vehicle',
    String? slotName,
  }) {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => AyoPlateEditorDialog(
          imageFile: imageFile,
          title: title,
          slotName: slotName,
        ),
      ),
    );
  }

  @override
  State<AyoPlateEditorDialog> createState() => _AyoPlateEditorDialogState();
}

/// Plate placement, stored relative to the photo so preview and export match exactly.
class _PlateSpec {
  _PlateSpec();

  double cx = 0.5; // centre x, 0..1 of photo width
  double cy = 0.72; // centre y, 0..1 of photo height
  double widthFrac = 0.18; // plate width as fraction of photo width
  double angle = 0; // radians
}

const double _kPlateAspect = 3.4; // width : height

/// Draws the photo and (optionally) the AYO plate. Used by BOTH the live preview and
/// the final export, so what the host sees is exactly what gets uploaded.
void _paintComposite(Canvas canvas, Size size, ui.Image image, _PlateSpec? plate) {
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Offset.zero & size,
    Paint()..filterQuality = FilterQuality.high,
  );
  if (plate == null) return;

  final w = size.width * plate.widthFrac;
  final h = w / _kPlateAspect;

  canvas.save();
  canvas.translate(plate.cx * size.width, plate.cy * size.height);
  canvas.rotate(plate.angle);

  final outer = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: w, height: h),
    Radius.circular(h * 0.14),
  );

  // soft contact shadow so the plate sits on the bumper
  canvas.drawRRect(
    outer.shift(Offset(0, h * 0.05)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.08),
  );
  // light metal frame
  canvas.drawRRect(outer, Paint()..color = const Color(0xFFE9EAEE));
  // red plate face
  final inset = h * 0.07;
  final face = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: w - inset * 2, height: h - inset * 2),
    Radius.circular(h * 0.10),
  );
  canvas.drawRRect(
    face,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -h / 2),
        Offset(0, h / 2),
        [AppColors.primary, Color.lerp(AppColors.primary, Colors.black, 0.18)!],
      ),
  );

  // white AYO text, auto-fit to the plate face
  final tp = TextPainter(
    text: TextSpan(
      text: 'AYO',
      style: TextStyle(
        color: Colors.white,
        fontSize: h * 0.62,
        fontWeight: FontWeight.w900,
        letterSpacing: h * 0.06,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final maxTextW = face.width * 0.86;
  if (tp.width > maxTextW) {
    final scale = maxTextW / tp.width;
    canvas.scale(scale);
  }
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

  canvas.restore();
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.image, this.plate);

  final ui.Image image;
  final _PlateSpec? plate;

  @override
  void paint(Canvas canvas, Size size) => _paintComposite(canvas, size, image, plate);

  @override
  bool shouldRepaint(covariant _PhotoPainter old) => true;
}

class _AyoPlateEditorDialogState extends State<AyoPlateEditorDialog> {
  ui.Image? _image;
  String? _loadError;
  static const bool _applyPlate = true; // AYO plate is mandatory on every exterior photo
  bool _isProcessing = false;
  final _PlateSpec _plate = _PlateSpec();

  // gesture baselines
  late double _baseW;
  late double _baseAngle;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Could not open this photo.');
    }
  }

  /// Renders the photo + plate at the photo's real resolution (long side capped at 2048px).
  Future<void> _applyAndReturn() async {
    final image = _image;
    if (image == null) return;
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final longSide = math.max(image.width, image.height).toDouble();
      final k = longSide > 2048 ? 2048 / longSide : 1.0;
      final outW = (image.width * k).round();
      final outH = (image.height * k).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _paintComposite(canvas, Size(outW.toDouble(), outH.toDouble()), image, _plate);
      final picture = recorder.endRecording();
      final out = await picture.toImage(outW, outH);
      final data = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      picture.dispose();
      if (data == null) throw Exception('encode failed');

      final file = File(
        '${Directory.systemTemp.path}/ayo_plate_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (mounted) Navigator.pop(context, file);
    } catch (e) {
      debugPrint('AYO plate render failed: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not apply AYO plate. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0E13),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cover the real number plate: drag to move, pinch to resize, twist to rotate',
                      style: TextStyle(color: Color(0xFFE2E4E8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildCanvas()),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    final image = _image;
    if (_loadError != null) {
      return Center(child: Text(_loadError!, style: const TextStyle(color: Colors.white70)));
    }
    if (image == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, box) {
          final imgAspect = image.width / image.height;
          var w = box.maxWidth;
          var h = w / imgAspect;
          if (h > box.maxHeight) {
            h = box.maxHeight;
            w = h * imgAspect;
          }
          final size = Size(w, h);
          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (d) {
                    _baseW = _plate.widthFrac;
                    _baseAngle = _plate.angle;
                    if (_applyPlate) {
                      // tapping/starting on the photo jumps the plate to the finger
                      setState(() {
                        _plate.cx = (d.localFocalPoint.dx / size.width).clamp(0.0, 1.0);
                        _plate.cy = (d.localFocalPoint.dy / size.height).clamp(0.0, 1.0);
                      });
                    }
                  },
                  onScaleUpdate: (d) {
                    if (!_applyPlate) return;
                    setState(() {
                      _plate.cx = (d.localFocalPoint.dx / size.width).clamp(0.0, 1.0);
                      _plate.cy = (d.localFocalPoint.dy / size.height).clamp(0.0, 1.0);
                      if (d.pointerCount > 1) {
                        _plate.widthFrac = (_baseW * d.scale).clamp(0.04, 0.6);
                        _plate.angle = _baseAngle + d.rotation;
                      }
                    });
                  },
                  child: CustomPaint(
                    size: size,
                    painter: _PhotoPainter(image, _applyPlate ? _plate : null),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF181620),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_applyPlate) ...[
            _sliderRow(
              label: 'Size',
              value: _plate.widthFrac,
              min: 0.04,
              max: 0.6,
              onChanged: (v) => setState(() => _plate.widthFrac = v),
            ),
            _sliderRow(
              label: 'Tilt',
              value: _plate.angle.clamp(-0.8, 0.8),
              min: -0.8,
              max: 0.8,
              onChanged: (v) => setState(() => _plate.angle = v),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_isProcessing || _image == null) ? null : _applyAndReturn,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Apply & Upload',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.primary,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
