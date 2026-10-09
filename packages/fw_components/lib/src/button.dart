import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Visual treatment of a button, independent of its semantic intent.
enum FwButtonVariant { solid, outline, ghost, link }

/// Semantic intent of an action. Never conveyed by color alone: intents
/// also differ in label, icon, or placement in the UI.
enum FwIntent { primary, neutral, success, warning, danger, info }

/// Button size. All sizes keep the theme's minimum touch target; size
/// changes control padding, not the hit area.
enum FwButtonSize { sm, md, lg }

/// Intent color roles for the solid treatment: (background, foreground).
///
/// Shared by action widgets so intent means the same colors everywhere.
(FwColorRole, FwColorRole) intentRoles(FwIntent intent) => switch (intent) {
  FwIntent.primary => (FwColorRole.primary, FwColorRole.onPrimary),
  FwIntent.neutral => (
    FwColorRole.secondaryContainer,
    FwColorRole.onSecondaryContainer,
  ),
  FwIntent.success => (FwColorRole.success, FwColorRole.onSuccess),
  FwIntent.warning => (FwColorRole.warning, FwColorRole.onWarning),
  FwIntent.danger => (FwColorRole.error, FwColorRole.onError),
  FwIntent.info => (FwColorRole.info, FwColorRole.onInfo),
};

/// Button with native keyboard/focus behavior and explicit loading semantics.
///
/// Visual [variant] is separate from semantic [intent]: a destructive
/// action is `variant: FwButtonVariant.solid, intent: FwIntent.danger`,
/// not a red-styled primary. The caller owns busy state via [loading];
/// busy and disabled buttons never invoke [onPressed].
class FwButton extends StatelessWidget {
  const FwButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FwButtonVariant.solid,
    this.intent = FwIntent.primary,
    this.size = FwButtonSize.md,
    this.leading,
    this.trailing,
    this.loading = false,
    this.loadingLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FwButtonVariant variant;
  final FwIntent intent;
  final FwButtonSize size;

  /// Optional leading/trailing icon widgets, spaced with a token gap.
  final Widget? leading;
  final Widget? trailing;

  final bool loading;

  /// Localized replacement for "label, loading" while busy.
  final String? loadingLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  double get _sizeFactor => switch (size) {
    FwButtonSize.sm => 0.75,
    FwButtonSize.md => 1,
    FwButtonSize.lg => 1.5,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final action = loading ? null : onPressed;
    final (intentBg, intentFg) = intentRoles(intent);

    final labelStyle = theme.typeScale.resolve(FwTextRole.label, context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
        ],
        Flexible(
          // Long labels grow and wrap instead of truncating.
          child: Text(loading ? (loadingLabel ?? label) : label),
        ),
        if (trailing != null) ...[
          SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
          trailing!,
        ],
      ],
    );

    final padding = EdgeInsetsDirectional.symmetric(
      horizontal:
          theme.spaceScale.resolveAlias(FwSpaceAlias.controlInline, context) *
          _sizeFactor,
      vertical:
          theme.spaceScale.resolveAlias(FwSpaceAlias.controlBlock, context) *
          _sizeFactor,
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
                // Solid treatments fall back to the disabled pair; text
                // treatments keep no background in any state.
                return variant == FwButtonVariant.solid
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
            borderRadius: BorderRadius.circular(theme.radii.md),
          ),
        ),
        side: side == null ? null : WidgetStateProperty.resolveWith(side),
      );
    }

    BorderSide? outlineSide(Set<WidgetState> states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(
          color: colors.of(FwColorRole.focusRing),
          width: theme.focusWidth,
        );
      }
      if (variant == FwButtonVariant.outline) {
        return BorderSide(
          color: states.contains(WidgetState.disabled)
              ? colors.of(FwColorRole.disabled)
              : colors.of(intentBg),
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
          background: colors.of(intentBg),
          foreground: colors.of(intentFg),
          side: outlineSide,
        ),
        child: content,
      ),
      FwButtonVariant.outline => OutlinedButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(foreground: colors.of(intentBg), side: outlineSide),
        child: content,
      ),
      FwButtonVariant.ghost => TextButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(foreground: colors.of(intentBg), side: outlineSide),
        child: content,
      ),
      // Link: inline text action with a non-color cue (underline).
      FwButtonVariant.link => TextButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: styleFrom(
          foreground: colors.of(intentBg),
          side: outlineSide,
          textStyle: labelStyle.copyWith(decoration: TextDecoration.underline),
        ),
        child: content,
      ),
    };
    return loading
        ? Semantics(
            liveRegion: true,
            label: loadingLabel ?? label,
            button: true,
            enabled: false,
            child: ExcludeSemantics(child: button),
          )
        : button;
  }
}
