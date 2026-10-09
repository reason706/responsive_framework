import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

// ---------------------------------------------------------------------------
// Alert / banner (B01).
// ---------------------------------------------------------------------------

/// Alert intent: success, informational, warning, or danger.
enum FwAlertIntent { success, info, warning, danger }

/// Alert/banner (B01): status message with icon, title, optional body and
/// action, and an optional dismiss button.
///
/// Announcements are opt-in via [announce]: set it when the alert is added
/// dynamically (e.g. a form error summary). Do not announce on every
/// rebuild — the widget takes no responsibility for when you insert it.
class FwAlert extends StatelessWidget {
  const FwAlert({
    super.key,
    required this.intent,
    required this.title,
    this.body,
    this.action,
    this.onDismiss,
    this.announce = false,
  });

  final FwAlertIntent intent;
  final String title;
  final String? body;
  final Widget? action;

  /// If non-null, a close button with a "Dismiss" tooltip is shown.
  final VoidCallback? onDismiss;

  /// When true, the alert is a live region for screen readers.
  final bool announce;

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
    final (intentColor, icon) = _style(colors);

    final alert = Container(
      padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s3, context)),
      decoration: BoxDecoration(
        color: colors.of(FwColorRole.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
        border: Border(left: BorderSide(color: intentColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: intentColor, size: 20),
          SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
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
                  const SizedBox(height: 4),
                  Text(
                    body!,
                    style: theme.typeScale.resolve(FwTextRole.bodySm, context),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              iconSize: 18,
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );

    if (!announce) return alert;
    return Semantics(liveRegion: true, child: alert);
  }
}

// ---------------------------------------------------------------------------
// Progress (B03/B04/B05).
// ---------------------------------------------------------------------------

/// Linear progress (B03): determinate or indeterminate.
///
/// The percentage label renders outside the track by default
/// ([showValueLabel]); the track itself carries the semantics value so
/// screen readers announce progress without duplication.
class FwLinearProgress extends StatelessWidget {
  const FwLinearProgress({
    super.key,
    this.value,
    this.intent = FwAlertIntent.info,
    this.thickness = 4,
    this.showValueLabel = true,
    this.label,
    this.semanticLabel,
  }) : assert(
         value == null || (value >= 0.0 && value <= 1.0),
         'value must be null or within 0..1',
       );

  /// 0..1, or null for indeterminate.
  final double? value;
  final FwAlertIntent intent;
  final double thickness;

  /// Show "42%" (or [label]) beside the track.
  final bool showValueLabel;

  /// Custom label text; defaults to the percentage when determinate.
  final String? label;
  final String? semanticLabel;

  Color _color(FwColors colors) => switch (intent) {
    FwAlertIntent.success => colors.of(FwColorRole.success),
    FwAlertIntent.info => colors.of(FwColorRole.primary),
    FwAlertIntent.warning => colors.of(FwColorRole.warning),
    FwAlertIntent.danger => colors.of(FwColorRole.error),
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final percent = value == null ? null : '${(value! * 100).round()}%';

    final bar = Semantics(
      label: semanticLabel ?? 'Progress',
      value: percent,
      child: LinearProgressIndicator(
        value: value,
        minHeight: thickness,
        color: _color(colors),
        backgroundColor: colors.of(FwColorRole.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(thickness / 2),
      ),
    );

    if (!showValueLabel) return bar;
    final text = label ?? percent ?? 'Loading…';
    return Row(
      children: [
        Expanded(child: bar),
        SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
        // Visual only; the bar announces the value.
        ExcludeSemantics(
          child: Text(
            text,
            style: theme.typeScale.resolve(FwTextRole.label, context),
          ),
        ),
      ],
    );
  }
}

/// Circular progress (B04): determinate or indeterminate.
///
/// Shares its indeterminate behavior with [FwBusyIndicator]; there is one
/// progress model, not two.
class FwCircularProgress extends StatelessWidget {
  const FwCircularProgress({
    super.key,
    this.value,
    this.size = 36,
    this.strokeWidth = 4,
    this.semanticLabel,
  }) : assert(
         value == null || (value >= 0.0 && value <= 1.0),
         'value must be null or within 0..1',
       );

  /// 0..1, or null for indeterminate.
  final double? value;
  final double size;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.fwTheme.colors;
    final percent = value == null ? null : '${(value! * 100).round()}%';
    return Semantics(
      label: semanticLabel ?? 'Progress',
      value: percent,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: strokeWidth,
          color: colors.of(FwColorRole.primary),
          backgroundColor: colors.of(FwColorRole.surfaceContainerHighest),
        ),
      ),
    );
  }
}

