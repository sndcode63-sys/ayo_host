import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/toast_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/host_service.dart';
import 'cards.dart';

/// Upload row for an identity document (DL front, DL back, selfie).
/// Presigns via `POST /host/document/presign`, uploads the file, and reports the
/// storage key through [onUploaded].
class DocUploadTile extends StatefulWidget {
  const DocUploadTile({
    super.key,
    required this.title,
    required this.hint,
    required this.icon,
    required this.documentType,
    required this.onUploaded,
    this.uploadedKey,
    this.selfie = false,
  });

  final String title;
  final String hint;
  final IconData icon;

  /// DL_FRONT | DL_BACK | SELFIE
  final String documentType;
  final String? uploadedKey;
  final bool selfie;
  final ValueChanged<String> onUploaded;

  @override
  State<DocUploadTile> createState() => _DocUploadTileState();
}

class _DocUploadTileState extends State<DocUploadTile> {
  String? _localPath;
  String? _key;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _key = widget.uploadedKey;
  }

  Future<void> _choose() async {
    if (_uploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.title, style: AppText.sectionTitle),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.textPrimary),
                title: Text('Take a photo', style: AppText.input),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
                title: Text('Choose from gallery', style: AppText.input),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1800,
      preferredCameraDevice: widget.selfie ? CameraDevice.front : CameraDevice.rear,
    );
    if (picked == null) return;

    setState(() {
      _localPath = picked.path;
      _uploading = true;
    });
    try {
      final key = await HostService.uploadHostDocument(
        documentType: widget.documentType,
        file: File(picked.path),
      );
      if (!mounted) return;
      setState(() => _key = key);
      widget.onUploaded(key);
    } catch (_) {
      if (mounted) setState(() => _localPath = null);
      ToastService.showError('${widget.title} upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploaded = _key != null && _key!.isNotEmpty;
    final radius = BorderRadius.circular(AppRadius.field + 2);

    return Material(
      color: AppColors.card,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: _choose,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: uploaded ? AppColors.success.withValues(alpha: 0.4) : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  color: uploaded ? AppColors.successSoft : AppColors.fieldMuted,
                  child: _localPath != null
                      ? Image.file(File(_localPath!), fit: BoxFit.cover)
                      : Icon(
                          uploaded ? Icons.check_rounded : widget.icon,
                          color: uploaded ? AppColors.success : AppColors.textMuted,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppText.input),
                    const SizedBox(height: 2),
                    Text(
                      widget.hint,
                      style: AppText.body.copyWith(fontSize: 11.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_uploading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else if (uploaded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const StatusPill(label: 'Uploaded', kind: StatusKind.success),
                    const SizedBox(height: 4),
                    Text('Replace',
                        style: AppText.body.copyWith(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                )
              else
                Text('Upload',
                    style: AppText.body.copyWith(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
