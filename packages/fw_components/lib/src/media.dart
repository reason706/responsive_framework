import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// M01 — Responsive image with explicit constraints and loading/error states.
///
/// The caller supplies the [ImageProvider] (asset, network, memory — never
/// `dart:io` in this cross-platform core). [aspectRatio] reserves space
/// before the image arrives, avoiding layout shift. A null [semanticLabel]
/// marks the image decorative.
///
/// Prove offline and failure behavior with fakes before gallery
/// network-image demos: see [FwImage.errorBuilder].
class FwImage extends StatelessWidget {
  const FwImage({
    super.key,
    required this.provider,
    this.semanticLabel,
    this.fit = BoxFit.cover,
    this.aspectRatio,
    this.width,
    this.height,
    this.borderRadius = FwRadius.none,
    this.placeholder,
    this.errorBuilder,
  });

  final ImageProvider provider;

  /// Accessible label. Null means decorative (excluded from semantics).
  final String? semanticLabel;
  final BoxFit fit;

  /// Reserves the aspect ratio before load to avoid layout shift.
  final double? aspectRatio;
  final double? width;
  final double? height;
  final FwRadius borderRadius;

  /// Shown while loading. Defaults to a themed surface block.
  final Widget? placeholder;

  /// Shown on failure. Defaults to a broken-image indicator that keeps the
  /// accessible label.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    Widget image = Image(
      image: provider,
      fit: fit,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: theme.colors.of(FwColorRole.surfaceMuted),
              alignment: Alignment.center,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colors.of(FwColorRole.primary),
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        if (errorBuilder != null) return errorBuilder!(context, error);
        return Container(
          width: width,
          height: height,
          color: theme.colors.of(FwColorRole.surfaceMuted),
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image,
            color: theme.colors.of(FwColorRole.textSubtle),
          ),
        );
      },
    );
    if (aspectRatio != null) {
      assert(aspectRatio! > 0, 'Aspect ratio must be positive.');
      image = AspectRatio(aspectRatio: aspectRatio!, child: image);
    }
    if (borderRadius != FwRadius.none) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(theme.radii.of(borderRadius)),
        child: image,
      );
    }
    return image;
  }
}

/// Avatar sizes: fixed bounded diameters in logical pixels.
enum FwAvatarSize {
  xs(24),
  sm(32),
  md(40),
  lg(56),
  xl(72);

  const FwAvatarSize(this.diameter);
  final double diameter;
}

enum FwAvatarShape { circle, rounded }

/// Presence status. The dot color is never the only signal — [statusLabel]
/// is announced to assistive technology.
enum FwAvatarStatus { online, away, busy, offline }

/// M03 — Avatar with image/initials/icon fallback.
///
/// Fallback order: [provider] image → [initials] (caller-provided,
/// preferred) → initials derived from [name] via grapheme clusters →
/// [icon]. Never naive string indexing: the derivation uses the
/// `characters` package. Diameter is fixed and bounded per [size].
class FwAvatar extends StatelessWidget {
  const FwAvatar({
    super.key,
    this.provider,
    this.initials,
    this.name,
    this.icon = Icons.person,
    this.size = FwAvatarSize.md,
    this.shape = FwAvatarShape.circle,
    this.status,
    this.statusLabel,
    this.semanticLabel,
  }) : assert(
         status == null || statusLabel != null,
         'Status must have text meaning: provide statusLabel.',
       );

  final ImageProvider? provider;

  /// Caller-provided initials. Preferred over derivation.
  final String? initials;

  /// Full name; initials are derived from grapheme clusters.
  final String? name;
  final IconData icon;
  final FwAvatarSize size;
  final FwAvatarShape shape;
  final FwAvatarStatus? status;

  /// Accessible text for the status, e.g. "Online".
  final String? statusLabel;
  final String? semanticLabel;

