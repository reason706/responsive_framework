import 'package:flutter/material.dart';

/// Motion speeds for component transitions.
///
/// `xs` (micro-interactions: ripples, icon flips) and `xl` (large
/// choreographed transitions: page/sheet entrances) extend the original
/// fast/medium/slow core. Durations collapse to zero under reduced motion
/// unless the theme opts out.
enum FwMotionSpeed { xs, fast, medium, slow, xl }

/// A spring configuration for physics-based motion.
///
/// Stiffness/damping follow [SpringDescription] conventions; [toDescription]
/// converts directly. Springs are for continuous gestures and playful
/// entrances — never for conveying validation or busy state, which must not
/// wait on animation.
@immutable
class FwSpring {
  const FwSpring({this.mass = 1, this.stiffness = 170, this.damping = 26});

  /// Standard spring: quick settle, slight overshoot.
  static const standard = FwSpring();

  /// Calmer spring for large surfaces: less overshoot, slower settle.
  static const gentle = FwSpring(mass: 1, stiffness: 120, damping: 20);

  final double mass;
  final double stiffness;
  final double damping;

  SpringDescription toDescription() =>
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping);
}

/// Durations, curves, springs, and the reduced-motion policy.
///
/// When [respectReducedMotion] is true (the default) and the platform
/// reports reduced motion (`MediaQuery.disableAnimations`), durations
/// resolve to zero and curves to linear: the UI still changes state, it
/// just doesn't animate there. Never stop conveying that a task is busy
/// merely because animation is disabled.
@immutable
class FwMotion {
  const FwMotion({
    this.xs = const Duration(milliseconds: 80),
    this.fast = const Duration(milliseconds: 120),
    this.medium = const Duration(milliseconds: 200),
    this.slow = const Duration(milliseconds: 320),
    this.xl = const Duration(milliseconds: 480),
    this.standardCurve = Curves.easeOutCubic,
    this.emphasizedCurve = Curves.easeInOutCubic,
    this.spring = FwSpring.standard,
    this.gentleSpring = FwSpring.gentle,
    this.respectReducedMotion = true,
  });

  final Duration xs;
  final Duration fast;
  final Duration medium;
  final Duration slow;
  final Duration xl;
  final Curve standardCurve;
  final Curve emphasizedCurve;

  /// Default spring for gesture-driven and playful motion.
  final FwSpring spring;

  /// Calmer spring for large-surface entrances.
  final FwSpring gentleSpring;
  final bool respectReducedMotion;

  bool _reduced(BuildContext context) =>
      respectReducedMotion && MediaQuery.disableAnimationsOf(context);

  /// Duration for [speed], or zero under reduced motion.
  Duration durationFor(BuildContext context, FwMotionSpeed speed) {
    if (_reduced(context)) return Duration.zero;
    return switch (speed) {
      FwMotionSpeed.xs => xs,
      FwMotionSpeed.fast => fast,
      FwMotionSpeed.medium => medium,
      FwMotionSpeed.slow => slow,
      FwMotionSpeed.xl => xl,
    };
  }

  /// Animation curve, or linear under reduced motion.
  Curve curveFor(BuildContext context, {bool emphasized = false}) {
    if (_reduced(context)) return Curves.linear;
    return emphasized ? emphasizedCurve : standardCurve;
  }

  FwMotion copyWith({
    Duration? xs,
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Duration? xl,
    Curve? standardCurve,
    Curve? emphasizedCurve,
    FwSpring? spring,
    FwSpring? gentleSpring,
    bool? respectReducedMotion,
  }) => FwMotion(
    xs: xs ?? this.xs,
    fast: fast ?? this.fast,
    medium: medium ?? this.medium,
    slow: slow ?? this.slow,
    xl: xl ?? this.xl,
    standardCurve: standardCurve ?? this.standardCurve,
    emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
    spring: spring ?? this.spring,
    gentleSpring: gentleSpring ?? this.gentleSpring,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );
}
