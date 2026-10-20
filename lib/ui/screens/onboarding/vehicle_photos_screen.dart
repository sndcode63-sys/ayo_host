import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../dashboard/main_shell.dart';

/// AYO Host Vehicle Listing — Step 2 of 2: Photos, Documents & Full Live Preview.
class VehiclePhotosScreen extends StatelessWidget {
  const VehiclePhotosScreen({super.key});

  static const route = '/onboarding/vehicle/photos';

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    final ctrl = context.read<OnboardingController>();
    await ctrl.uploadPhotoToCloudinary(File(picked.path));
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
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    final ctrl = context.read<OnboardingController>();
    await ctrl.uploadDocumentFile(docType, File(picked.path));
  }

  void _showAddPhotoOptions(BuildContext context) {
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
              Text('Upload Vehicle Photo', style: AppText.sectionTitle),
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
                    _pickAndUploadPhoto(context);
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
                  subtitle: const Text('Enter Cloudinary / HTTPS URL'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlInputDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context) {
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
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://res.cloudinary.com/.../car.jpg',
                border: OutlineInputBorder(),
              ),
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
                context.read<OnboardingController>().addPhotoUrl(url);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Photo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              trailing: '${ob.photoUrls.length} Photos Added',
              trailingColor: AppColors.primary,
            ),
            const SizedBox(height: 4),
            Text('Upload real photos of your vehicle to attract guest bookings.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 10),
            if (ob.uploadingPhoto)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 6),
                      Text('Uploading photo to Cloudinary...', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                for (int i = 0; i < ob.photoUrls.length; i++)
                  _PhotoThumbnail(
                    url: ob.photoUrls[i],
                    index: i,
                    onDelete: () => context.read<OnboardingController>().removePhotoUrl(i),
                  ),
                _AddPhotoTile(onTap: () => _showAddPhotoOptions(context)),
              ],
            ),
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
                                      ? "Host Driver's License"
                                      : docType == 'INSURANCE'
                                          ? 'Commercial Insurance'
                                          : 'Pollution / Smog Check',
                              style: AppText.sectionTitle.copyWith(fontSize: 12),
                            ),
                            Text(
                              ob.uploadedDocUrls.containsKey(docType)
                                  ? '✓ Document Uploaded'
                                  : 'Document Required',
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
                      ElevatedButton.icon(
                        onPressed: () => _pickAndUploadDoc(context, docType),
                        icon: Icon(
                          ob.uploadedDocUrls.containsKey(docType)
                              ? Icons.check_circle_rounded
                              : Icons.upload_file_rounded,
                          size: 13,
                        ),
                        label: Text(
                          ob.uploadedDocUrls.containsKey(docType) ? 'Uploaded' : 'Upload',
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
            Text('Preview your vehicle listing card as displayed to guests and admin.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(14),
              color: AppColors.primarySoft.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 90,
                          height: 68,
                          color: AppColors.fieldFill,
                          child: ob.photoUrls.isNotEmpty
                              ? Image.network(
                                  ob.photoUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.directions_car_rounded,
                                    size: 32,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : const Icon(
                                  Icons.directions_car_rounded,
                                  size: 32,
                                  color: AppColors.textMuted,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ob.make} ${ob.model}',
                              style: AppText.screenTitle.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${ob.year} · ${ob.bodyType} · ${ob.transmission}',
                              style: AppText.body.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${ob.plateState.split(' - ').first} ${ob.plate}',
                              style: AppText.captionCaps.copyWith(
                                fontSize: 9.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const StatusPill(label: 'PREVIEW', kind: StatusKind.neutral),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _SpecRow(label: 'Pickup Location', value: ob.pickupAddress),
                  _SpecRow(label: 'Daily Rate', value: '₹${ob.dailyRate.toInt()} / day'),
                  _SpecRow(
                    label: 'Documents Uploaded',
                    value: '${ob.uploadedDocUrls.length} / 4 Verified',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Submit Listing & Go to Home',
              icon: Icons.check_circle_rounded,
              loading: ob.saving,
              onPressed: () async {
                final ctrl = context.read<OnboardingController>();
                final ok = await ctrl.submitListing();
                if (context.mounted) {
                  if (ok) {
                    await context.read<DashboardController>().load();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        MainShell.route,
                        (r) => false,
                      );
                    }
                  } else {
                    final err = ctrl.lastError ?? '';
                    if (err.contains('KYC') || err.contains('HOST_KYC_REQUIRED') || err.contains('Bina KYC')) {
                      _showKycPendingDialog(
                        context,
                        'Bina KYC verification ke vehicle list nahi kar sakte. Aapka Host Onboarding & KYC verification under review hai (SLA: 24 Hours). Admin team dwara verify hote hi aap vehicle live list kar payenge.',
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Submitting sends full vehicle details, photos, and document links to Ayo backend.',
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

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.url,
    required this.index,
    required this.onDelete,
  });

  final String url;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.directions_car_rounded, color: AppColors.textMuted),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                index == 0 ? 'COVER' : 'PHOTO ${index + 1}',
                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 24),
            SizedBox(height: 4),
            Text('Upload Photo', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppText.body.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
