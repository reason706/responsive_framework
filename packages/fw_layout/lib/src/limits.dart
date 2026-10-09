import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// L07 — Aspect ratio with a validated positive ratio.
///
/// Thin wrapper over [AspectRatio]: the contract is that ratios are
/// positive (asserted) and unbounded axes are the caller's documented
/// responsibility.
class FwAspectRatio extends StatelessWidget {
  const FwAspectRatio({
    super.key,
    required this.aspectRatio,
    required this.child,
  }) : assert(aspectRatio > 0, 'Aspect ratio must be positive.');

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AspectRatio(aspectRatio: aspectRatio, child: child);
}

/// L07 — Constrained box with typed lengths.
///
/// Bounds resolve against the root, so `maxWidth: FwRem(40)` means 40rem
/// regardless of the text scaler. Unspecified bounds stay unbounded —
/// document which axis your parent bounds.
class FwLimits extends StatelessWidget {
  const FwLimits({
    super.key,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    required this.child,
  });

  final FwLength? minWidth;
  final FwLength? maxWidth;
  final FwLength? minHeight;
  final FwLength? maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minWidth?.resolve(context) ?? 0,
      maxWidth: maxWidth?.resolve(context) ?? double.infinity,
      minHeight: minHeight?.resolve(context) ?? 0,
      maxHeight: maxHeight?.resolve(context) ?? double.infinity,
    ),
    child: child,
  );
}
