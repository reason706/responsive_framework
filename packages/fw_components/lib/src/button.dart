import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Visual treatment of a button, independent of its semantic intent.
enum FwButtonVariant { solid, tonal, outline, ghost, link }

/// Button with native keyboard/focus behavior and explicit loading semantics.
///
/// Visual [variant] is separate from semantic [intent]: a destructive
/// action is `variant: FwButtonVariant.solid, intent: FwIntent.danger`,
/// not a red-styled primary. [size], [shape], and [variant] are orthogonal:
/// every combination is expressible.
///
/// Icons use [icon] + [iconPosition] with logical (not physical)
/// directions: [FwIconPosition.start]/[end] flip automatically in RTL
/// locales; [top]/[bottom] stack the icon above/below the label.
/// [FwIconPosition.only] adopts square icon metrics and requires
/// [semanticLabel]. The icon–label gap defaults to the 8px consensus token
/// ([FwSpace.s2]); override with [iconGap]. The legacy [leading]/[trailing]
/// widget slots remain for non-icon content and are mutually exclusive
/// with [icon].
///
/// The caller owns busy state via [loading]; busy and disabled buttons
/// never invoke [onPressed]. While loading, the indicator replaces the
/// icon at [loadingPosition] (default: in place at the start); with
/// [keepWidthWhileLoading] the button holds its idle width so layout does
/// not jump.
class FwButton extends StatelessWidget {
  const FwButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FwButtonVariant.solid,
    this.intent = FwIntent.primary,
    this.size = FwSize.md,
    this.shape = FwShape.rounded,
    this.icon,
    this.iconPosition = FwIconPosition.start,
    this.iconGap,
    this.semanticLabel,
    this.leading,
    this.trailing,
    this.loading = false,
    this.loadingLabel,
    this.loadingPosition = FwLoadingPosition.start,
    this.keepWidthWhileLoading = true,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         icon == null || (leading == null && trailing == null),
         'icon and leading/trailing are mutually exclusive: use icon + '
         'iconPosition for icons, leading/trailing for other content.',
       ),
       assert(
         iconPosition != FwIconPosition.only || semanticLabel != null,
         'icon-only buttons require a semanticLabel for screen readers.',
       ),
       assert(
         !(fullWidth && iconPosition == FwIconPosition.only),
         'icon-only buttons cannot be fullWidth.',
       );

  /// Icon-only button: square metrics, guaranteed touch target, and a
  /// required [semanticLabel]. Shares the [FwButton] variant/intent/size
  /// model with [FwIconButton] (A02); prefer [FwIconButton] when only the
  /// ghost/filled/tonal/outline treatments are needed.
  const FwButton.icon({
    super.key,
    required Widget icon,
    required String semanticLabel,
    required this.onPressed,
    this.variant = FwButtonVariant.ghost,
    this.intent = FwIntent.primary,
    this.size = FwSize.md,
    this.shape = FwShape.rounded,
    this.loading = false,
    this.loadingPosition = FwLoadingPosition.center,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
  }) : label = '',
       icon = icon,
       iconPosition = FwIconPosition.only,
       iconGap = null,
       semanticLabel = semanticLabel,
       leading = null,
       trailing = null,
       loadingLabel = null,
       keepWidthWhileLoading = true;

  final String label;
  final VoidCallback? onPressed;
  final FwButtonVariant variant;
  final FwIntent intent;
  final FwSize size;
  final FwShape shape;

  /// Icon widget and its placement. Mutually exclusive with [leading]/
  /// [trailing].
  final Widget? icon;
  final FwIconPosition iconPosition;

  /// Icon–label gap in logical pixels. Null resolves to the [FwSpace.s2]
  /// token (8px at root 16).
  final double? iconGap;

  /// Accessible name. Required when [iconPosition] is [FwIconPosition.only].
  final String? semanticLabel;

  /// Generic leading/trailing content slots (non-icon). Mutually exclusive
  /// with [icon].
  final Widget? leading;
  final Widget? trailing;

  final bool loading;

  /// Localized replacement for "label, loading" while busy.
  final String? loadingLabel;

  /// Where the loading indicator appears. Defaults to replacing the
  /// leading icon in place at a stable width.
  final FwLoadingPosition loadingPosition;
  final bool keepWidthWhileLoading;

  /// Stretch to the available width.
  final bool fullWidth;

  /// Fire a haptic tap signal on press (skipped under accessible
  /// navigation or when the theme disables haptics).
  final bool enableFeedback;

  final FocusNode? focusNode;
  final bool autofocus;

  FwRadius get _radius => switch (shape) {
    FwShape.stadium => FwRadius.pill,
    FwShape.rounded => FwRadius.md,
    FwShape.sharp => FwRadius.none,
  };

  /// Icon glyph size for [size], from the type scale's label metrics.
  double _iconSize(BuildContext context) {
    final theme = context.fwTheme;
    // Label text size scaled: icon tracks the label, never the hit area.
    final labelSize =
        theme.typeScale.resolve(FwTextRole.label, context).fontSize ?? 14;
    return (labelSize * 1.25).clamp(16.0, 28.0);
  }

  Widget _spinner(BuildContext context, Color? color) {
    final size = _iconSize(context);
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  /// The icon at the configured position (idle content only; loading is
  /// handled by [_loadingOverlay] in [build]).
  Widget _iconSlot(BuildContext context) {
    final theme = context.fwTheme;
    final gap = iconGap ?? theme.spaceScale.of(FwSpace.s2, context);
    final iconSize = _iconSize(context);
    final glyph = SizedBox(width: iconSize, height: iconSize, child: icon);
    final label = Flexible(child: Text(this.label));

    switch (iconPosition) {
      case FwIconPosition.only:
        return glyph;
      case FwIconPosition.start:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            glyph,
            SizedBox(width: gap),
            label,
          ],
        );
      case FwIconPosition.end:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            label,
            SizedBox(width: gap),
            glyph,
          ],
        );
      case FwIconPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            glyph,
            SizedBox(height: gap),
            label,
          ],
        );
      case FwIconPosition.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            label,
            SizedBox(height: gap),
            glyph,
          ],
        );
    }
  }

  /// Legacy slot content (leading/trailing arbitrary widgets).
  Widget _slotContent(BuildContext context) {
    final theme = context.fwTheme;
    final gap = iconGap ?? theme.spaceScale.of(FwSpace.s2, context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, SizedBox(width: gap)],
        Flexible(child: Text(loading ? (loadingLabel ?? label) : label)),
        if (trailing != null) ...[SizedBox(width: gap), trailing!],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    void handlePress() {
      if (enableFeedback) theme.haptics.tap(context);
      onPressed?.call();
    }

    final action = loading
        ? null
        : onPressed == null
        ? null
        : handlePress;
    // Layer-3 component tokens, with a semantic-role fallback so the button
    // renders identically with or without an explicit registration.
    final buttonColors =
        Theme.of(context).extension<FwButtonColors>() ??
        FwButtonColors.fromColors(colors);
    final colorSet = switch (variant) {
      FwButtonVariant.solid => buttonColors.setFor(
        filled: true,
        intent: intent,
      ),
      FwButtonVariant.tonal => buttonColors.tonalFor(intent),
      FwButtonVariant.outline ||
      FwButtonVariant.ghost ||
      FwButtonVariant.link => buttonColors.setFor(
        filled: false,
        intent: intent,
      ),
    };

    final labelStyle = theme.typeScale.resolve(FwTextRole.label, context);
    Widget content = icon != null ? _iconSlot(context) : _slotContent(context);

    // Loading visuals: the spinner replaces the icon position (default:
    // in place at the start). With [keepWidthWhileLoading] the idle
    // content is maintained invisibly underneath so the button never
    // changes size when busy toggles.
    if (loading) {
      if (iconPosition == FwIconPosition.only) {
        content = _spinner(context, colorSet.foreground);
      } else if (keepWidthWhileLoading) {
        content = Stack(
          alignment: Alignment.center,
          children: [
            Visibility.maintain(child: content),
            _loadingOverlay(context, colorSet.foreground),
          ],
        );
      } else {
        content = _loadingOverlay(context, colorSet.foreground);
      }
    }

    final factor = size.scaleFactor;
    final padding = iconPosition == FwIconPosition.only
        ? EdgeInsets.zero
        : EdgeInsetsDirectional.symmetric(
            horizontal:
                theme.spaceScale.resolveAlias(
                  FwSpaceAlias.controlInline,
                  context,
                ) *
                factor,
            vertical:
                theme.spaceScale.resolveAlias(
                  FwSpaceAlias.controlBlock,
                  context,
                ) *
                factor,
          );

    ButtonStyle styleFrom({
      Color? background,
      Color? foreground,
      BorderSide? Function(Set<WidgetState> states)? side,
      TextStyle? textStyle,
    }) {
      // State-layer overlays preserve the intent hue while giving
      // hover/pressed/focus feedback, mirroring Material behavior.
      Color mixOver(Color base, Color over, double alpha) =>
          Color.lerp(base, over, alpha)!;
      final bg = background == null
          ? null
          : WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                // Filled treatments fall back to the disabled pair; text
                // treatments keep no background in any state.
                return variant == FwButtonVariant.solid ||
                        variant == FwButtonVariant.tonal
                    ? colors.of(FwColorRole.disabled)
                    : Colors.transparent;
              }
              final base = background;
              final over = foreground ?? colors.of(FwColorRole.onSurface);
              if (states.contains(WidgetState.pressed)) {
                return mixOver(base, over, 0.12);
              }
              if (states.contains(WidgetState.hovered)) {
                return mixOver(base, over, 0.08);
              }
              if (states.contains(WidgetState.focused)) {
                return mixOver(base, over, 0.10);
              }
              return base;
            });
      final fg = foreground == null
          ? null
          : WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colors.of(FwColorRole.onDisabled);
              }
              return foreground;
            });
      return ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(theme.minTapTarget, theme.minTapTarget),
        ),
        padding: WidgetStatePropertyAll(padding),
        textStyle: WidgetStatePropertyAll(textStyle ?? labelStyle),
        backgroundColor: bg,
        foregroundColor: fg,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radii.of(_radius)),
          ),
        ),
        side: side == null ? null : WidgetStateProperty.resolveWith(side),
      );
    }

    BorderSide? outlineSide(Set<WidgetState> states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(
          color: colors.of(FwColorRole.focusRing),
          width: theme.focusRing.width,
        );
      }
      if (variant == FwButtonVariant.outline) {
        return BorderSide(
          color: states.contains(WidgetState.disabled)
              ? colors.of(FwColorRole.disabled)
              : colorSet.foreground,
        );
      }
      return BorderSide.none;
    }

    final Widget button = switch (variant) {
      FwButtonVariant.solid => FilledButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(
          background: colorSet.background,
          foreground: colorSet.foreground,
          side: outlineSide,
        ),
        child: content,
      ),
      FwButtonVariant.tonal => FilledButton.tonal(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(
          background: colorSet.background,
          foreground: colorSet.foreground,
          side: outlineSide,
        ),
        child: content,
      ),
      FwButtonVariant.outline => OutlinedButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(foreground: colorSet.foreground, side: outlineSide),
        child: content,
      ),
      FwButtonVariant.ghost => TextButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(foreground: colorSet.foreground, side: outlineSide),
        child: content,
      ),
      // Link: inline text action with a non-color cue (underline).
      FwButtonVariant.link => TextButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(
          foreground: colorSet.foreground,
          side: outlineSide,
          textStyle: labelStyle.copyWith(decoration: TextDecoration.underline),
        ),
        child: content,
      ),
    };

    final Widget sized = fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;

    // Icon-only buttons expose the semantic label; labeled buttons keep
    // the default text semantics.
    final Widget labeled = iconPosition == FwIconPosition.only
        ? Semantics(
            label: semanticLabel,
            button: true,
            excludeSemantics: true,
            child: sized,
          )
        : sized;

    return loading
        ? Semantics(
            liveRegion: true,
            label: loadingLabel ?? (label.isEmpty ? semanticLabel : label),
            button: true,
            enabled: false,
            child: ExcludeSemantics(child: labeled),
          )
        : labeled;
  }

  /// Loading overlay for the width-stable path: spinner with the loading
  /// label, drawn over the invisibly-maintained idle content.
  Widget _loadingOverlay(BuildContext context, Color? foreground) {
    final theme = context.fwTheme;
    final gap = iconGap ?? theme.spaceScale.of(FwSpace.s2, context);
    final spinner = _spinner(context, foreground);
    final text = Text(loadingLabel ?? label);
    switch (loadingPosition) {
      case FwLoadingPosition.start:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            spinner,
            SizedBox(width: gap),
            Flexible(child: text),
          ],
        );
      case FwLoadingPosition.end:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: text),
            SizedBox(width: gap),
            spinner,
          ],
        );
      case FwLoadingPosition.center:
        return spinner;
    }
  }
}
