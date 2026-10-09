import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';

/// Visual treatment of an icon button, independent of intent.
enum FwIconButtonVariant { filled, tonal, outline, ghost }

/// Icon-only action with a guaranteed minimum touch target.
///
/// [tooltip] is required: it is the accessible name (used by screen
/// readers) and the visible tooltip. The hit area is always at least
/// [FwTheme.minTapTarget] even when the glyph is small.
class FwIconButton extends StatelessWidget {
  const FwIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.variant = FwIconButtonVariant.ghost,
    this.intent = FwIntent.primary,
    this.iconSize = 24,
    this.selected = false,
    this.loading = false,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;

  /// Accessible name and tooltip. Required by the component contract.
  final String tooltip;
  final FwIconButtonVariant variant;
  final FwIntent intent;

  /// Glyph size in logical pixels. The touch target is independent of this.
  final double iconSize;

  /// Toggle state for `selected` icon buttons. Controlled by the caller.
  final bool selected;
  final bool loading;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final action = loading ? null : onPressed;
    final (intentBg, intentFg) = intentRoles(intent);

    final style =
        IconButton.styleFrom(
          minimumSize: Size(theme.minTapTarget, theme.minTapTarget),
          iconSize: iconSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radii.md),
          ),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(
                color: colors.of(FwColorRole.focusRing),
                width: theme.focusWidth,
              );
            }
            if (variant == FwIconButtonVariant.outline) {
              return BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? colors.of(FwColorRole.disabled)
                    : colors.of(intentBg),
              );
            }
            return BorderSide.none;
          }),
        );

    IconButton button({Color? background, Color? foreground}) => IconButton(
      onPressed: action,
      tooltip: tooltip,
      focusNode: focusNode,
      autofocus: autofocus,
      isSelected: selected ? true : null,
      style: style.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return background == null
                ? Colors.transparent
                : colors.of(FwColorRole.disabled);
          }
          // Selected toggle fills with the intent pair.
          if (states.contains(WidgetState.selected)) {
            return colors.of(intentBg);
          }
          return background;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.of(FwColorRole.onDisabled);
          }
          if (states.contains(WidgetState.selected)) {
            return colors.of(intentFg);
          }
          return foreground;
        }),
      ),
      icon: loading
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : icon,
    );

    final Widget built = switch (variant) {
      FwIconButtonVariant.filled => button(
        background: colors.of(intentBg),
        foreground: colors.of(intentFg),
      ),
      FwIconButtonVariant.tonal => button(
        background: colors.of(FwColorRole.secondaryContainer),
        foreground: colors.of(FwColorRole.onSecondaryContainer),
      ),
      FwIconButtonVariant.outline => button(foreground: colors.of(intentBg)),
      FwIconButtonVariant.ghost => button(foreground: colors.of(intentBg)),
    };
    return loading
        ? Semantics(
            liveRegion: true,
            label: '$tooltip, loading',
            button: true,
            enabled: false,
            child: ExcludeSemantics(child: built),
          )
        : built;
  }
}

/// Standard close/dismiss action.
///
/// A thin [FwIconButton] specialization: the parent owns dismissal, this
/// only provides the consistent glyph, target, and accessible name.
/// Set [destructive] for destructive contexts (danger intent).
class FwCloseButton extends StatelessWidget {
  const FwCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Close',
    this.destructive = false,
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final bool destructive;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => FwIconButton(
    icon: const Icon(Icons.close),
    onPressed: onPressed,
    tooltip: tooltip,
    intent: destructive ? FwIntent.danger : FwIntent.neutral,
    focusNode: focusNode,
    autofocus: autofocus,
  );
}