/// Busy indicator (B05): indeterminate progress with an accessible label.
///
/// When reduced motion is requested ([MediaQuery.disableAnimations]), the
/// spinner is replaced by static text — no animation, but the busy state
/// is still communicated. The [label] is always exposed to screen readers.
class FwBusyIndicator extends StatelessWidget {
  const FwBusyIndicator({super.key, this.label = 'Loading…', this.size = 24});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final indicator = reduceMotion
        ? Icon(
            Icons.hourglass_top,
            size: size,
            color: theme.colors.of(FwColorRole.textMuted),
          )
        : FwCircularProgress(size: size, strokeWidth: size / 8);

    return Semantics(
      label: label,
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: indicator),
          SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
          Text(label, style: theme.typeScale.resolve(FwTextRole.body, context)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton (B06).
// ---------------------------------------------------------------------------

/// Skeleton placeholder (B06): a reserved-geometry block for loading content.
///
/// Decorative — excluded from semantics. Static by default; set [shimmer]
/// to opt into the shimmer animation, which is automatically disabled when
/// reduced motion is requested.
class FwSkeleton extends StatefulWidget {
  const FwSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
    this.shimmer = false,
  });

  final double? width;
  final double height;
  final double borderRadius;

  /// Opt-in shimmer animation. Ignored under reduced motion.
  final bool shimmer;

  /// Circular avatar placeholder.
  const FwSkeleton.avatar({super.key, this.width = 40, this.shimmer = false})
    : height = 40,
      borderRadius = 20;

  @override
  State<FwSkeleton> createState() => _FwSkeletonState();
}

class _FwSkeletonState extends State<FwSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.shimmer) _controller.repeat();
  }

  @override
  void didUpdateWidget(FwSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmer != oldWidget.shimmer) {
      if (widget.shimmer) {
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
    final base = colors.of(FwColorRole.surfaceContainerHighest);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animate = widget.shimmer && !reduceMotion;

    Widget block = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );

    if (animate) {
      block = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, colors.of(FwColorRole.surface), base],
            stops: [
              _controller.value - 0.3,
              _controller.value,
              _controller.value + 0.3,
            ].map((s) => s.clamp(0.0, 1.0)).toList(),
          ).createShader(bounds),
          child: child,
        ),
        child: block,
      );
    }

    return ExcludeSemantics(child: block);
  }
}

// ---------------------------------------------------------------------------
// Empty / error / offline state panel (B07).
// ---------------------------------------------------------------------------

/// State panel (B07): illustration/icon, heading, description, and actions.
///
/// One composable panel for empty, error, and offline states. The [onRetry]
/// callback and the offline condition belong to the app — this widget never
/// guesses connectivity from a single failed request. Wire an illustration
/// into [illustration] when the illustration system lands.
class FwStatePanel extends StatelessWidget {
  const FwStatePanel({
    super.key,
    this.illustration,
    this.icon,
    required this.heading,
    this.description,
    this.actions = const [],
  }) : assert(
         illustration != null || icon != null,
         'Provide an illustration or an icon',
       );

  final Widget? illustration;
  final IconData? icon;
  final String heading;
  final String? description;
  final List<Widget> actions;

  /// Empty state: nothing here yet.
  const FwStatePanel.empty({
    super.key,
    required this.heading,
    this.description,
    this.actions = const [],
    this.illustration,
  }) : icon = Icons.inbox_outlined;

  /// Error state with a retry action.
  FwStatePanel.error({
    super.key,
    required this.heading,
    this.description,
    required VoidCallback onRetry,
    String retryLabel = 'Retry',
    this.illustration,
  }) : icon = Icons.error_outline,
       actions = [
         // Built with material directly to avoid a fw_components cycle;
         // apps should pass their own FwButton.
         _RetryButton(label: retryLabel, onPressed: onRetry),
       ];

  /// Offline state: the app supplies [isOffline]; this is presentation only.
  const FwStatePanel.offline({
    super.key,
    this.description = 'Check your connection and try again.',
    this.actions = const [],
    this.illustration,
  }) : icon = Icons.wifi_off_outlined,
       heading = 'You are offline';

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    return Padding(
      padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s6, context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null)
            illustration!
          else
            Icon(icon, size: 48, color: colors.of(FwColorRole.textMuted)),
          SizedBox(height: theme.spaceScale.of(FwSpace.s3, context)),
          Text(
            heading,
            style: theme.typeScale.resolve(FwTextRole.h4, context),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
            Text(
              description!,
              style: theme.typeScale
                  .resolve(FwTextRole.body, context)
                  .copyWith(color: colors.of(FwColorRole.textMuted)),
              textAlign: TextAlign.center,
            ),
          ],
          if (actions.isNotEmpty) ...[
            SizedBox(height: theme.spaceScale.of(FwSpace.s4, context)),
            Wrap(
              spacing: theme.spaceScale.of(FwSpace.s2, context),
              alignment: WrapAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// Minimal retry button for [FwStatePanel.error]; apps should pass their own
/// button via [FwStatePanel.actions] instead.
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}