  /// Derives initials from [name]: first grapheme of the first two words,
  /// uppercased. Not naive string indexing.
  static String initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final picked = words.take(2).map((w) => w.characters.firstOrNull ?? '');
    return picked.join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final diameter = size.diameter;
    final radius = shape == FwAvatarShape.circle
        ? diameter / 2
        : theme.radii.of(FwRadius.md);

    Widget content;
    if (provider != null) {
      content = FwImage(
        provider: provider!,
        fit: BoxFit.cover,
        width: diameter,
        height: diameter,
        semanticLabel: null, // The avatar carries the label, not the image.
      );
    } else {
      final text = initials ?? (name != null ? initialsFor(name!) : null);
      content = Container(
        width: diameter,
        height: diameter,
        color: colors.of(FwColorRole.secondaryContainer),
        alignment: Alignment.center,
        child: text != null
            ? Text(
                text,
                style: theme.typeScale
                    .resolve(FwTextRole.label, context)
                    .copyWith(
                      color: colors.of(FwColorRole.onSecondaryContainer),
                    ),
              )
            : Icon(
                icon,
                size: diameter * 0.55,
                color: colors.of(FwColorRole.onSecondaryContainer),
              ),
      );
    }

    Widget avatar = SizedBox(
      width: diameter,
      height: diameter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );

    if (status != null) {
      final statusColor = switch (status!) {
        FwAvatarStatus.online => colors.of(FwColorRole.success),
        FwAvatarStatus.away => colors.of(FwColorRole.warning),
        FwAvatarStatus.busy => colors.of(FwColorRole.error),
        FwAvatarStatus.offline => colors.of(FwColorRole.textSubtle),
      };
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: diameter * 0.32,
              height: diameter * 0.32,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.of(FwColorRole.surface),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final label = [
      if (semanticLabel != null) semanticLabel,
      if (statusLabel != null) statusLabel,
    ].join(', ');
    if (label.isEmpty) {
      return ExcludeSemantics(child: avatar);
    }
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: avatar,
    );
  }
}

/// M05 — Icon with size, semantic color role, and decorative/meaningful
/// distinction.
///
/// Interactive behavior belongs to [FwIconButton] (A02); this is the
/// presentational primitive. A null [semanticLabel] marks the icon
/// decorative. No vendor icon pack is forced — any [IconData] works.
class FwIcon extends StatelessWidget {
  const FwIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;

  /// Glyph size in logical pixels.
  final double size;

  /// Semantic color. Defaults to the ambient icon color.
  final FwColorRole? color;

  /// Accessible label. Null means decorative (excluded from semantics).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: size,
      color: color == null ? null : context.fwTheme.colors.of(color!),
    );
    if (semanticLabel == null) {
      return ExcludeSemantics(child: iconWidget);
    }
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: iconWidget,
    );
  }
}

/// M02 — Figure: image with caption, optional credit and action.
///
/// Composes [FwImage] and text. When [semanticLabel] (or [caption]) is
/// provided, the inner image is excluded from semantics so screen readers
/// hear the figure label once — never the image and caption duplicated.
class FwFigure extends StatelessWidget {
  const FwFigure({
    super.key,
    required this.image,
    this.caption,
    this.captionRole = FwTextRole.caption,
    this.credit,
    this.action,
    this.semanticLabel,
    this.gap,
  });

  /// The image; typically [FwImage].
  final Widget image;

  /// Caption text; may wrap independently of the image.
  final String? caption;
  final FwTextRole captionRole;

  /// Optional credit line under the caption (photographer, source).
  final String? credit;

  /// Optional action, e.g. a view-fullscreen button.
  final Widget? action;

