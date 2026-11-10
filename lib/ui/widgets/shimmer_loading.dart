import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Ultra-smooth 60fps shimmer effect widget with ShaderMask linear gradient.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFFE8E8EE);
    final highlight = widget.highlightColor ?? const Color(0xFFF8F8FC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.2, -0.3),
              end: const Alignment(1.2, 0.3),
              stops: const [0.0, 0.45, 0.55, 1.0],
              colors: [
                base,
                highlight,
                highlight,
                base,
              ],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2.5 - 1.0), 0, 0);
  }
}

/// Generic rounded placeholder container for building skeleton screens.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.color,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E2E8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Screen Specific Shimmer Skeletons
// ─────────────────────────────────────────────────────────────

/// Full dashboard shimmer skeleton matching the live dashboard layout.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: [
          // Top Bar Skeleton
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 80, height: 20, borderRadius: 6),
                  SizedBox(height: 6),
                  ShimmerBox(width: 130, height: 12, borderRadius: 4),
                ],
              ),
              const Spacer(),
              const ShimmerBox(width: 36, height: 36, borderRadius: 18),
              const SizedBox(width: 12),
              const ShimmerBox(width: 32, height: 32, borderRadius: 16),
            ],
          ),
          const SizedBox(height: 20),

          // Greeting skeleton
          const ShimmerBox(width: 170, height: 26, borderRadius: 8),
          const SizedBox(height: 8),
          const ShimmerBox(width: 220, height: 14, borderRadius: 6),
          const SizedBox(height: 18),

          // Big Revenue Card skeleton
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E2E8),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            padding: const EdgeInsets.all(18),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 110, height: 14, borderRadius: 6),
                    ShimmerBox(width: 60, height: 20, borderRadius: 10),
                  ],
                ),
                ShimmerBox(width: 150, height: 36, borderRadius: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 120, height: 12, borderRadius: 4),
                    ShimmerBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Stats Row (3 small cards)
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 74, borderRadius: 14)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 74, borderRadius: 14)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 74, borderRadius: 14)),
            ],
          ),
          const SizedBox(height: 24),

          // Section Header skeleton
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 120, height: 18, borderRadius: 6),
              ShimmerBox(width: 50, height: 14, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle tile skeletons
          for (int i = 0; i < 2; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E2E8),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 84, height: 64, borderRadius: 12),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 140, height: 16, borderRadius: 6),
                        SizedBox(height: 8),
                        ShimmerBox(width: 90, height: 12, borderRadius: 4),
                        SizedBox(height: 8),
                        ShimmerBox(width: 70, height: 14, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fleet list shimmer skeleton.
class FleetShimmer extends StatelessWidget {
  const FleetShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E2E8),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car image skeleton
                const ShimmerBox(height: 160, borderRadius: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 160, height: 20, borderRadius: 6),
                          ShimmerBox(width: 70, height: 22, borderRadius: 12),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const ShimmerBox(width: 120, height: 13, borderRadius: 4),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ShimmerBox(width: 90, height: 22, borderRadius: 6),
                          ShimmerBox(width: 80, height: 32, borderRadius: AppRadius.button),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Notifications shimmer skeleton.
class NotificationShimmer extends StatelessWidget {
  const NotificationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E2E8),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 42, height: 42, borderRadius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 16, borderRadius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(height: 12, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Earnings screen shimmer skeleton.
class EarningsShimmer extends StatelessWidget {
  const EarningsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          const ShimmerBox(height: 140, borderRadius: 16),
          const SizedBox(height: 16),
          const ShimmerBox(height: 200, borderRadius: 16),
          const SizedBox(height: 20),
          const ShimmerBox(width: 140, height: 18, borderRadius: 6),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShimmerBox(height: 64, borderRadius: 14),
            ),
          ],
        ],
      ),
    );
  }
}
