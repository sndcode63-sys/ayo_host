import 'package:flutter/material.dart';

/// Comprehensive Animation Utilities for AYO Host app.
/// Provides buttery-smooth route transitions, tap feedback, and entrance animations.
class AnimationUtils {
  AnimationUtils._();

  /// Standard duration for ultra-smooth UI animations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration standardDuration = Duration(milliseconds: 320);
  static const Duration pageDuration = Duration(milliseconds: 380);
  static const Duration splashExitDuration = Duration(milliseconds: 450);

  /// Natural, organic easing curves
  static const Curve smoothCurve = Curves.fastEaseInToSlowEaseOut;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve bounceCurve = Curves.easeOutBack;

  /// Custom PageRoute that fades and subtly zooms in (perfect for Splash -> Home / Auth transitions).
  static Route<T> fadeThroughRoute<T>(Widget page, {Duration? duration, RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? splashExitDuration,
      reverseTransitionDuration: duration ?? splashExitDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: enterCurve),
        );

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }

  /// Custom PageRoute with smooth horizontal slide and subtle parallax.
  static Route<T> smoothSlideRoute<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: pageDuration,
      reverseTransitionDuration: pageDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return buildSmoothTransition(animation, secondaryAnimation, child);
      },
    );
  }

  /// Custom PageRoute for bottom sheet modals / slide-up details.
  static Route<T> slideUpRoute<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: pageDuration,
      reverseTransitionDuration: pageDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: enterCurve));

        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
    );
  }

  /// Smooth transition builder for Theme `pageTransitionsTheme`
  static Widget buildSmoothTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Primary page entering from the right
    final enterSlide = Tween<Offset>(
      begin: const Offset(0.18, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: smoothCurve,
    ));

    final enterFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    ));

    // Secondary (underneath) page receding with subtle parallax
    final exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.06, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: exitCurve,
    ));

    final exitFade = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeIn,
    ));

    return SlideTransition(
      position: exitSlide,
      child: FadeTransition(
        opacity: exitFade,
        child: SlideTransition(
          position: enterSlide,
          child: FadeTransition(
            opacity: enterFade,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Smooth navigate with push
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, smoothSlideRoute<T>(page));
  }

  /// Smooth navigate replacing current screen (with seamless fade-through)
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, TO>(context, fadeThroughRoute<T>(page));
  }

  /// Smooth navigate clearing backstack (e.g. from Splash or Auth to Home)
  static Future<T?> pushAndRemoveUntil<T>(BuildContext context, Widget page) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      fadeThroughRoute<T>(page),
      (route) => false,
    );
  }
}

/// Custom PageTransitionsBuilder that gives every push/pop throughout the entire app
/// a butter-smooth 60/120fps fluid slide and fade.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimationUtils.buildSmoothTransition(
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Tactile button/card press feedback animation (scales down slightly on press).
class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final HitTestBehavior behavior;

  const ScaleOnPress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.965,
    this.duration = const Duration(milliseconds: 110),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) _ctrl.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Smooth fade and slide entrance for lists, cards, and page sections.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.beginOffset = const Offset(0.0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Gentle breathing / pulse effect for badges, tags, and status dots.
class PulseEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1600),
    this.minScale = 0.97,
    this.maxScale = 1.03,
  });

  @override
  State<PulseEffect> createState() => _PulseEffectState();
}

class _PulseEffectState extends State<PulseEffect> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}