  /// Accessible label for the whole figure. Defaults to [caption].
  final String? semanticLabel;
  final FwSpace? gap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final spacing = theme.spaceScale.of(gap ?? FwSpace.s2, context);
    final label = semanticLabel ?? caption;
    final Widget img = label == null ? image : ExcludeSemantics(child: image);
    final captionStyle = theme.typeScale.resolve(captionRole, context);
    // When the caption text is identical to the figure label it would be
    // announced twice inside the single figure node; exclude the redundant
    // copy. A caption that differs from an explicit label stays navigable.
    final Widget? captionWidget = caption == null
        ? null
        : caption == label
        ? ExcludeSemantics(child: Text(caption!, style: captionStyle))
        : Text(caption!, style: captionStyle);
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          img,
          if (captionWidget != null || credit != null || action != null) ...[
            SizedBox(height: spacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (captionWidget != null) captionWidget,
                      if (credit != null)
                        Text(
                          credit!,
                          style: theme.typeScale
                              .resolve(FwTextRole.caption, context)
                              .copyWith(
                                color: theme.colors.of(FwColorRole.textSubtle),
                              ),
                        ),
                    ],
                  ),
                ),
                if (action != null) ...[SizedBox(width: spacing), action!],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// M04 — Avatar group: overlapping avatars with a capped visible count.
///
/// Later avatars stack behind earlier ones (first avatar on top). The
/// overflow chip shows `+N`; when [onOverflowTap] is set it is a real
/// button, otherwise a labelled indicator. Every avatar keeps its own
/// semantics so the name list is preserved for assistive technology —
/// overlap never hides required actions.
class FwAvatarGroup extends StatelessWidget {
  const FwAvatarGroup({
    super.key,
    required this.children,
    this.maxVisible = 5,
    this.size = FwAvatarSize.md,
    this.overlap = 0.35,
    this.onOverflowTap,
    this.overflowSemantics,
    this.semanticLabel,
  }) : assert(maxVisible > 0, 'maxVisible must be positive'),
       assert(overlap >= 0 && overlap < 1, 'overlap must be in [0, 1)');

  final List<FwAvatar> children;

  /// Maximum avatars painted before the `+N` overflow chip.
  final int maxVisible;
  final FwAvatarSize size;

  /// Fraction of the diameter each avatar covers the previous one.
  final double overlap;

  /// Optional overflow action; null renders a non-interactive indicator.
  final VoidCallback? onOverflowTap;

  /// Accessible label for the overflow chip, e.g. "3 more members".
  final String? overflowSemantics;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final diameter = size.diameter;
    final step = diameter * (1 - overlap);
    final visible = children.take(maxVisible).toList();
    final overflow = children.length - visible.length;

    Widget avatarChip(FwAvatar avatar) => SizedBox(
      width: diameter,
      height: diameter,
      child: FittedBox(fit: BoxFit.contain, child: avatar),
    );

    Widget overflowChip() {
      final label = overflowSemantics ?? '+$overflow more';
      final chip = Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colors.of(FwColorRole.surfaceContainerHigh),
          border: Border.all(
            color: theme.colors.of(FwColorRole.surface),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '+$overflow',
          style: theme.typeScale
              .resolve(FwTextRole.label, context)
              .copyWith(color: theme.colors.of(FwColorRole.onSurface)),
        ),
      );
      if (onOverflowTap == null) {
        return Semantics(label: label, child: chip);
      }
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onOverflowTap,
          customBorder: const CircleBorder(),
          child: chip,
        ),
      );
    }

    final tiles = <Widget>[
      for (final avatar in visible) avatarChip(avatar),
      if (overflow > 0) overflowChip(),
    ];
    final totalWidth = diameter + (tiles.length - 1) * step;
    // Paint back-to-front so the first avatar ends up on top.
    final group = SizedBox(
      width: totalWidth,
      height: diameter,
      child: Stack(
        children: [
          for (var i = tiles.length - 1; i >= 0; i--)
            PositionedDirectional(start: i * step, top: 0, child: tiles[i]),
        ],
      ),
    );
    if (semanticLabel == null) return group;
    return Semantics(label: semanticLabel, child: group);
  }
}

// ---------------------------------------------------------------------------
// Carousel (M09).
// ---------------------------------------------------------------------------

