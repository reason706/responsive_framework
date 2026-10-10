import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'feedback.dart';

// ---------------------------------------------------------------------------
// Banner (P4): persistent page-level messaging.
// ---------------------------------------------------------------------------

/// Banner (P4): a persistent, full-width messaging strip for page-level
/// status — maintenance windows, feature announcements, quota warnings.
///
/// Distinct from [FwAlert] (an inline card with a left intent border) and
/// from toasts (transient overlays): a banner is *page chrome*. It spans the
/// full content width, carries an intent-tinted background, and stays until
/// dismissed or the condition clears. The Carbon/Atlassian banner pattern.
///
/// Demand note: improvement-plan-2 §4 P4 slate — "Carbon/Atlassian pattern;
/// persistent page-level messaging distinct from toast/alert".
///
/// Announcements are opt-in via [announce]: set it when the banner is added
/// dynamically. Do not announce on every rebuild.
class FwBanner extends StatelessWidget {
  const FwBanner({
    super.key,
    required this.intent,
    required this.title,
    this.body,
    this.action,
    this.onDismiss,
    this.announce = false,
    this.elevation = 0,
    this.tonal = true,
  }) : assert(
         elevation >= 0 && elevation <= 5,
         'elevation must be an FwElevation level 0–5',
       );

  /// Severity → icon + tint. Reuses [FwAlertIntent] so banner/alert/toast
  /// intents stay visually consistent across the framework.
  final FwAlertIntent intent;

  /// Bold headline. Keep under ~80 characters; longer copy goes in [body].
  final String title;

  /// Optional supporting text.
  final String? body;

  /// Optional action slot (typically a text button).
  final Widget? action;

  /// If non-null, a close button with a "Dismiss" tooltip is shown.
  final VoidCallback? onDismiss;

  /// When true, the banner is a live region for screen readers.
  final bool announce;

  /// Elevation level 0–5. Banners sit in page flow, so the M3-correct
  /// default is 0 (flat); raise only when overlapping other content.
  final int elevation;

  /// Whether the M3 surface tint applies at [elevation].
  final bool tonal;

  (Color, IconData) _style(FwColors colors) => switch (intent) {
    FwAlertIntent.success => (
      colors.of(FwColorRole.success),
      Icons.check_circle_outline,
    ),
    FwAlertIntent.info => (colors.of(FwColorRole.info), Icons.info_outline),
    FwAlertIntent.warning => (
      colors.of(FwColorRole.warning),
      Icons.warning_amber_outlined,
    ),
    FwAlertIntent.danger => (colors.of(FwColorRole.error), Icons.error_outline),
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final space = theme.spaceScale;
    final (intentColor, icon) = _style(colors);

    // Intent tint blended over the surface — derived from tokens only.
    final fill = Color.alphaBlend(
      intentColor.withValues(alpha: theme.opacities.of(FwOpacity.medium) * 0.3),
      colors.of(FwColorRole.surface),
    );

    final banner = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: space.of(FwSpace.s4, context),
        vertical: space.of(FwSpace.s3, context),
      ),
      decoration: const FwElevation().decoration(
        context,
        elevation,
        tonal: tonal,
        color: fill,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: space.of(FwSpace.s1, context) / 2),
            child: Icon(
              icon,
              color: intentColor,
              size: theme.iconSizes.of(FwIconSize.md),
            ),
          ),
          SizedBox(width: space.of(FwSpace.s3, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.typeScale.resolve(FwTextRole.label, context),
                ),
                if (body != null) ...[
                  SizedBox(height: space.of(FwSpace.s1, context)),
                  Text(
                    body!,
                    style: theme.typeScale.resolve(FwTextRole.bodySm, context),
                  ),
                ],
                if (action != null) ...[
                  SizedBox(height: space.of(FwSpace.s2, context)),
                  action!,
                ],
              ],
            ),
          ),
          if (onDismiss != null) ...[
            SizedBox(width: space.of(FwSpace.s2, context)),
            IconButton(
              tooltip: 'Dismiss',
              iconSize: theme.iconSizes.of(FwIconSize.sm),
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ],
      ),
    );

    if (!announce) return banner;
    return Semantics(liveRegion: true, child: banner);
  }
}
