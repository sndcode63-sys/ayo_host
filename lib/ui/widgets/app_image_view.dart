import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// In-memory cache linking remote GCS URLs to recently picked local device image files.
/// This guarantees 0ms instant preview and prevents 403 Forbidden / CORS blank screens.
class AppImageCache {
  AppImageCache._();

  static final Map<String, String> _urlToLocalPath = {};

  static void register(String url, String localPath) {
    if (url.trim().isNotEmpty && localPath.trim().isNotEmpty) {
      _urlToLocalPath[url.trim()] = localPath.trim();
    }
  }

  static String? getLocalPath(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final path = _urlToLocalPath[url.trim()];
    if (path != null && File(path).existsSync()) {
      return path;
    }
    return null;
  }
}

/// Universal, ultra-resilient image view widget for AYO.
/// Prioritizes local file preview -> cached local file -> network image -> GCS bucket URL -> fallback icon.
class AppImageView extends StatelessWidget {
  const AppImageView({
    super.key,
    this.url,
    this.localPath,
    this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon,
    this.isAvatar = false,
  });

  final String? url;
  final String? localPath;
  final File? file;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallbackIcon;
  final bool isAvatar;

  Widget _buildFallback() {
    if (fallbackIcon != null) return fallbackIcon!;
    return Container(
      width: width,
      height: height,
      color: AppColors.fieldFill,
      child: Center(
        child: Icon(
          isAvatar ? Icons.person_outline_rounded : Icons.directions_car_rounded,
          size: (width != null && width! < 60) ? 22 : 32,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    // 1. Direct File provided and exists
    if (file != null && file!.existsSync()) {
      content = Image.file(
        file!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    // 2. Explicit localPath provided and exists
    else if (localPath != null && localPath!.trim().isNotEmpty && File(localPath!.trim()).existsSync()) {
      content = Image.file(
        File(localPath!.trim()),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    // 3. URL is a local file path that exists on disk
    else if (url != null && url!.trim().isNotEmpty && File(url!.trim()).existsSync()) {
      content = Image.file(
        File(url!.trim()),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    // 4. URL is registered in local cache with an existing file
    else if (url != null && AppImageCache.getLocalPath(url!) != null) {
      final cachedPath = AppImageCache.getLocalPath(url!)!;
      content = Image.file(
        File(cachedPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    // 5. Remote HTTP / HTTPS URL
    else if (url != null && (url!.trim().startsWith('http://') || url!.trim().startsWith('https://'))) {
      content = Image.network(
        url!.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    // 6. GCS relative key (e.g. vehicles/.../photos/xyz.jpg or hosts/.../avatar.jpg)
    else if (url != null && url!.trim().isNotEmpty) {
      final cleanKey = url!.trim().replaceAll(RegExp(r'^/+'), '');
      final fullGcsUrl = 'https://storage.googleapis.com/ayo-rentals/$cleanKey';
      content = Image.network(
        fullGcsUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    // 7. No image source available
    else {
      content = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
