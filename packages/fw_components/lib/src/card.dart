import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// D01 — Card variants.
enum FwCardVariant {
  /// Surface with a resting shadow; the default.
  elevated,

  /// Surface with a border and no shadow.
  outlined,

  /// Muted container fill, no border or shadow.
  filled,
}

/// D01 — Card with header/media/content/actions slots.
///
/// Composition over configuration: each slot is a widget, and the card only
/// arranges them. [media] renders full-bleed (edge to edge); the other slots
/// share the card [padding]. This widget is informational — it is never
/// implicitly tappable. For a tappable card, wrap it in [FwInteractiveCard].
class FwCard extends StatelessWidget {
  const FwCard({
    super.key,
    this.header,
    this.media,
    this.content,
    this.actions,
    this.variant = FwCardVariant.elevated,
    this.padding = FwSpace.s4,
    this.semanticLabel,
  });

  final Widget? header;
  final Widget? media;
  final Widget? content;
  final Widget? actions;
  final FwCardVariant variant;
  final FwSpace padding;

  /// Accessible label for the card as a whole. Null marks it decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final radius = BorderRadius.circular(theme.radii.of(FwRadius.lg));

    // Material elevation approximates the token shadow: the sm level's
    // blur radius doubles as the elevation value.
    final (Color fill, double elevation, BorderSide side) = switch (variant) {
      FwCardVariant.elevated => (
        colors.of(FwColorRole.surface),
        theme.shadows.sm.firstOrNull?.blurRadius ?? 0,
        BorderSide.none,
      ),
      FwCardVariant.outlined => (
        colors.of(FwColorRole.surface),
        0.0,
        BorderSide(color: colors.of(FwColorRole.border)),
      ),
      FwCardVariant.filled => (
        colors.of(FwColorRole.surfaceContainerLow),
        0.0,
        BorderSide.none,
      ),
    };

    final bodySlots = [
      if (header != null) header!,
      if (content != null) content!,
      if (actions != null) actions!,
    ];

    Widget card = Material(
      color: fill,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: radius, side: side),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (media != null) media!,
            if (bodySlots.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(theme.spaceScale.of(padding, context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.spaceScale.of(FwSpace.s3, context),
                  children: bodySlots,
                ),
              ),
          ],
        ),
      ),
    );

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        excludeSemantics: false,
        child: card,
      );
    }
    return card;
  }
}

/// D01 — Explicit interactive wrapper for cards.
///
/// Tapping anywhere on the child invokes [onTap] — except on nested
/// interactive elements (buttons, links, icon buttons), which keep their own
/// handlers: the gesture arena gives the innermost tappable priority, so a
/// nested action never double-fires the card. Card content must not double
/// as an implicit button — reaching for this wrapper is the explicit choice.
///
/// [semanticLabel] describes the destination ("Open article: X"), not the
/// card's visible text.
class FwInteractiveCard extends StatelessWidget {
  const FwInteractiveCard({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final effectiveOnTap = enabled ? onTap : null;
    return Semantics(
      button: true,
      enabled: effectiveOnTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveOnTap,
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.lg)),
          child: child,
        ),
      ),
    );
  }
}
