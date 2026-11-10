import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/services/razorpay_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../data/services/host_service.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/inputs.dart';
import '../../widgets/listing_preview.dart';
import '../../widgets/chrome.dart';
import '../../widgets/app_image_view.dart';
import '../dashboard/main_shell.dart';
import '../documents/vehicle_documents_screen.dart';

/// AYO Host Vehicle Listing — Step 3 of 3: Photos, Documents & Full Live Preview.
class VehiclePhotosScreen extends StatefulWidget {
  const VehiclePhotosScreen({super.key});

  static const route = '/onboarding/vehicle/photos';

  @override
  State<VehiclePhotosScreen> createState() => _VehiclePhotosScreenState();
}

class _VehiclePhotosScreenState extends State<VehiclePhotosScreen> {
  @override
  void dispose() {
    RazorpayService.instance.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, {String? slot}) async {
    final ctrl = context.read<OnboardingController>();
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    await ctrl.uploadVehiclePhoto(File(picked.path), slot: slot);
  }

  void _showAddPhotoOptions(BuildContext context, {String? slot, String? slotName}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Upload ${slotName ?? "Vehicle Photo"}', style: AppText.sectionTitle),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Choose Photo from Gallery'),
                  subtitle: const Text('Pick image file from phone'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(context, slot: slot);
                  },
                ),
              ),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.link_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Paste Direct Image URL'),
                  subtitle: const Text('Enter GCS / HTTPS URL'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlInputDialog(context, slot: slot);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context, {String? slot}) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter direct image URL for your car:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            AppTextField(
              hint: 'https://storage.googleapis.com/ayo-rentals/.../car.jpg',
              controller: urlController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                context.read<OnboardingController>().addPhotoUrl(url, slot: slot);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Photo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMissingDocsDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('Mandatory Documents Required', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppText.body.copyWith(fontSize: 12),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              final vId = context.read<OnboardingController>().createdVehicleId;
              Navigator.pushNamed(
                context,
                VehicleDocumentsScreen.route,
                arguments: vId.isNotEmpty ? vId : null,
              );
            },
            child: const Text('Upload Documents', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showKycPendingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: AppColors.warning, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('KYC Verification Pending', style: AppText.sectionTitle.copyWith(fontSize: 16)),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppText.body.copyWith(fontSize: 12),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, MainShell.route, (r) => false);
            },
            child: const Text('Go to Home Dashboard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadDoc(BuildContext context, String docType) async {
    final ctrl = context.read<OnboardingController>();
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    await ctrl.uploadDocumentFile(docType, File(picked.path));
  }

  void _confirmDeletePhoto(BuildContext context, String slotName, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $slotName?'),
        content: Text(
          'Are you sure you want to delete this $slotName photo from cloud storage?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDoc(BuildContext context, String docType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $docType Document?'),
        content: Text(
          'Are you sure you want to delete this $docType document from cloud storage?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ctrl = context.read<OnboardingController>();
              final vId = ctrl.createdVehicleId;
              if (vId.isNotEmpty) {
                final ok = await ctrl.deleteDocument(vehicleId: vId, type: docType);
                if (ok) {
                  ToastService.showSuccess('$docType document deleted from storage');
                }
              } else {
                ctrl.uploadedDocUrls.remove(docType);
                ToastService.showSuccess('$docType document removed');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions(BuildContext context, String docType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Upload $docType Document', style: AppText.sectionTitle),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Choose Photo from Gallery'),
                  subtitle: const Text('Upload RC, Insurance, or PUC document'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadDoc(context, docType);
                  },
                ),
              ),
              const Divider(),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.link_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Paste Direct Image URL'),
                  subtitle: const Text('Enter GCS / HTTPS URL'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDocUrlInputDialog(context, docType);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocUrlInputDialog(BuildContext context, String docType) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $docType URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter direct URL for $docType certificate:', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            AppTextField(
              hint: 'https://storage.googleapis.com/ayo-rentals/.../doc.pdf',
              controller: urlController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                final ctrl = context.read<OnboardingController>();
                ctrl.saveUploadedDocUrl(docType, url);
                if (ctrl.createdVehicleId.isNotEmpty) {
                  ctrl.confirmDocument(
                    vehicleId: ctrl.createdVehicleId,
                    type: docType,
                    url: url,
                    fileName: '${docType.toLowerCase()}_doc.jpg',
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Document', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleListingSubmission() async {
    final ctrl = context.read<OnboardingController>();
    final authCtrl = context.read<AuthController>();
    final dashCtrl = context.read<DashboardController>();

    // Strict Validation: 3 Mandatory Photos Required
    if (!ctrl.hasThreeMandatoryPhotos) {
      ToastService.showError(
        'Three (3) vehicle photos are required: Cover (Front), Interior Cockpit, and Rear Trunk. Please upload all three.',
      );
      return;
    }

    final ok = await ctrl.submitListing();
    if (!mounted) return;

    if (ok) {
      // Check if listing fee gate needs Razorpay
      final checklist = ctrl.documentChecklist;
      final fee = checklist?.listingFee;
      if (ctrl.lastError == 'LISTING_FEE_REQUIRED' || (fee != null && !fee.bypassEnabled && fee.amountPaise > 0)) {
        var feePaise = fee?.amountPaise;
        if (feePaise == null || feePaise <= 0) {
          if (ctrl.submitResult?.amountPaise != null && ctrl.submitResult!.amountPaise > 0) {
            feePaise = ctrl.submitResult!.amountPaise;
          } else {
            try {
              feePaise = (await HostService.getListingFee()).feePaise;
            } catch (_) {
              feePaise = 0; // real amount comes from the payment order below
            }
          }
        }
        await _triggerRazorpayFeePayment(
          ctrl.createdVehicleId,
          feePaise,
          authCtrl,
          dashCtrl,
        );
        return;
      }

      ToastService.showSuccess('Vehicle submitted for review! Check fleet status on Dashboard.');
      ctrl.resetVehicleDraft();
      await dashCtrl.load();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, MainShell.route, (r) => false);
    } else {
      final err = ctrl.lastError ?? '';
      if (err.contains('KYC') || err.contains('HOST_KYC_REQUIRED')) {
        _showKycPendingDialog(
          context,
          'Host KYC verification is required to list vehicles. Please complete your profile and payout setup. Our verification team reviews accounts within 24 hours.',
        );
      } else if (err.contains('MISSING_VEHICLE_DOCUMENTS') || err.contains('missing_documents') || err.contains('documents')) {
        _showMissingDocsDialog(
          context,
          'All vehicle documents (RC, Commercial Insurance, Pollution) must be uploaded before listing. Please upload all documents to complete verification.',
        );
      } else {
        ToastService.showError(err.isNotEmpty ? err : 'Submission failed. Please try again.');
      }
    }
  }

  void _showPaymentFailedDialog({
    required BuildContext context,
    required String vehicleId,
    required String errorMessage,
    required int amountPaise,
    required AuthController authCtrl,
    required DashboardController dashCtrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Payment Incomplete', style: AppText.sectionTitle.copyWith(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              amountPaise > 0
                  ? 'Listing fee payment of ₹${amountPaise ~/ 100} could not be completed ($errorMessage).'
                  : 'Listing fee payment could not be completed ($errorMessage).',
              style: AppText.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'You can retry the online payment now, or submit your vehicle for offline admin verification.',
              style: AppText.body.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ctrl = context.read<OnboardingController>();
              final nav = Navigator.of(context);
              try {
                ToastService.showInfo('Submitting listing for admin review...');
                final subRes = await HostService.submitVehicleForReview(vehicleId);
                if (subRes.success || subRes.listingFeeRequired == false) {
                  ToastService.showSuccess('Vehicle submitted for admin review!');
                  ctrl.resetVehicleDraft();
                  await dashCtrl.load();
                  if (mounted) {
                    nav.pushNamedAndRemoveUntil(MainShell.route, (r) => false);
                  }
                } else {
                  ToastService.showWarning(
                    subRes.amountPaise > 0
                        ? 'Listing fee of ₹${subRes.amountPaise ~/ 100} is required before submission. Please complete payment.'
                        : 'Listing fee payment is required before submission. Please complete payment.',
                  );
                }
              } catch (_) {
                ToastService.showWarning('Please complete the listing fee payment to submit for review.');
              }
            },
            child: const Text('Admin Review'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _triggerRazorpayFeePayment(vehicleId, amountPaise, authCtrl, dashCtrl);
            },
            child: const Text('Retry Payment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerRazorpayFeePayment(
    String vehicleId,
    int amountPaise,
    AuthController authCtrl,
    DashboardController dashCtrl,
  ) async {
    final ctrl = context.read<OnboardingController>();

    try {
      String activeOrderId = ctrl.submitResult?.orderId ?? '';
      String activeKeyId = ctrl.submitResult?.keyId ?? '';
      int activeAmount = ctrl.submitResult?.amountPaise ?? amountPaise;

      // Normalize amount: strictly in paise (1 INR = 100 paise)
      if (activeAmount > 0 && activeAmount < 1000) {
        activeAmount = activeAmount * 100;
      }
      if (activeAmount <= 0) {
        try {
          activeAmount = (await HostService.getListingFee()).feePaise;
        } catch (_) {}
      }

      if (activeOrderId.isEmpty) {
        ToastService.showInfo('Creating Razorpay payment order...');
        final feeOrder = await HostService.payListingFee(vehicleId);

        if (feeOrder.bypassed) {
          ToastService.showSuccess('Listing fee waived! Vehicle submitted for admin review.');
          ctrl.resetVehicleDraft();
          await dashCtrl.load();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, MainShell.route, (r) => false);
          }
          return;
        }
        activeOrderId = feeOrder.orderId;
        if (feeOrder.keyId.isNotEmpty) {
          activeKeyId = feeOrder.keyId;
        }
        if (feeOrder.amount > 0) {
          activeAmount = feeOrder.amount;
        }
      }

      // Resolve key ID dynamically from backend
      final resolvedKeyId = activeKeyId.isNotEmpty
          ? activeKeyId
          : (dashCtrl.paymentsConfig?.keyId.isNotEmpty == true
              ? dashCtrl.paymentsConfig!.keyId
              : '');

      if (resolvedKeyId.isEmpty) {
        ToastService.showError('Payment gateway key is not configured on the server.');
        return;
      }

      RazorpayService.instance.initialize(
        onSuccess: (PaymentSuccessResponse res) async {
          LoggerService.info('Razorpay payment completed: ${res.paymentId}');
          ToastService.showInfo('Verifying payment signature with AYO backend...');
          var verified = await ctrl.verifyListingFee(
            vehicleId: vehicleId,
            orderId: res.orderId ?? activeOrderId,
            paymentId: res.paymentId ?? '',
            signature: res.signature ?? '',
          );
          if (!verified) {
            try {
              final subRes = await HostService.submitVehicleForReview(vehicleId);
              if (subRes.success || subRes.listingFeeRequired == false) {
                verified = true;
              }
            } catch (_) {}
          }
          if (verified) {
            if (mounted) {
              ToastService.showSuccess('Listing fee paid! Vehicle submitted for admin review.');
              ctrl.resetVehicleDraft();
              await dashCtrl.load();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, MainShell.route, (r) => false);
              }
            }
          } else {
            if (mounted) {
              ToastService.showError('Payment verification failed. Please contact support or retry.');
            }
          }
        },
        onFailure: (PaymentFailureResponse res) {
          LoggerService.warning('Razorpay payment failure: [${res.code}] ${res.message}');
          if (mounted) {
            _showPaymentFailedDialog(
              context: context,
              vehicleId: vehicleId,
              errorMessage: res.message ?? 'Payment cancelled',
              amountPaise: activeAmount,
              authCtrl: authCtrl,
              dashCtrl: dashCtrl,
            );
          }
        },
      );

      RazorpayService.instance.openCheckout(
        keyId: resolvedKeyId,
        amountPaise: activeAmount,
        orderId: activeOrderId,
        name: 'AYO Host Platform',
        description: 'Vehicle Listing & Onboarding Fee (₹${(activeAmount / 100).toInt()})',
        contact: authCtrl.userPhone,
        email: authCtrl.userEmail,
      );
    } catch (e) {
      LoggerService.error('Failed to create Razorpay listing fee order', error: e);
      ToastService.showError('Payment order error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ob = context.watch<OnboardingController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            StepHeader(
              step: 3,
              totalSteps: 3,
              title: 'AYO Host Onboarding',
              subtitle: 'Step 3 of 3 · Photos & Legal Documents',
              rightTag: 'Final Step',
              onClose: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, MainShell.route);
                }
              },
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: '1. Vehicle Photos Gallery',
              trailing: '${ob.mandatoryPhotosCount} / 3 Mandatory Added',
              trailingColor: ob.hasThreeMandatoryPhotos ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 4),
            Text(
              'Teen images mandatory hain: Front Cover, Interior, aur Rear/Trunk.',
              style: AppText.body.copyWith(
                fontSize: 10,
                color: ob.hasThreeMandatoryPhotos ? AppColors.textMuted : AppColors.primary,
                fontWeight: ob.hasThreeMandatoryPhotos ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (ob.uploadingPhoto)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 6),
                      Text('Uploading photo to Google Cloud Storage...', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),

            // 2x2 Photo Grid matching user reference UI
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                // Slot 1: Front Angle (Cover) - Mandatory
                _PhotoSlotCard(
                  title: 'Front Angle',
                  subtitle: 'Cover photo (Mandatory)',
                  icon: Icons.directions_car_rounded,
                  badge: '★ COVER',
                  isCover: true,
                  imageUrl: ob.frontPhotoUrl,
                  localPath: ob.frontPhotoLocalPath,
                  onTap: () => _showAddPhotoOptions(context, slot: 'FRONT', slotName: 'Front Angle (Cover)'),
                  onDelete: () => _confirmDeletePhoto(context, 'Front Cover', () => ob.removeFrontPhoto()),
                ),

                // Slot 2: Interior / Cockpit - Mandatory
                _PhotoSlotCard(
                  title: 'Interior / Cockpit',
                  subtitle: 'Dashboard & seats',
                  icon: Icons.airline_seat_recline_extra_rounded,
                  badge: 'MANDATORY',
                  imageUrl: ob.interiorPhotoUrl,
                  localPath: ob.interiorPhotoLocalPath,
                  onTap: () => _showAddPhotoOptions(context, slot: 'INTERIOR', slotName: 'Interior / Cockpit'),
                  onDelete: () => _confirmDeletePhoto(context, 'Interior', () => ob.removeInteriorPhoto()),
                ),

                // Slot 3: Rear & Trunk - Mandatory
                _PhotoSlotCard(
                  title: 'Rear & Trunk',
                  subtitle: 'Cargo & charging',
                  icon: Icons.sensor_door_outlined,
                  badge: 'MANDATORY',
                  imageUrl: ob.rearPhotoUrl,
                  localPath: ob.rearPhotoLocalPath,
                  onTap: () => _showAddPhotoOptions(context, slot: 'REAR', slotName: 'Rear & Trunk'),
                  onDelete: () => _confirmDeletePhoto(context, 'Rear & Trunk', () => ob.removeRearPhoto()),
                ),

                // Slot 4: Add More Angles (Up to 8 total)
                _AddMoreAnglesTile(
                  count: ob.additionalPhotoUrls.length,
                  onTap: () => _showAddPhotoOptions(context, slotName: 'Additional Angle'),
                ),
              ],
            ),

            // If additional photos are uploaded, display their thumbnails below
            if (ob.additionalPhotoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Additional Angles (${ob.additionalPhotoUrls.length} uploaded)',
                style: AppText.captionCaps.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ob.additionalPhotoUrls.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final u = ob.additionalPhotoUrls[index];
                    final localP = index < ob.additionalPhotoLocalPaths.length ? ob.additionalPhotoLocalPaths[index] : null;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppImageView(
                            url: u,
                            localPath: localP,
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _confirmDeletePhoto(
                              context,
                              'Additional Photo',
                              () => ob.removeAdditionalPhoto(index),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 22),
            SectionHeader(
              title: '2. Vehicle Documents Verification',
              trailing: '${ob.uploadedDocUrls.length} / 4 Uploaded',
            ),
            const SizedBox(height: 4),
            Text('Upload required legal documents for compliance verification.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 12),
            if (ob.uploadingDoc)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 6),
                      Text('Uploading document...', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            for (final docType in ['RC', 'DL', 'INSURANCE', 'POLLUTION'])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        docType == 'RC'
                            ? Icons.badge_outlined
                            : docType == 'DL'
                                ? Icons.credit_card_rounded
                                : docType == 'INSURANCE'
                                    ? Icons.shield_outlined
                                    : Icons.cloud_outlined,
                        color: ob.uploadedDocUrls.containsKey(docType)
                            ? AppColors.success
                            : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docType == 'RC'
                                  ? 'Registration Certificate (RC)'
                                  : docType == 'DL'
                                      ? 'Commercial Driving License'
                                      : docType == 'INSURANCE'
                                          ? 'Commercial Vehicle Insurance'
                                          : 'Pollution Under Control (PUC)',
                              style: AppText.sectionTitle.copyWith(fontSize: 12),
                            ),
                            Text(
                              ob.uploadedDocUrls.containsKey(docType)
                                  ? 'Uploaded and ready for review'
                                  : 'Required before listing approval',
                              style: AppText.body.copyWith(
                                fontSize: 9.5,
                                color: ob.uploadedDocUrls.containsKey(docType)
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ob.uploadedDocUrls.containsKey(docType)) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Color(0xFFDC2626)),
                          tooltip: 'Delete document',
                          onPressed: () => _confirmDeleteDoc(context, docType),
                        ),
                        const SizedBox(width: 4),
                      ],
                      ElevatedButton.icon(
                        onPressed: () => _showUploadOptions(context, docType),
                        icon: Icon(
                          ob.uploadedDocUrls.containsKey(docType)
                              ? Icons.check_circle_rounded
                              : Icons.upload_file_rounded,
                          size: 14,
                        ),
                        label: Text(
                          ob.uploadedDocUrls.containsKey(docType) ? 'Replace' : 'Upload',
                          style: const TextStyle(fontSize: 10),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ob.uploadedDocUrls.containsKey(docType)
                              ? AppColors.success
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 22),
            Text('3. Listing Full Preview', style: AppText.sectionTitle),
            const SizedBox(height: 4),
            Text('Photos slide automatically — this is how guests and admin will see your listing.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: ListingPreviewCard(ob: ob),
            ),
            const SizedBox(height: 22),
            ScaleOnPress(
              onTap: ob.saving ? null : _handleListingSubmission,
              child: PrimaryButton(
                label: 'Submit Listing & Go to Home',
                icon: Icons.check_circle_rounded,
                loading: ob.saving,
                onPressed: _handleListingSubmission,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Submitting sends full vehicle details, 3 mandatory photos, and legal documents to Ayo backend.',
                style: AppText.body.copyWith(fontSize: 9.5, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slot Card designed exactly matching user reference UI
class _PhotoSlotCard extends StatelessWidget {
  const _PhotoSlotCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
    this.localPath,
    required this.onTap,
    required this.onDelete,
    this.badge,
    this.isCover = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String imageUrl;
  final String? localPath;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String? badge;
  final bool isCover;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty || (localPath != null && localPath!.isNotEmpty);

    if (hasImage) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImageView(
                url: imageUrl,
                localPath: localPath,
                fit: BoxFit.cover,
                fallbackIcon: Container(
                  color: AppColors.fieldFill,
                  child: const Center(
                    child: Icon(Icons.directions_car_rounded, color: AppColors.textMuted),
                  ),
                ),
              ),
              // Gradient shadow overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              // Top Badge (e.g. ★ COVER)
              if (badge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCover ? Colors.white : Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 9,
                        color: isCover ? AppColors.primary : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Trash/Delete Icon
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.textPrimary),
                  ),
                ),
              ),
              // Bottom Title with Checkmark
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

    // Empty Slot Card (Dashed appearance, clean white background, center icon, label)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppText.sectionTitle.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppText.body.copyWith(fontSize: 9, color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMoreAnglesTile extends StatelessWidget {
  const _AddMoreAnglesTile({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Add More Angles',
              style: AppText.sectionTitle.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              count > 0 ? '$count added · Up to 8' : 'Up to 8 total',
              style: AppText.body.copyWith(fontSize: 9, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
