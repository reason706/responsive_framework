import 'package:flutter/material.dart';

/// Badge placement (+B12).
///
/// Overlays a badge (typically [FwBadge]) on a [child] — an icon, avatar,
/// or button — at a corner. [alignment] picks the corner; [offset] nudges
/// the badge (positive values push it outward, into the margin).
///
/// The badge is announced after the child's semantics via [IndexSemantics].
class FwBadgePlacement extends StatelessWidget {
  const FwBadgePlacement({
    super.key,
    required this.child,
    required this.badge,
    this.alignment = Alignment.topRight,
    this.offset = Offset.zero,
  });

  /// The widget the badge annotates.
  final Widget child;

  /// The badge overlay (usually [FwBadge]).
  final Widget badge;

  /// Corner for the badge.
  final AlignmentGeometry alignment;

  /// Nudge applied after alignment. Positive x pushes right, positive y
  /// pushes down (outward for top-right).
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Anchor the badge's center to the chosen corner, then nudge.
              final align = alignment.resolve(Directionality.of(context));
              final dx = (align.x + 1) / 2 * constraints.maxWidth;
              final dy = (align.y + 1) / 2 * constraints.maxHeight;
              return Stack(
                children: [
                  Positioned(
                    left: dx + offset.dx,
                    top: dy + offset.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: badge,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