/// Image/content carousel (M09) with page indicators.
///
/// A controlled [PageView] with dot indicators; tapping a dot jumps to
/// that page. Pages announce "Page X of N". For onboarding-specific flows
/// (skip/next actions) use [FwOnboardingFlow].
class FwCarousel extends StatefulWidget {
  const FwCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.initialPage = 0,
    this.onPageChanged,
    this.showIndicators = true,
    this.aspectRatio = 16 / 9,
    this.indicatorSemanticLabel,
  }) : assert(itemCount > 0, 'FwCarousel needs at least one item.');

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// External controller for programmatic paging; one is created if null.
  final PageController? controller;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final bool showIndicators;

  /// Aspect ratio of the page viewport.
  final double aspectRatio;

  /// Accessible label for an indicator dot; defaults to "Go to page X".
  final String Function(int index)? indicatorSemanticLabel;

  @override
  State<FwCarousel> createState() => _FwCarouselState();
}

class _FwCarouselState extends State<FwCarousel> {
  PageController? _internalController;
  int _index = 0;

  PageController get _controller =>
      widget.controller ??
      (_internalController ??= PageController(initialPage: widget.initialPage));

  @override
  void initState() {
    super.initState();
    _index = widget.initialPage;
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.itemCount,
            onPageChanged: (i) {
              setState(() => _index = i);
              widget.onPageChanged?.call(i);
            },
            itemBuilder: (context, i) => Semantics(
              label: 'Page ${i + 1} of ${widget.itemCount}',
              liveRegion: i == _index,
              child: widget.itemBuilder(context, i),
            ),
          ),
        ),
        if (widget.showIndicators && widget.itemCount > 1) ...[
          SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.itemCount; i++)
                _IndicatorDot(
                  active: i == _index,
                  semanticLabel:
                      widget.indicatorSemanticLabel?.call(i) ??
                      'Go to page ${i + 1}',
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: theme.motion.durationFor(
                      context,
                      FwMotionSpeed.fast,
                    ),
                    curve: theme.motion.curveFor(context),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Indicator dot; the active dot is wider and uses the primary color.
class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({
    required this.active,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool active;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s1, context)),
          child: AnimatedContainer(
            duration: theme.motion.durationFor(context, FwMotionSpeed.fast),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? colors.of(FwColorRole.primary)
                  : colors.of(FwColorRole.textMuted).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(
                theme.radii.of(FwRadius.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo viewer (M07+).
// ---------------------------------------------------------------------------

/// Zoomable photo viewer (M07+): pinch-zoom and double-tap to zoom, built
/// on [InteractiveViewer]. Zero platform risk — pure Flutter gestures.
///
/// The [child] is typically an [FwImage]. Zoom state is internal; the
/// viewer resets when the widget is rebuilt with a different child.
class FwPhotoViewer extends StatefulWidget {
  const FwPhotoViewer({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 4.0,
    this.doubleTapScale = 2.0,
    this.semanticLabel,
  });

  final Widget child;
  final double minScale;
  final double maxScale;

  /// Scale toggled by double-tap.
  final double doubleTapScale;

  /// Accessible label for the viewer.
  final String? semanticLabel;

  @override
  State<FwPhotoViewer> createState() => _FwPhotoViewerState();
}

class _FwPhotoViewerState extends State<FwPhotoViewer> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final details = _doubleTapDetails;
    if (details == null) return;
    final current = _controller.value.getMaxScaleOnAxis();
    if (current > widget.minScale + 0.01) {
      _controller.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      final scale = widget.doubleTapScale;
      _controller.value = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (scale - 1),
          -position.dy * (scale - 1),
          0.0,
          1.0,
        )
        ..scaleByDouble(scale, scale, scale, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? 'Image viewer. Double tap to zoom.',
      child: GestureDetector(
        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          child: widget.child,
        ),
      ),
    );
  }
}
