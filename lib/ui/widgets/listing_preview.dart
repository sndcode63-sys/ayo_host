import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/controllers.dart';
import 'app_image_view.dart';
import 'cards.dart';

/// One photo to show in the slider: a remote [url], a [localPath] on disk, or both.
class PhotoSource {
  const PhotoSource({this.url, this.localPath});

  final String? url;
  final String? localPath;

  bool get isEmpty =>
      (url == null || url!.trim().isEmpty) &&
      (localPath == null || localPath!.trim().isEmpty);
}

/// Photo slider that slides automatically (loops) and follows the photo list as it changes.
class AutoSlidePhotoSlider extends StatefulWidget {
  const AutoSlidePhotoSlider({
    super.key,
    required this.photos,
    this.height = 210,
    this.interval = const Duration(seconds: 3),
  });

  final List<PhotoSource> photos;
  final double height;
  final Duration interval;

  @override
  State<AutoSlidePhotoSlider> createState() => _AutoSlidePhotoSliderState();
}

class _AutoSlidePhotoSliderState extends State<AutoSlidePhotoSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  List<PhotoSource> get _photos => widget.photos.where((p) => !p.isEmpty).toList();

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant AutoSlidePhotoSlider old) {
    super.didUpdateWidget(old);
    final count = _photos.length;
    if (_page >= count && count > 0) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_photos.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        final count = _photos.length;
        if (!mounted || count < 2 || !_controller.hasClients) return;
        _controller.animateToPage(
          (_page + 1) % count,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    if (photos.isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        color: AppColors.fieldMuted,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 6),
            Text('Upload photos to preview', style: AppText.body.copyWith(fontSize: 11)),
          ],
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => AppImageView(
              url: photos[i].url,
              localPath: photos[i].localPath,
              width: double.infinity,
              height: widget.height,
              fit: BoxFit.cover,
            ),
          ),
          if (photos.length > 1) ...[
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_page + 1}/${photos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _page == i ? AppColors.primary : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full listing preview: auto-sliding photos + every detail the host entered.
class ListingPreviewCard extends StatelessWidget {
  const ListingPreviewCard({super.key, required this.ob});

  final OnboardingController ob;

  List<PhotoSource> _photos() {
    final list = <PhotoSource>[
      PhotoSource(url: ob.frontPhotoUrl, localPath: ob.frontPhotoLocalPath),
      PhotoSource(url: ob.interiorPhotoUrl, localPath: ob.interiorPhotoLocalPath),
      PhotoSource(url: ob.rearPhotoUrl, localPath: ob.rearPhotoLocalPath),
    ];
    final n = ob.additionalPhotoUrls.length > ob.additionalPhotoLocalPaths.length
        ? ob.additionalPhotoUrls.length
        : ob.additionalPhotoLocalPaths.length;
    for (var i = 0; i < n; i++) {
      list.add(PhotoSource(
        url: i < ob.additionalPhotoUrls.length ? ob.additionalPhotoUrls[i] : null,
        localPath: i < ob.additionalPhotoLocalPaths.length ? ob.additionalPhotoLocalPaths[i] : null,
      ));
    }
    return list.where((p) => !p.isEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos();
    final weekend = ob.weekendRate > 0 ? ob.weekendRate : ob.dailyRate * 1.2;
    final plate = ob.plate.isEmpty ? '' : '${ob.plateState.split(' - ').first} ${ob.plate}';
    final name = '${ob.make} ${ob.model}'.trim();

    Widget chip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.fieldMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(text, style: AppText.body.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AutoSlidePhotoSlider(photos: photos),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? 'Your vehicle' : name,
                        style: AppText.screenTitle.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const StatusPill(label: 'PREVIEW', kind: StatusKind.neutral),
                  ],
                ),
                if (plate.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(plate,
                      style: AppText.captionCaps.copyWith(
                          fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    chip(Icons.calendar_today_outlined, ob.year),
                    chip(Icons.directions_car_outlined, ob.bodyType),
                    chip(Icons.settings_outlined, ob.transmission),
                    chip(Icons.local_gas_station_outlined, ob.fuelType),
                    chip(Icons.event_seat_outlined, '${ob.seatingCapacity} seats'),
                    chip(Icons.swap_calls_rounded, ob.drivetrain),
                    if (ob.mileage.trim().isNotEmpty) chip(Icons.speed_rounded, ob.mileage.trim()),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                _PreviewRow(label: 'Pickup Location', value: ob.pickupAddress),
                _PreviewRow(label: 'Pincode', value: ob.pincode),
                _PreviewRow(label: 'Daily Rate', value: ob.dailyRate > 0 ? '₹${ob.dailyRate.toInt()} / day' : ''),
                _PreviewRow(
                  label: 'Weekend Rate',
                  value: ob.dailyRate > 0
                      ? '₹${weekend.toInt()} / day${ob.weekendRate > 0 ? '' : ' (auto +20%)'}'
                      : '',
                ),
                if (ob.hourlyRentals)
                  _PreviewRow(
                    label: 'Hourly Rate',
                    value: '₹${ob.effectiveHourlyRate.toInt()} / hr (min 6 hrs)',
                  ),
                _PreviewRow(label: 'Host Delivery', value: ob.hostDelivery ? 'Available' : 'Not offered'),
                _PreviewRow(label: 'Photos', value: '${photos.length} uploaded · ${ob.mandatoryPhotosCount} / 3 mandatory'),
                _PreviewRow(label: 'Documents', value: '${ob.uploadedDocUrls.length} / 4 uploaded'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: AppText.body.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
