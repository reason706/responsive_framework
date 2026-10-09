import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Container color roles per intent for subtle treatments.
(FwColorRole, FwColorRole) _intentContainerRoles(FwIntent intent) =>
    switch (intent) {
      FwIntent.primary => (
        FwColorRole.primaryContainer,
        FwColorRole.onPrimaryContainer,
      ),
      FwIntent.neutral => (
        FwColorRole.secondaryContainer,
        FwColorRole.onSecondaryContainer,
      ),
      FwIntent.success => (
        FwColorRole.successContainer,
        FwColorRole.onSuccessContainer,
      ),
      FwIntent.warning => (
        FwColorRole.warningContainer,
        FwColorRole.onWarningContainer,
      ),
      FwIntent.danger => (
        FwColorRole.errorContainer,
        FwColorRole.onErrorContainer,
      ),
      FwIntent.info => (FwColorRole.infoContainer, FwColorRole.onInfoContainer),
    };

/// T01 — Text resolving a typography role.
///
/// [heading] sets heading semantics independently of the visual [role]:
/// a visually small heading can still announce as a heading, and decorative
/// large text need not claim heading semantics. Truncation is explicit —
/// pass [maxLines]/[overflow] deliberately; essential text wraps by default.
class FwText extends StatelessWidget {
  const FwText(
    this.data, {
    super.key,
    this.role = FwTextRole.body,
    this.heading = false,
    this.selectable = false,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.color,
    this.semanticsLabel,
  });

  final String data;
  final FwTextRole role;

  /// Announces as a heading regardless of visual size.
  final bool heading;
  final bool selectable;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Semantic text color. Defaults to the role's own color.
  final FwColorRole? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    var style = theme.typeScale.resolve(role, context);
    if (color != null) {
      style = style.copyWith(color: theme.colors.of(color!));
    }
    Widget text = selectable
        ? SelectableText(
            data,
            style: style,
            maxLines: maxLines,
            textAlign: textAlign,
          )
        : Text(
            data,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign,
          );
    if (semanticsLabel != null) {
      text = Semantics(
        label: semanticsLabel,
        excludeSemantics: true,
        child: text,
      );
    }
    if (heading) {
      text = Semantics(header: true, child: text);
    }
    return text;
  }
}

