import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/host_service.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../dashboard/main_shell.dart';

/// AYO Vehicle Documents — RC, DL, Insurance, Smog (Step 2 of 2 Verification).
class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({super.key, this.vehicleId});

  final String? vehicleId;

  static const route = '/onboarding/documents';

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  bool _uploadingDoc = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingController>().loadDocuments(widget.vehicleId);
    });
  }

  IconData _iconFor(String type) => switch (type) {
        'RC' || 'rc' => Icons.badge_outlined,
        'DL' || 'dl' || 'host_dl' => Icons.credit_card_rounded,
        'INSURANCE' || 'insurance' => Icons.shield_outlined,
        'POLLUTION' || 'pollution' || 'smog' => Icons.cloud_outlined,
        _ => Icons.description_outlined,
      };

  Future<void> _pickAndUploadDoc(String docType) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final ob = context.read<OnboardingController>();
    final vId = widget.vehicleId ?? ob.createdVehicleId;

    setState(() => _uploadingDoc = true);
    try {
      final url = await HostService.uploadToCloudinary(File(picked.path));
      await ob.confirmDocument(
        vehicleId: vId,
        type: docType,
        url: url,
        fileName: picked.name,
      );
      ToastService.showSuccess('$docType document uploaded successfully!');
    } catch (e) {
      ToastService.showError('Document upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingDoc = false);
    }
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
                  subtitle: Text('Pick $docType image or document from phone'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadDoc(docType);
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
                  title: const Text('Paste Document URL'),
                  subtitle: const Text('Enter Cloudinary or HTTPS URL'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlInputDialog(context, docType);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context, String docType) {
    final urlController = TextEditingController();
    final vId = widget.vehicleId ?? context.read<OnboardingController>().createdVehicleId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Upload $docType Document URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Cloudinary / Document URL for $docType:', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://res.cloudinary.com/.../doc.pdf',
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
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                await context.read<OnboardingController>().confirmDocument(
                      vehicleId: vId,
                      type: docType,
                      url: url,
                      fileName: '${docType.toLowerCase()}_file.pdf',
                    );
              }
            },
            child: const Text('Save Document', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ob = context.read<OnboardingController>();
    final vId = widget.vehicleId ?? ob.createdVehicleId;

    final ok = await ob.submitVehicleForReview(vId);
    if (!mounted || !ok) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      MainShell.route,
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ob = context.watch<OnboardingController>();
    final checklist = ob.documentChecklist;
    final docs = checklist?.documents ?? [];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const StepHeader(
              step: 2,
              totalSteps: 2,
              title: 'Vehicle Documents',
              subtitle: 'Step 2 of 2 · Document Verification',
            ),
            const SizedBox(height: 20),
            Text('Vehicle Document Status', style: AppText.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Upload valid documents for your vehicle to submit for admin review and activation.',
              style: AppText.body,
            ),
            const SizedBox(height: 16),
            if (ob.documentsLoading || _uploadingDoc)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 10),
                      Text('Uploading document to server...', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              )
            else if (docs.isEmpty) ...[
              for (final type in ['RC', 'DL', 'INSURANCE', 'POLLUTION'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_iconFor(type), color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$type Certificate',
                                style: AppText.sectionTitle.copyWith(fontSize: 13),
                              ),
                            ),
                            const StatusPill(label: 'REQUIRED', kind: StatusKind.danger),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _showUploadOptions(context, type),
                          icon: const Icon(Icons.upload_file_rounded, size: 14),
                          label: Text('Upload $type Document'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ] else
              for (final doc in docs) ...[
                _DocumentCard(
                  doc: doc,
                  icon: _iconFor(doc.type),
                  onUpload: () => _showUploadOptions(context, doc.type),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'End-to-end encrypted. Used exclusively for compliance verification.',
                    style: AppText.body
                        .copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Submit Documents for Review',
              icon: Icons.arrow_forward_rounded,
              loading: ob.saving,
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  MainShell.route,
                  (r) => false,
                ),
                child: Text(
                  'Go to Host Dashboard',
                  style: AppText.body.copyWith(
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.icon,
    required this.onUpload,
  });

  final VehicleDocument doc;
  final IconData icon;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final done = doc.isDone;

    return AppCard(
      color: done ? AppColors.successSoft.withValues(alpha: 0.5) : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Icon(icon, size: 17, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title,
                        style: AppText.sectionTitle.copyWith(fontSize: 12.5)),
                    Text(doc.subtitle,
                        style: AppText.body.copyWith(
                            fontSize: 9.5, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusPill.auto(doc.status),
            ],
          ),
          if (done) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 5),
                Text('Uploaded / Verified on Ayo Backend',
                    style: AppText.body.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file_rounded, size: 14),
              label: Text('Upload ${doc.type} Document',
                  style: const TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
