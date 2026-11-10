import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/animation_utils.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/host_service.dart';
import '../../../state/controllers.dart';
import '../dashboard/main_shell.dart';
import '../onboarding/host_profile_setup_screen.dart';
import 'sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFF140407);
  static const _asset = 'assets/images/ayo_splash_4k.webp';

  static const _minDisplay = Duration(milliseconds: 2400);

  late final AnimationController _clock;
  late final AnimationController _finish;

  final _imageReady = Completer<void>();
  final _embers = _Ember.generate();
  ui.Image? _image;

  bool _navigated = false;
  String? _pendingRoute;
  bool _skipRequested = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: const Duration(hours: 1))..forward();
    _finish = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _loadImage();
    _startInitAndNavigation();
  }

  @override
  void dispose() {
    _clock.dispose();
    _finish.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final data = await rootBundle.load(_asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (e, st) {
      debugPrint('SPLASH: image load failed -> $e\n$st');
    } finally {
      if (!_imageReady.isCompleted) _imageReady.complete();
    }
  }

  Future<void> _startInitAndNavigation() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 1. Direct minimum display timer
    final minDisplay = Future.delayed(_minDisplay);

    // 2. Background mein auth + session check
    String targetRoute = SignInScreen.route;
    try {
      final isAuth = await AuthService.isAuthenticated();
      if (!mounted) return;

      if (!isAuth) {
        targetRoute = SignInScreen.route;
      } else {
        try {
          await context.read<AuthController>().checkSession();
          if (!mounted) return;

          final status = await HostService.getOnboardingStatus();
          if (!mounted) return;

          final hasProfile = status.profileCompleted ||
              (status.profile != null && status.profile!.firstName.isNotEmpty);

          targetRoute =
          hasProfile ? MainShell.route : HostProfileSetupScreen.route;
        } catch (_) {
          targetRoute = SignInScreen.route;
        }
      }
    } catch (_) {
      targetRoute = SignInScreen.route;
    }

    _pendingRoute = targetRoute;

    // Agar user ne check ke dauraan tap kiya tha, turant navigate
    if (_skipRequested) {
      _navigateToPending();
      return;
    }

    await minDisplay;
    if (!mounted) return;

    // Loading bar 100% tak bhar do, phir navigate
    try {
      await _finish.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 150));

    _navigateToPending();
  }

  void _navigateToPending() {
    if (_navigated || !mounted) return;
    final route = _pendingRoute;
    if (route == null) {
      // Auth check abhi complete nahi; ready hote hi route karega
      _skipRequested = true;
      return;
    }
    _navigated = true;

    Widget targetWidget;
    if (route == MainShell.route) {
      targetWidget = const MainShell();
    } else if (route == HostProfileSetupScreen.route) {
      targetWidget = const HostProfileSetupScreen();
    } else {
      targetWidget = const SignInScreen();
    }

    Navigator.pushReplacement(
      context,
      AnimationUtils.fadeThroughRoute(
        targetWidget,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToPending,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Instant Flutter native asset render (zero delay, zero black blank screen)
              Image.asset(
                _asset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Container(color: _bg),
              ),

              // 2. High-tech glow, particles, headlights, sparks & animated loading bar on top
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_clock, _finish]),
                  builder: (_, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _AyoSplashPainter(
                      image: _image,
                      t: _clock.value * 3600.0, // seconds
                      finish: Curves.easeOut.transform(_finish.value),
                      bg: Colors.transparent,
                      embers: _embers,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── helpers ─────────────────────────

double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();

Color _a(Color c, double o) => c.withAlpha((255 * o.clamp(0.0, 1.0)).round());

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// 0.4 <-> 1.0 smooth pulse (CSS ease-in-out jaisa)
double _pulse(double t, double period, [double shift = 0]) =>
    0.4 + 0.6 * (0.5 - 0.5 * math.cos(2 * math.pi * (t + shift) / period));

class _Ember {
  const _Ember(this.x, this.y, this.r, this.delay, this.dur, this.dx);
  final double x, y, r, delay, dur, dx;

  static List<_Ember> generate() {
    final rnd = math.Random(7);
    return List.generate(24, (_) {
      return _Ember(
        60 + rnd.nextDouble() * 820,
        900 + rnd.nextDouble() * 300,
        2 + rnd.nextInt(4) * 0.5,
        rnd.nextDouble() * 1.5,
        3 + rnd.nextDouble() * 3,
        -40 + rnd.nextDouble() * 80,
      );
    });
  }
}

class _AyoSplashPainter extends CustomPainter {
  _AyoSplashPainter({
    required this.image,
    required this.t,
    required this.finish,
    required this.bg,
    required this.embers,
  });

  final ui.Image? image;
  final double t; // seconds since app start
  final double finish; // 0..1 bar ko 100% tak le jaane ke liye
  final Color bg;
  final List<_Ember> embers;

  // Design canvas = original splash image (941 x 1672)
  static const double dw = 941, dh = 1672;

  @override
  void paint(Canvas canvas, Size size) {
    // "Cover" fit — image poori screen bharti hai, center crop
    final s = math.max(size.width / dw, size.height / dh);
    canvas.save();
    canvas.translate((size.width - dw * s) / 2, (size.height - dh * s) / 2);
    canvas.scale(s);

    final img = image;
    if (img != null) {
      _drawImage(canvas, img);
    }
    _drawLoadingBar(canvas);
    _drawFx(canvas);

    canvas.restore();
  }

  // ───────── base image (instant direct full render) ─────────

  void _drawImage(Canvas canvas, ui.Image img) {
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    const dst = Rect.fromLTWH(0, 0, dw, dh);
    final base = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;
    canvas.drawImageRect(img, src, dst, base);
  }

  // ───────── loading bar (smooth real animation) ─────────

  void _drawLoadingBar(Canvas canvas) {
    final vis = _seg(t, 0.1, 0.4);
    if (vis <= 0) return;

    final track = RRect.fromLTRBR(374.5, 1511.5, 565.5, 1526.5,
        const Radius.circular(7.5));
    canvas.drawRRect(track, Paint()..color = _a(const Color(0xFF47252A), vis));

    final p = _lerp(0.92 * Curves.easeOutCubic.transform(_seg(t, 0.1, 2.2)),
        1.0, finish);
    final w = math.max(14.0, 190.0 * p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(375, 1512, w, 14), const Radius.circular(7)),
      Paint()..color = _a(const Color(0xFFFA3344), vis),
    );
  }

  // ───────── glow / light overlays (immediately alive from start) ─────────

  void _drawFx(Canvas canvas) {
    final fa = _seg(t, 0.1, 0.5);
    if (fa <= 0) return;

    const hl = [Color(0xFFE8F6FF), Color(0xFF9FD8FF), Color(0x006AB8FF)];
    const hlStops = [0.0, 0.35, 1.0];

    // headlights
    _glow(canvas, 595, 998, 70, 36, hl, hlStops, fa * _pulse(t, 2.4));
    _glow(canvas, 856, 1006, 40, 26, hl, hlStops, fa * _pulse(t, 3.0, 1.0));
    _glow(canvas, 143, 988, 42, 30, hl, hlStops, fa * _pulse(t, 3.0, 1.0));

    // phone screen
    _glow(canvas, 468, 778, 55, 70,
        const [Color(0xE6FF5A5A), Color(0x00FF2D3D)], const [0.0, 1.0],
        fa * _pulse(t, 2.4));

    // underline glow + travelling dot
    final under = Path()
      ..moveTo(376, 513)
      ..quadraticBezierTo(540, 505, 700, 517);
    canvas.drawPath(
      under,
      Paint()
        ..color = _a(const Color(0xFFFF2D3D), fa * _pulse(t, 2.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..blendMode = BlendMode.screen
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final dp = (t - 0.2) / 2.2;
    if (dp >= 0) {
      final f = dp - dp.floorToDouble();
      final m = under.computeMetrics().first;
      final tan = m.getTangentForOffset(
          m.length * Curves.easeInOut.transform(f));
      final o = (f < 0.15 ? f / 0.15 : (f > 0.85 ? (1 - f) / 0.15 : 1.0));
      if (tan != null) {
        canvas.drawCircle(
          tan.position,
          7,
          Paint()
            ..color = _a(Colors.white, fa * o)
            ..blendMode = BlendMode.screen
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
    }

    // running light on the ring
    final ring = Path()
      ..addOval(Rect.fromCenter(
          center: const Offset(470, 1183), width: 916, height: 96));
    _runner(canvas, ring, t / 4.0, 0.12, _runPaint(fa, 5));

    // badge borders
    _badge(canvas, const Offset(185, 753), -15, 204, 80, 22, t / 3.0, fa);
    _badge(canvas, const Offset(732, 698), -12, 272, 104, 26,
        (t + 1.5) / 3.0, fa);

    // phone sparks
    const sparks = [
      [505.0, 732.0, 526.0, 718.0, 0.0],
      [510.0, 748.0, 534.0, 746.0, 0.3],
      [505.0, 764.0, 524.0, 776.0, 0.6],
    ];
    for (final s in sparks) {
      final f = ((t - s[4]) / 1.2);
      final p = f - f.floorToDouble();
      final o = p < 0.3 ? p / 0.3 : (1 - p) / 0.7;
      canvas.drawLine(
        Offset(s[0], s[1]),
        Offset(s[2], s[3]),
        Paint()
          ..color = _a(const Color(0xFFFF9A8A), fa * o)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.screen,
      );
    }

    // feature icon ripples
    const cx = [219.0, 470.0, 718.0];
    for (var i = 0; i < 3; i++) {
      for (var k = 0; k < 2; k++) {
        final start = 0.2 + i * 0.3 + k * 0.8;
        if (t < start) continue;
        final f = (t - start) / 2.0;
        final p = f - f.floorToDouble();
        canvas.drawCircle(
          Offset(cx[i], 1334),
          34 * _lerp(1.0, 1.5, p),
          Paint()
            ..color = _a(const Color(0xFFFF3B4A), fa * 0.8 * (1 - p))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..blendMode = BlendMode.screen,
        );
      }
    }

    // embers
    for (final e in embers) {
      if (t < e.delay) continue;
      final f = (t - e.delay) / e.dur;
      final p = f - f.floorToDouble();
      final o = p < 0.15 ? p / 0.15 * 0.9 : (1 - p) / 0.85 * 0.9;
      canvas.drawCircle(
        Offset(e.x + e.dx * p, e.y - 320 * p),
        e.r,
        Paint()
          ..color = _a(const Color(0xFFFF6A5A), fa * o)
          ..blendMode = BlendMode.screen,
      );
    }

    canvas.restore();
  }

  // ───────── drawing primitives ─────────

  void _glow(Canvas c, double cx, double cy, double rx, double ry,
      List<Color> colors, List<double> stops, double alpha) {
    if (alpha <= 0) return;
    final faded = colors.map((col) => _a(col, col.a * alpha)).toList();
    c.save();
    c.translate(cx, cy);
    c.scale(1, ry / rx);
    c.drawCircle(
      Offset.zero,
      rx,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, rx, faded, stops)
        ..blendMode = BlendMode.screen,
    );
    c.restore();
  }

  Paint _runPaint(double fa, double sw) => Paint()
    ..color = _a(const Color(0xFFFFD0D4), fa)
    ..style = PaintingStyle.stroke
    ..strokeWidth = sw
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.screen
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

  void _runner(Canvas c, Path path, double frac, double lenFrac, Paint p) {
    final m = path.computeMetrics().first;
    final total = m.length;
    final start = (frac % 1.0) * total;
    final end = start + lenFrac * total;
    if (end <= total) {
      c.drawPath(m.extractPath(start, end), p);
    } else {
      c.drawPath(m.extractPath(start, total), p);
      c.drawPath(m.extractPath(0, end - total), p);
    }
  }

  void _badge(Canvas c, Offset center, double deg, double w, double h,
      double r, double frac, double fa) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(deg * math.pi / 180);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Radius.circular(r)));
    _runner(c, path, frac, 0.14, _runPaint(fa, 3));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _AyoSplashPainter old) =>
      old.t != t ||
          old.finish != finish ||
          old.image != image ||
          old.bg != bg;
}