/// A03/T03 — Text link sharing the button link behavior.
///
/// One link implementation: [FwLink] is the inline/standalone text link;
/// `FwButton(variant: FwButtonVariant.link)` is the same styling with a
/// 48px target for touch. Navigation and submit callbacks stay separate —
/// pass navigation through [onTap]; [uri] is metadata for semantics and
/// the app's own handling (URI opening is delegated to the application).
/// Disabled links keep explicit semantics instead of silent greying.
class FwLink extends StatelessWidget {
  const FwLink({
    super.key,
    required this.label,
    this.onTap,
    this.uri,
    this.external = false,
    this.intent = FwIntent.primary,
    this.enabled = true,
    this.semanticLabel,
    this.leading,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// Destination metadata, exposed to semantics. Opening it is the app's job.
  final Uri? uri;

  /// Shows the external-destination cue.
  final bool external;
  final FwIntent intent;
  final bool enabled;
  final String? semanticLabel;
  final Widget? leading;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final effectiveOnTap = enabled ? onTap : null;
    final (intentBg, _) = intentRoles(intent);
    final style = theme.typeScale
        .resolve(FwTextRole.body, context)
        .copyWith(
          // Underline is the non-color cue; never rely on color alone.
          decoration: TextDecoration.underline,
          color: effectiveOnTap == null
              ? colors.of(FwColorRole.onDisabled)
              : colors.of(intentBg),
        );
    final gap = theme.spaceScale.of(FwSpace.s1, context);
    return Semantics(
      link: true,
      enabled: effectiveOnTap != null,
      label: semanticLabel,
      value: uri?.toString(),
      excludeSemantics: true,
      child: InkWell(
        onTap: effectiveOnTap,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor: effectiveOnTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        focusColor: colors.of(FwColorRole.focusRing).withValues(alpha: 0.12),
        hoverColor: colors.of(intentBg).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: gap / 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, SizedBox(width: gap)],
              Flexible(child: Text(label, style: style)),
              if (external) ...[
                SizedBox(width: gap),
                Icon(
                  Icons.open_in_new,
                  size: style.fontSize! * 0.9,
                  color: style.color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// T04 — Noninteractive badge: count, dot, or label.
///
/// Provide the accessible full count when the visual text is abbreviated
/// (`99+`): screen readers announce [semanticLabel] or the raw count, never
/// the truncated text. Badges are not interactive; use [FwChip] for that.
class FwBadge extends StatelessWidget {
  const FwBadge({
    super.key,
    this.count,
    this.maxCount = 99,
    this.label,
    this.dot = false,
    this.variant = FwBadgeVariant.solid,
    this.intent = FwIntent.primary,
    this.semanticLabel,
  }) : assert(
         count != null || label != null || dot,
         'Provide count, label, or dot.',
       );

  final int? count;
  final int maxCount;
  final String? label;
  final bool dot;
  final FwBadgeVariant variant;
  final FwIntent intent;

  /// Announced instead of the visual text. Defaults to the full count.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final (bg, fg) = intentRoles(intent);
    final (containerBg, containerFg) = _intentContainerRoles(intent);
    final (Color bgColor, Color fgColor, BorderSide? side) = switch (variant) {
      FwBadgeVariant.solid => (colors.of(bg), colors.of(fg), null),
      FwBadgeVariant.subtle => (
        colors.of(containerBg),
        colors.of(containerFg),
        null,
      ),
      FwBadgeVariant.outline => (
        Colors.transparent,
        colors.of(bg),
        BorderSide(color: colors.of(bg)),
      ),
    };

    final String visual = dot
        ? ''
        : label ?? (count! > maxCount ? '$maxCount+' : '$count');
    final String announced =
        semanticLabel ?? (count != null ? '$count' : (label ?? ''));
    final textStyle = theme.typeScale
        .resolve(FwTextRole.label, context)
        .copyWith(color: fgColor);

    return Semantics(
      label: announced,
      excludeSemantics: true,
      child: Container(
        padding: dot
            ? EdgeInsets.all(theme.spaceScale.of(FwSpace.s1, context))
            : EdgeInsets.symmetric(
                horizontal: theme.spaceScale.of(FwSpace.s2, context),
                vertical: theme.spaceScale.of(FwSpace.s1, context),
              ),
        decoration: BoxDecoration(
          color: bgColor,
          border: side == null ? null : Border.fromBorderSide(side),
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.pill)),
        ),
        child: dot
            ? SizedBox(
                width: textStyle.fontSize! * 0.6,
                height: textStyle.fontSize! * 0.6,
              )
            : Text(visual, style: textStyle),
      ),
    );
  }
}

enum FwBadgeVariant { solid, subtle, outline }

/// T05 — Chip/tag built on Flutter's chip primitives.
///
/// [FwChipKind.assist] triggers [onPressed]; [filter] toggles [selected]
/// via [onSelected]; [input] is removable via [onDeleted]. Selection and
/// removal are separate callbacks and separate semantic actions.
enum FwChipKind { assist, filter, input }

class FwChip extends StatelessWidget {
  const FwChip({
    super.key,
    required this.label,
    this.kind = FwChipKind.assist,
    this.selected = false,
    this.onPressed,
    this.onSelected,
    this.onDeleted,
    this.leading,
    this.enabled = true,
    this.deleteTooltip = 'Remove',
  });

  final String label;
  final FwChipKind kind;
  final bool selected;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final Widget? leading;
  final bool enabled;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final labelWidget = Text(
      label,
      style: theme.typeScale.resolve(FwTextRole.label, context),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.pill)),
    );
    final padding = EdgeInsets.symmetric(
      horizontal: theme.spaceScale.of(FwSpace.s3, context),
      vertical: theme.spaceScale.of(FwSpace.s1, context),
    );
    switch (kind) {
      case FwChipKind.assist:
        return ActionChip(
          label: labelWidget,
          avatar: leading,
          shape: shape,
          padding: padding,
          onPressed: enabled ? onPressed : null,
        );
      case FwChipKind.filter:
        return FilterChip(
          label: labelWidget,
          avatar: leading,
          shape: shape,
          padding: padding,
          selected: selected,
          onSelected: enabled ? onSelected : null,
        );
      case FwChipKind.input:
        return InputChip(
          label: labelWidget,
          avatar: leading,
          shape: shape,
          padding: padding,
          onPressed: enabled ? onPressed : null,
          onDeleted: enabled ? onDeleted : null,
          deleteButtonTooltipMessage: onDeleted == null ? null : deleteTooltip,
        );
    }
  }
}

/// T06 — Divider with token border and spacing.
///
/// Decorative dividers (no [label]) are excluded from semantics. Vertical
/// dividers need a bounded height from the parent — they do not invent one.
class FwDivider extends StatelessWidget {
  const FwDivider({
    super.key,
    this.vertical = false,
    this.indent = FwSpace.s0,
    this.endIndent = FwSpace.s0,
    this.label,
    this.thickness,
    this.color = FwColorRole.border,
  });

  final bool vertical;
  final FwSpace indent;
  final FwSpace endIndent;

  /// Optional centered label; makes the divider non-decorative.
  final Widget? label;

  /// Defaults to the theme hairline (1px, root-independent).
  final FwLength? thickness;
  final FwColorRole color;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final width = (thickness ?? theme.borders.hairline).resolve(context);
    final lineColor = theme.colors.of(color);
    Widget line() => Container(
      width: vertical ? width : double.infinity,
      height: vertical ? double.infinity : width,
      color: lineColor,
    );
    final indentPx = theme.spaceScale.of(indent, context);
    final endIndentPx = theme.spaceScale.of(endIndent, context);

    Widget divided;
    if (label == null) {
      divided = line();
    } else {
      final gap = theme.spaceScale.of(FwSpace.s3, context);
      divided = vertical
          ? Column(
              children: [
                Expanded(child: line()),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: gap),
                  child: label,
                ),
                Expanded(child: line()),
              ],
            )
          : Row(
              children: [
                Expanded(child: line()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap),
                  child: label,
                ),
                Expanded(child: line()),
              ],
            );
    }

    final padded = vertical
        ? Padding(
            padding: EdgeInsets.symmetric(
              horizontal: indentPx,
            ).copyWith(right: endIndentPx),
            child: divided,
          )
        : Padding(
            padding: EdgeInsets.only(left: indentPx, right: endIndentPx),
            child: divided,
          );

    if (label == null) {
      return ExcludeSemantics(child: padded);
    }
    return padded;
  }
}
