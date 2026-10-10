import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'auto_skeleton.dart';

// ---------------------------------------------------------------------------
// Shimmer (P4): animated sweep for skeleton loading states.
// ---------------------------------------------------------------------------

/// Shimmer sweep (P4): an animated highlight that sweeps across [child],
/// completing the skeleton loading pattern.
///
/// This is the retrospective §12 "shimmer pass" on [FwAutoSkeleton]:
/// compose them for auto-derived bones with motion —
/// `FwShimmer(child: FwAutoSkeleton(child: realTree))` — or wrap any
/// placeholder ([FwSkeleton], custom bones).
///
/// Motion honors the platform reduced-motion setting: under
/// [MediaQuery.disableAnimations] the sweep is suppressed and the child
/// renders statically. Shimmer is decorative — semantics are excluded so
/// screen readers don't announce a loading shimmer as content.
///
/// Demand note: retrospective §12 deferral ("`FwAutoSkeleton` shimmer pass").
class FwShimmer extends StatefulWidget {
  const FwShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColorRole = FwColorRole.surfaceContainerHighest,
    this.highlightColorRole = FwColorRole.surface,
  });

  /// The placeholder the sweep travels across.
  final Widget child;

  /// Master switch. False renders [child] statically (also useful in tests).
  final bool enabled;

  /// One full sweep duration.
  final Duration duration;

  /// Token role for the sweep's base. No raw colors in the public API.
  final FwColorRole baseColorRole;

  /// Token role for the sweep's highlight band.
  final FwColorRole highlightColorRole;

  /// Convenience: shimmering auto bones derived from a real widget tree.
  factory FwShimmer.bones({
    Key? key,
    required Widget child,
    bool enabled = true,
    Duration duration = const Duration(milliseconds: 1500),
    FwColorRole baseColorRole = FwColorRole.surfaceContainerHighest,
    FwColorRole highlightColorRole = FwColorRole.surface,
    FwColorRole boneColorRole = FwColorRole.surfaceContainerHighest,
    double borderRadius = 6,
  }) => FwShimmer(
    key: key,
    enabled: enabled,
    duration: duration,
    baseColorRole: baseColorRole,
    highlightColorRole: highlightColorRole,
    child: FwAutoSkeleton(
      boneColorRole: boneColorRole,
      borderRadius: borderRadius,
      child: child,
    ),
  );

  @override
  State<FwShimmer> createState() => _FwShimmerState();
}

class _FwShimmerState extends State<FwShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(FwShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final base = colors.of(widget.baseColorRole);
    final highlight = colors.of(widget.highlightColorRole);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animate = widget.enabled && !reduceMotion;

    Widget child = widget.child;
    if (animate) {
      child = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: [
              _controller.value - 0.3,
              _controller.value,
              _controller.value + 0.3,
            ].map((s) => s.clamp(0.0, 1.0)).toList(),
          ).createShader(bounds),
          child: child,
        ),
        child: child,
      );
    }
    return ExcludeSemantics(child: child);
  }
}
