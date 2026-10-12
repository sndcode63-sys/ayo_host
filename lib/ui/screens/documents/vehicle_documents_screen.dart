import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../../widgets/inputs.dart';
import '../dashboard/main_shell.dart';

/// AYO Vehicle Documents — RC, DL, Insurance, Smog (Step 2 of 2).
class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({super.key});

  static const route = '/onboarding/documents';

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingController>().loadDocuments();
    });
  }

  IconData _iconFor(String type) => switch (type) {
        'rc' => Icons.badge_outlined,
        'dl' => Icons.credit_card_rounded,
        'insurance' => Icons.shield_outlined,
        'smog' => Icons.cloud_outlined,
        _ => Icons.description_outlined,
      };

  Future<void> _submit() async {
    final ok = await context.read<OnboardingController>().submitDocuments();
    if (!mounted || !ok) return;
    Navigator.pushNamedAndRemoveUntil(
        context, MainShell.route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ob = context.watch<OnboardingController>();

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
            Text('Vehicle Documents', style: AppText.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Provide valid documents to activate your vehicle for instant guest booking.',
              style: AppText.body,
            ),
            const SizedBox(height: 16),
            if (ob.documentsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              for (final doc in ob.documents) ...[
                _DocumentCard(doc: doc, icon: _iconFor(doc.type)),
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
              label: 'Submit Documents',
              icon: Icons.arrow_forward_rounded,
              loading: ob.saving,
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, MainShell.route, (r) => false),
                child: Text('Save and continue later',
                    style: AppText.body.copyWith(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc, required this.icon});

  final VehicleDocument doc;
  final IconData icon;

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
                        style:
                            AppText.sectionTitle.copyWith(fontSize: 12.5)),
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
          if (doc.fileName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.fileName!,
                            style: AppText.body.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(doc.fileMeta ?? '',
                            style: AppText.body.copyWith(
                                fontSize: 9,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Text('Replace',
                      style: AppText.body.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
          if (doc.status == 'Verified') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 5),
                Text('Verified by AYO',
                    style: AppText.body.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ],
            ),
          ],
          if (doc.status == 'Required') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _UploadButton(
                    icon: doc.type == 'insurance'
                        ? Icons.upload_file_rounded
                        : Icons.add_a_photo_outlined,
                    label: doc.type == 'insurance'
                        ? 'Upload Policy'
                        : 'Upload or Take Photo',
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: AppTextField(
                    hint: 'MM/DD/YYYY',
                    keyboardType: TextInputType.datetime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              doc.type == 'insurance'
                  ? 'PDF, JPG or PNG up to 15MB'
                  : 'Clear shot or scan works',
              style: AppText.body
                  .copyWith(fontSize: 9, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                style: AppText.body.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
