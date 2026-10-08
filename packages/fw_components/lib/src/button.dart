import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

enum FwButtonVariant { primary, outline, ghost }

/// Button with native keyboard/focus behavior and explicit loading semantics.
class FwButton extends StatelessWidget {
  const FwButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FwButtonVariant.primary,
    this.loading = false,
    this.loadingLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FwButtonVariant variant;
  final bool loading;

  /// Localized replacement for "label, loading" while busy.
  final String? loadingLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final scheme = theme.colors.scheme;
    final action = loading ? null : onPressed;
    final content = Text(loading ? (loadingLabel ?? label) : label);
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(theme.minTapTarget, theme.minTapTarget),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(
          horizontal: theme.spacing.of(FwSpace.s4),
          vertical: theme.spacing.of(FwSpace.s2),
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.md),
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: scheme.onSurface, width: theme.focusWidth);
        }
        if (variant == FwButtonVariant.outline) {
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.12)
                : scheme.outline,
          );
        }
        return BorderSide.none;
      }),
    );
    final Widget button = switch (variant) {
      FwButtonVariant.primary => FilledButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: style,
        child: content,
      ),
      FwButtonVariant.outline => OutlinedButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: style,
        child: content,
      ),
      FwButtonVariant.ghost => TextButton(
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        style: style,
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
