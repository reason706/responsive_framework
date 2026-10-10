/// Skeletonizer-style auto bones (stretch): render bone placeholders from a
/// real child tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fw_core/fw_core.dart';

/// Auto skeleton: paints bone placeholders derived from [child]'s real
/// layout instead of hand-maintained shimmer duplicates (the skeletonizer
/// trick).
///
/// The child is laid out normally but never painted; each leaf [RenderBox]
/// becomes a rounded bone rect in the token skeleton color. Containers,
/// rows, and columns contribute no bone of their own — their children do —
/// so bones hug the content shape.
///
/// This is intentionally static (no shimmer sweep); pair with [FwSkeleton]'s
/// shimmer or an [AnimatedSwitcher] when motion is wanted. Bones ignore
/// pointer events and keep the child's semantics: while loading, apps
/// typically swap the whole subtree, so manage announcements at that level.
///
/// Example:
/// ```dart
/// isLoading
///   ? FwAutoSkeleton(
///       child: Column(
///         children: [Text(user.name), Text(user.bio)],
///       ),
///     )
///   : ProfileCard(user: user);
/// ```
class FwAutoSkeleton extends SingleChildRenderObjectWidget {
  const FwAutoSkeleton({
    super.key,
    required Widget super.child,
    this.boneColorRole = FwColorRole.surfaceContainerHighest,
    this.borderRadius = 6,
  });

  /// Token role for the bone fill. No raw colors in the public API.
  final FwColorRole boneColorRole;

  /// Corner radius of each bone.
  final double borderRadius;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAutoSkeleton(
    boneColor: context.fwTheme.colors.of(boneColorRole),
    borderRadius: borderRadius,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAutoSkeleton renderObject,
  ) {
    renderObject
      ..boneColor = context.fwTheme.colors.of(boneColorRole)
      ..borderRadius = borderRadius;
  }
}

class _RenderAutoSkeleton extends RenderProxyBox {
  _RenderAutoSkeleton({required Color boneColor, required double borderRadius})
    : _boneColor = boneColor,
      _borderRadius = borderRadius;

  Color _boneColor;
  set boneColor(Color value) {
    if (value == _boneColor) return;
    _boneColor = value;
    markNeedsPaint();
  }

  double _borderRadius;
  set borderRadius(double value) {
    if (value == _borderRadius) return;
    _borderRadius = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final bones = <Rect>[];
    _collectBones(child, bones);
    if (bones.isEmpty) {
      bones.add(Offset.zero & size);
    }
    final paint = Paint()..color = _boneColor;
    for (final bone in bones) {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          bone.shift(offset),
          Radius.circular(_borderRadius),
        ),
        paint,
      );
    }
  }

  /// Collects one rect per leaf [RenderBox]: boxes that only contain other
  /// boxes contribute no bone of their own.
  void _collectBones(RenderObject node, List<Rect> out) {
    if (!node.attached) return;
    var hasBoxChild = false;
    node.visitChildren((child) {
      if (child is RenderBox) {
        if (child.hasSize && !child.size.isEmpty) {
          hasBoxChild = true;
        }
        _collectBones(child, out);
      }
    });
    if (!hasBoxChild &&
        node is RenderBox &&
        node.hasSize &&
        !node.size.isEmpty) {
      out.add(
        MatrixUtils.transformRect(
          node.getTransformTo(this),
          Offset.zero & node.size,
        ),
      );
    }
  }
}
