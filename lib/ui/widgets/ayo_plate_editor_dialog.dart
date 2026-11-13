import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_colors.dart';

/// Interactive Vehicle Photo Editor to place the official AYO Red Plate
/// directly over the vehicle's physical license plate (Matching Reference UI Image 2).
/// When submitted, it renders the label permanently into the image before uploading to server.
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

class _AyoPlateEditorDialogState extends State<AyoPlateEditorDialog> {
  final GlobalKey _captureAreaKey = GlobalKey();

  bool _applyPlate = true;
  bool _isProcessing = false;

  // Position of the AYO sticker (relative to center of preview)
  double _dx = 0;
  double _dy = 60; // default slightly lower where front bumpers usually are
  double _plateWidth = 110;

  Future<void> _saveAndUploadWithPlate() async {
    if (!_applyPlate) {
      Navigator.pop(context, widget.imageFile);
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary =
          _captureAreaKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
        '${Directory.systemTemp.path}/ayo_plate_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, tempFile);
      }
    } catch (e) {
      debugPrint('Plate sticker render failed: $e');
      if (mounted) Navigator.pop(context, widget.imageFile);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, widget.imageFile),
            child: const Text('Skip / Raw', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instruction banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _applyPlate
                          ? 'Drag the red AYO plate over the vehicle\'s number plate'
                          : 'Plate sticker disabled for this photo',
                      style: const TextStyle(color: Color(0xFFE2E4E8), fontSize: 12),
                    ),
                  ),
                  Switch(
                    value: _applyPlate,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _applyPlate = val),
                  ),
                ],
              ),
            ),

            // Main Interactive Canvas
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: RepaintBoundary(
                    key: _captureAreaKey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base Vehicle Image
                          Image.file(
                            widget.imageFile,
                            fit: BoxFit.contain,
                          ),

                          // Draggable AYO Number Plate Sticker
                          if (_applyPlate)
                            Transform.translate(
                              offset: Offset(_dx, _dy),
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _dx += details.delta.dx;
                                    _dy += details.delta.dy;
                                  });
                                },
                                child: _AyoPlateSticker(
                                  width: _plateWidth,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF181620),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_applyPlate) ...[
                    Row(
                      children: [
                        const Text(
                          'Plate Size:',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: Slider(
                            value: _plateWidth,
                            min: 65,
                            max: 180,
                            activeColor: AppColors.primary,
                            inactiveColor: Colors.white24,
                            onChanged: (val) => setState(() => _plateWidth = val),
                          ),
                        ),
                        Text(
                          '${_plateWidth.toInt()}px',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      // Upload raw / without plate
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context, widget.imageFile),
                          child: const Text(
                            'Upload Raw Photo',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save with AYO plate
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isProcessing ? null : _saveAndUploadWithPlate,
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Official AYO Bumper License Plate Sticker matching Image 2
/// Pure Red background (#E60012) with bold white "AYO" text and subtle metallic border.
class _AyoPlateSticker extends StatelessWidget {
  const _AyoPlateSticker({
    required this.width,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.34;
    final fontSize = (height * 0.58).clamp(11.0, 36.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary, // Signature Ayo Red
        borderRadius: BorderRadius.circular(height * 0.18),
        border: Border.all(
          color: Colors.white,
          width: (height * 0.07).clamp(1.2, 3.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'AYO',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
          height: 1.0,
        ),
      ),
    );
  }
}
