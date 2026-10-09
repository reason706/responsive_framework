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
