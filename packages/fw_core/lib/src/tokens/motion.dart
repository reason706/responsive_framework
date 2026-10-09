import 'package:flutter/material.dart';

/// Motion speeds for component transitions.
enum FwMotionSpeed { fast, medium, slow }

/// Durations, curves, and the reduced-motion policy.
///
/// When [respectReducedMotion] is true (the default) and the platform
/// reports reduced motion (`MediaQuery.disableAnimations`), durations
/// resolve to zero and curves to linear: the UI still changes state, it
/// just doesn't animate there. Never stop conveying that a task is busy
/// merely because animation is disabled.
@immutable
class FwMotion {
  const FwMotion({
    this.fast = const Duration(milliseconds: 120),
    this.medium = const Duration(milliseconds: 200),
    this.slow = const Duration(milliseconds: 320),
    this.standardCurve = Curves.easeOutCubic,
    this.emphasizedCurve = Curves.easeInOutCubic,
    this.respectReducedMotion = true,
  });

  final Duration fast;
  final Duration medium;
  final Duration slow;
  final Curve standardCurve;
  final Curve emphasizedCurve;
  final bool respectReducedMotion;

  bool _reduced(BuildContext context) =>
      respectReducedMotion && MediaQuery.disableAnimationsOf(context);

  /// Duration for [speed], or zero under reduced motion.
  Duration durationFor(BuildContext context, FwMotionSpeed speed) {
    if (_reduced(context)) return Duration.zero;
    return switch (speed) {
      FwMotionSpeed.fast => fast,
      FwMotionSpeed.medium => medium,
      FwMotionSpeed.slow => slow,
    };
  }

  /// Animation curve, or linear under reduced motion.
  Curve curveFor(BuildContext context, {bool emphasized = false}) {
    if (_reduced(context)) return Curves.linear;
    return emphasized ? emphasizedCurve : standardCurve;
  }

  FwMotion copyWith({
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Curve? standardCurve,
    Curve? emphasizedCurve,
    bool? respectReducedMotion,
  }) => FwMotion(
    fast: fast ?? this.fast,
    medium: medium ?? this.medium,
    slow: slow ?? this.slow,
    standardCurve: standardCurve ?? this.standardCurve,
    emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );
}
