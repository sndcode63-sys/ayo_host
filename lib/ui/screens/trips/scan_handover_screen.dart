import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/services/host_service.dart';
import '../../../state/controllers.dart';
import '../../widgets/number_plate_badge.dart';

/// Fullscreen real-time Camera QR Scanner for Pickup Handover Verification.
/// Implements full 5-step flow matching AYO Host design specifications.
class ScanHandoverScreen extends StatefulWidget {
  const ScanHandoverScreen({
    super.key,
    this.targetTrip,
  });

  final Trip? targetTrip;

  static const route = '/scan-handover';

  @override
  State<ScanHandoverScreen> createState() => _ScanHandoverScreenState();
}

class _ScanHandoverScreenState extends State<ScanHandoverScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  late final Animation<double> _scanLineAnim;

  bool _isTorchOn = false;
  bool _isVerifying = false;
  bool _hasScanned = false;
  String? _pickedGalleryImagePath;
  Map<String, dynamic>? _successData;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  String _sanitizeHandoverToken(String raw) {
    var token = raw.trim();

    // Strip wrapping quotes
    if ((token.startsWith('"') && token.endsWith('"')) ||
        (token.startsWith("'") && token.endsWith("'"))) {
      token = token.substring(1, token.length - 1).trim();
    }

    // If it's a URL (e.g. qrserver API url or deep link)
    if (token.startsWith('http://') || token.startsWith('https://')) {
      final uri = Uri.tryParse(token);
      if (uri != null) {
        final queryToken = uri.queryParameters['handover_token'] ??
            uri.queryParameters['token'] ??
            uri.queryParameters['data'];
        if (queryToken != null && queryToken.trim().isNotEmpty) {
          token = queryToken.trim();
        }
      }
    }

    // If it's JSON: {"handover_token": "..."}
    if (token.startsWith('{') && token.endsWith('}')) {
      try {
        final decoded = jsonDecode(token);
        if (decoded is Map) {
          final t = decoded['handover_token'] ?? decoded['token'] ?? decoded['data'];
          if (t != null && t.toString().trim().isNotEmpty) {
            token = t.toString().trim();
          }
        }
      } catch (_) {}
    }

    return token;
  }

  Future<void> _pickAndScanFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null || !mounted) return;

      // 1. Immediately show the picked photo on screen so the user sees their QR image being scanned
      setState(() {
        _pickedGalleryImagePath = image.path;
        _isVerifying = false;
        _hasScanned = false;
      });

      // 2. Brief visual delay so user sees the laser sweep across their photo (Paytm style)
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      // 3. Analyze image using MobileScanner
      final BarcodeCapture? capture =
          await _scannerController.analyzeImage(image.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        String? scannedToken;
        for (final barcode in capture.barcodes) {
          final val = barcode.rawValue?.trim();
          if (val != null && val.isNotEmpty) {
            scannedToken = _sanitizeHandoverToken(val);
            break;
          }
        }

        if (scannedToken != null && scannedToken.isNotEmpty) {
          _hasScanned = true;
          await _verifyToken(scannedToken);
          return;
        }
      }

      // If no QR code detected in the selected image
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        ToastService.showError(
          'No QR code detected in this photo. Please make sure the QR is clearly visible.',
        );
      }
    } catch (e) {
      debugPrint('Gallery QR scan error: $e');
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        ToastService.showError('Could not process image: $e');
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || _isVerifying || _pickedGalleryImagePath != null) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue != null && rawValue.isNotEmpty) {
        _hasScanned = true;
        _verifyToken(_sanitizeHandoverToken(rawValue));
        break;
      }
    }
  }

  Future<void> _verifyToken(String token) async {
    setState(() {
      _isVerifying = true;
    });

    try {
      // 1. Get host geolocation if available
      double? lat;
      double? lng;
      final pos = await LocationService.currentPosition();
      if (pos != null) {
        lat = pos.lat;
        lng = pos.lng;
      }

      // 2. Call direct scan API
      final res = await HostService.scanHandover(
        handoverToken: token,
        hostLat: lat,
        hostLng: lng,
      );

      // 3. Reload dashboard state
      if (mounted) {
        await context.read<DashboardController>().load();
      }

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _successData = res;
        });
      }
    } catch (e) {
      if (mounted) {
        String message = 'Verification failed';
        if (e is DioException) {
          final resData = e.response?.data;
          if (resData is Map) {
            message = resData['message']?.toString() ??
                resData['error']?['message']?.toString() ??
                e.error?.toString() ??
                'QR token is invalid or expired';
          } else if (e.error != null) {
            message = e.error.toString();
          } else if (e.message != null) {
            message = e.message!;
          }
        } else {
          message = e.toString().replaceAll('Exception:', '').trim();
        }

        // Clean up common technical prefixes
        message = message.replaceAll('DioException [bad response]:', '').trim();
        if (message.startsWith('null')) {
          message = message.replaceFirst('null', '').trim();
        }
        if (message.isEmpty || message.toLowerCase() == 'null') {
          message = 'QR token is invalid or expired';
        }

        setState(() {
          _isVerifying = false;
          _hasScanned = false;
        });
        _showErrorBottomSheet(message);
      }
    }
  }

  void _showManualTokenSheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCDFE4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.keyboard_alt_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Enter Handover Token Manually',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E2022)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste the customer handover token if camera scanning is not working:',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E4E8)),
              ),
              child: TextField(
                controller: textController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Paste token here...',
                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9EA3AE)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final token = textController.text.trim();
                  if (token.isEmpty) {
                    ToastService.showWarning('Please paste the customer handover token');
                    return;
                  }
                  Navigator.pop(sheetCtx);
                  _verifyToken(_sanitizeHandoverToken(token));
                },
                child: const Text(
                  'Verify Token & Start Trip',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorBottomSheet(String message) {
    final isExpiredOrInvalid = message.toLowerCase().contains('invalid') ||
        message.toLowerCase().contains('expired') ||
        message.toLowerCase().contains('token');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCDFE4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Handover Verification Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2022)),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                  height: 1.4,
                ),
              ),
            ),
            if (isExpiredOrInvalid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.access_time_filled_rounded, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Customer QR codes are valid for 5 minutes only. Please ask the customer to refresh their QR screen in the Customer App.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showManualTokenSheet();
                    },
                    child: const Text('Enter Manually', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _hasScanned = false;
                        _pickedGalleryImagePath = null;
                      });
                    },
                    child: const Text('Scan Again', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If trip started successfully, render the Success celebration screen (Step 4)
    if (_successData != null) {
      return _buildSuccessCelebrationView(context);
    }

    final size = MediaQuery.of(context).size;
    final scanBoxSize = (size.width * 0.72).clamp(240.0, 310.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview OR Gallery Picked Photo
          if (_pickedGalleryImagePath != null)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Image.file(
                    File(_pickedGalleryImagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
          else
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

          // 2. Translucent Cutout Mask around viewfinder
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _ScannerOverlayPainter(
              boxSize: scanBoxSize,
              overlayColor: Colors.black.withValues(alpha: 0.62),
            ),
          ),

          // 3. Viewfinder Box with corners & animated scan line
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: Stack(
                children: [
                  // Corner brackets
                  const _ScannerCornerBrackets(),

                  // Animated Scanning Laser Line
                  AnimatedBuilder(
                    animation: _scanLineAnim,
                    builder: (context, child) {
                      return Positioned(
                        top: scanBoxSize * _scanLineAnim.value,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                Color(0xFFFF4D5A),
                                AppColors.primary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Top Header: Back Button, Title, Torch Flash Toggle / Close Gallery
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back circular button
                        _CircularGlassButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        // Title
                        Text(
                          _pickedGalleryImagePath != null ? 'Gallery QR Scan' : 'Scan Customer QR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        // Top actions: Close if viewing gallery image, else Gallery & Torch
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_pickedGalleryImagePath != null)
                              _CircularGlassButton(
                                icon: Icons.close_rounded,
                                onTap: () {
                                  setState(() {
                                    _pickedGalleryImagePath = null;
                                    _isVerifying = false;
                                  });
                                },
                              )
                            else ...[
                              _CircularGlassButton(
                                icon: Icons.photo_library_rounded,
                                onTap: _pickAndScanFromGallery,
                              ),
                              const SizedBox(width: 8),
                              _CircularGlassButton(
                                icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: _isTorchOn ? const Color(0xFFFFD700) : Colors.white,
                                onTap: _toggleTorch,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _pickedGalleryImagePath != null
                            ? AppColors.primary.withValues(alpha: 0.85)
                            : Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _pickedGalleryImagePath != null
                            ? 'Scanning uploaded QR image...'
                            : 'Point camera at QR or upload from gallery',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Action Buttons: Gallery + Manual Entry OR Switch Back
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_pickedGalleryImagePath != null) ...[
                  // Return to live camera
                  InkWell(
                    onTap: () {
                      setState(() {
                        _pickedGalleryImagePath = null;
                        _isVerifying = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Back to Camera',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Choose another image
                  InkWell(
                    onTap: _pickAndScanFromGallery,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.photo_library_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Choose Another',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Scan from Gallery (Paytm/PhonePe style)
                  InkWell(
                    onTap: _pickAndScanFromGallery,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.photo_library_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Upload from Gallery',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Enter Manually
                  InkWell(
                    onTap: _showManualTokenSheet,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.keyboard_outlined, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Enter Manually',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 6. QR Detected & Verifying State Overlay (Step 3)
          if (_isVerifying)
            Container(
              color: Colors.black.withValues(alpha: _pickedGalleryImagePath != null ? 0.62 : 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verifying QR Code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please wait while we verify the handover token',
                      style: TextStyle(
                        color: Color(0xFFB0B4BA),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Step 4: Full Success Screen with celebration graphics
  Widget _buildSuccessCelebrationView(BuildContext context) {
    final trip = widget.targetTrip;
    final vehicleTitle = trip?.vehicle.isNotEmpty == true ? trip!.vehicle : 'Vehicle Handover';
    final plate = trip?.vehicleId.isNotEmpty == true ? trip!.vehicleId : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Big Green Checkmark
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Trip Started Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15131A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vehicle handover verified.\nTrip is now ACTIVE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Mini Vehicle Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.directions_car_rounded, color: Color(0xFF4B5563), size: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicleTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15131A),
                            ),
                          ),
                          if (plate.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            AyoNumberPlateBadge(plate: plate, compact: true),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            'Trip Status',
                            style: TextStyle(fontSize: 9, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'ACTIVE',
                            style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Back to Trips Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F52BA), // Deep blue matching mockup
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Back to Trips',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularGlassButton extends StatelessWidget {
  const _CircularGlassButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// 4 glowing corner brackets for the viewfinder frame
class _ScannerCornerBrackets extends StatelessWidget {
  const _ScannerCornerBrackets();

  static const cornerLength = 28.0;
  static const cornerThickness = 4.0;
  static const cornerRadius = 8.0;
  static const cornerColor = Color(0xFF3B82F6); // Vibrant Blue matching screenshot

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(cornerRadius)),
            ),
          ),
        ),
        // Top-right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(cornerRadius)),
            ),
          ),
        ),
        // Bottom-left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(cornerRadius)),
            ),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerLength,
            height: cornerLength,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(cornerRadius)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark transparent overlay with a transparent square hole for the QR viewfinder
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.boxSize,
    required this.overlayColor,
  });

  final double boxSize;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.boxSize != boxSize || oldDelegate.overlayColor != overlayColor;
}
