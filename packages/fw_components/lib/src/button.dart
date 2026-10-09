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
    final colors = theme.colors;
    final action = loading ? null : onPressed;
    final content = Text(loading ? (loadingLabel ?? label) : label);
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(theme.minTapTarget, theme.minTapTarget),
      ),
      // Root-relative control padding; density-aware via the space scale.
      padding: WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(
          horizontal: theme.spaceScale.resolveAlias(
            FwSpaceAlias.controlInline,
            context,
          ),
          vertical: theme.spaceScale.resolveAlias(
            FwSpaceAlias.controlBlock,
            context,
          ),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        theme.typeScale.resolve(FwTextRole.label, context),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.md),
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          // Focus ring role stays visible against the control and its
          // surroundings; drawn separately from state colors.
          return BorderSide(
            color: colors.of(FwColorRole.focusRing),
            width: theme.focusWidth,
          );
        }
        if (variant == FwButtonVariant.outline) {
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? colors.of(FwColorRole.disabled)
                : colors.of(FwColorRole.borderStrong),
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
