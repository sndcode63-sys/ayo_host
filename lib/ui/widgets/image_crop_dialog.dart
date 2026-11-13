import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_colors.dart';

/// Interactive in-app image cropper for vehicle photos (Cover, Interior, Rear, etc.)
class ImageCropDialog extends StatefulWidget {
  const ImageCropDialog({
    super.key,
    required this.imageFile,
    this.title = 'Crop & Adjust Photo',
    this.initialAspectRatio = 16 / 9,
  });

  final File imageFile;
  final String title;
  final double? initialAspectRatio;

  static Future<File?> show(
    BuildContext context, {
    required File imageFile,
    String title = 'Crop & Adjust Vehicle Photo',
    double? initialAspectRatio = 16 / 9,
  }) {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => ImageCropDialog(
          imageFile: imageFile,
          title: title,
          initialAspectRatio: initialAspectRatio,
        ),
      ),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final GlobalKey _cropAreaKey = GlobalKey();
  final TransformationController _transformController = TransformationController();

  late double? _aspectRatio = widget.initialAspectRatio;
  int _quarterTurns = 0;
  bool _isProcessing = false;

  void _rotateClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
    });
  }

  void _resetZoom() {
    setState(() {
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _applyCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _cropAreaKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempFile = File(
        '${Directory.systemTemp.path}/ayo_cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, tempFile);
      }
    } catch (e) {
      debugPrint('Crop render failed: $e');
      if (mounted) Navigator.pop(context, widget.imageFile);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
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
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _resetZoom,
          ),
          IconButton(
            tooltip: 'Rotate 90°',
            icon: const Icon(Icons.rotate_right_rounded),
            onPressed: _rotateClockwise,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instruction header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.pinch_rounded, size: 16, color: Colors.white60),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pinch to zoom & drag to frame your car / bike nicely',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // Main Crop Area
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AspectRatio(
                    aspectRatio: _aspectRatio ?? 1.0,
                    child: Stack(
                      children: [
                        // RepaintBoundary containing the cropped view
                        RepaintBoundary(
                          key: _cropAreaKey,
                          child: ClipRect(
                            child: Container(
                              color: Colors.black,
                              child: InteractiveViewer(
                                transformationController: _transformController,
                                minScale: 0.8,
                                maxScale: 4.5,
                                boundaryMargin: const EdgeInsets.all(double.infinity),
                                child: Center(
                                  child: RotatedBox(
                                    quarterTurns: _quarterTurns,
                                    child: Image.file(
                                      widget.imageFile,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Rule of Thirds Grid Overlay
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.25)))))),
                                      Expanded(child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.25)))))),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.white.withValues(alpha: 0.25)),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.25)))))),
                                      Expanded(child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.25)))))),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.white.withValues(alpha: 0.25)),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Aspect Ratio Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF16151D),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ratioButton(label: '16:9 (Cover)', ratio: 16 / 9),
                      const SizedBox(width: 8),
                      _ratioButton(label: '4:3 (Cockpit)', ratio: 4 / 3),
                      const SizedBox(width: 8),
                      _ratioButton(label: '1:1 (Square)', ratio: 1 / 1),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.pop(context, widget.imageFile),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Use Original', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _applyCrop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.crop_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Crop & Upload', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratioButton({required String label, required double ratio}) {
    final isSelected = (_aspectRatio != null && (_aspectRatio! - ratio).abs() < 0.05);

    return InkWell(
      onTap: () {
        setState(() {
          _aspectRatio = ratio;
          _transformController.value = Matrix4.identity();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
