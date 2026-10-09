import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                // Long labels wrap instead of overflowing the column.
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: gap),
                    child: label,
                  ),
                ),
                Expanded(child: line()),
              ],
            )
          : Row(
              children: [
                Expanded(child: line()),
                // Long labels wrap instead of overflowing narrow rows.
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gap),
                    child: label,
                  ),
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

/// Emphasis applied to a [FwTextSegment] inside [FwRichText].
enum FwEmphasis { none, bold, italic, boldItalic, underline, strikethrough }

/// One inline segment of [FwRichText].
///
/// Use the subclasses — [FwTextSegment], [FwLinkSegment], [FwCodeSegment] —
/// rather than raw [TextSpan]s so emphasis, links, and code spans stay
/// theme-driven and recognizers are owned/disposed by [FwRichText].
sealed class FwRichSegment {
  const FwRichSegment();
}

/// Plain (optionally emphasized) text inside [FwRichText].
class FwTextSegment extends FwRichSegment {
  const FwTextSegment(this.text, {this.emphasis = FwEmphasis.none});

  final String text;
  final FwEmphasis emphasis;
}

/// A tappable inline link inside [FwRichText].
///
/// [onTap] is required — navigation itself stays the app's job; [uri] is
/// exposed as metadata for semantics.
class FwLinkSegment extends FwRichSegment {
  const FwLinkSegment(this.text, {required this.onTap, this.uri});

  final String text;
  final VoidCallback onTap;
  final Uri? uri;
}

/// A monospace code span inside [FwRichText].
class FwCodeSegment extends FwRichSegment {
  const FwCodeSegment(this.code);

  final String code;
}

/// T02 — Rich text: inline styles, links, emphasized text, code spans.
///
/// [FwRichText] owns the gesture recognizers for [FwLinkSegment]s and
/// disposes them — callers never manage recognizers. With [selectable],
/// renders [SelectableText.rich] instead; that is a documented separate
/// rendering path, not a mode toggle on the same tree.
class FwRichText extends StatefulWidget {
  const FwRichText({
    super.key,
    required this.segments,
    this.role = FwTextRole.body,
    this.selectable = false,
    this.textAlign,
    this.semanticLabel,
  });

  /// Inline segments; must not be empty.

  final List<FwRichSegment> segments;
  final FwTextRole role;
  final bool selectable;
  final TextAlign? textAlign;
  final String? semanticLabel;

  @override
  State<FwRichText> createState() => _FwRichTextState();
}

class _FwRichTextState extends State<FwRichText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(FwRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.segments, oldWidget.segments)) {
      _syncRecognizers();
    }
  }

  void _syncRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    for (final segment in widget.segments) {
      if (segment is FwLinkSegment) {
        _recognizers.add(TapGestureRecognizer()..onTap = segment.onTap);
      }
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final base = theme.typeScale.resolve(widget.role, context);
    final codeStyle = theme.typeScale.resolve(FwTextRole.code, context);
    final linkColor = theme.colors.of(FwColorRole.primary);
    var recognizerIndex = 0;
    TextSpan spanFor(FwRichSegment segment) {
      return switch (segment) {
        FwTextSegment(text: final text, emphasis: final emphasis) => TextSpan(
          text: text,
          style: switch (emphasis) {
            FwEmphasis.none => null,
            FwEmphasis.bold => const TextStyle(fontWeight: FontWeight.w700),
            FwEmphasis.italic => const TextStyle(fontStyle: FontStyle.italic),
            FwEmphasis.boldItalic => const TextStyle(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
            FwEmphasis.underline => const TextStyle(
              decoration: TextDecoration.underline,
            ),
            FwEmphasis.strikethrough => const TextStyle(
              decoration: TextDecoration.lineThrough,
            ),
          },
        ),
        FwLinkSegment(text: final text) => TextSpan(
          text: text,
          style: TextStyle(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: _recognizers[recognizerIndex++],
        ),
        FwCodeSegment(code: final code) => TextSpan(
          text: code,
          style: codeStyle.copyWith(
            backgroundColor: theme.colors
                .of(FwColorRole.surfaceContainerHigh)
                .withValues(alpha: 0.6),
          ),
        ),
      };
    }

    final rich = TextSpan(
      style: base,
      children: [for (final s in widget.segments) spanFor(s)],
    );
    final text = widget.selectable
        ? SelectableText.rich(rich, textAlign: widget.textAlign)
        : Text.rich(rich, textAlign: widget.textAlign);
    if (widget.semanticLabel == null) return text;
    return Semantics(label: widget.semanticLabel, child: text);
  }
}

/// T07 — Blockquote with directional marker and optional citation.
///
/// The marker border is logical-start so it flips in RTL. Citation renders
/// in the caption role, prefixed with an em dash.
class FwQuote extends StatelessWidget {
  const FwQuote({
    super.key,
    required this.text,
    this.citation,
    this.role = FwTextRole.body,
  });

  final String text;
  final String? citation;
  final FwTextRole role;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final gap = theme.spaceScale.of(FwSpace.s3, context);
    final style = theme.typeScale
        .resolve(role, context)
        .copyWith(fontStyle: FontStyle.italic);
    return Semantics(
      // Blockquote role: announced via structure; no dedicated flag exists.
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: theme.colors.of(FwColorRole.primary),
              width: theme.borders.hairline.resolve(context) * 2,
            ),
          ),
        ),
        padding: EdgeInsetsDirectional.only(start: gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: style),
            if (citation != null) ...[
              SizedBox(height: gap / 2),
              Text(
                '— $citation',
                style: theme.typeScale.resolve(FwTextRole.caption, context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One item of [FwBulletList]/[FwOrderedList]; [children] nest one level
/// deeper with the depth-appropriate marker.
class FwListItemData {
  const FwListItemData(this.text, {this.children = const []});

  final String text;
  final List<FwListItemData> children;
}

const _bulletMarkers = ['•', '–', '·'];
const _orderedStyles = ['1', 'a', 'i'];

String _orderedMarker(int depth, int index) {
  final n = index + 1;
  return switch (_orderedStyles[depth % _orderedStyles.length]) {
    'a' => '${String.fromCharCode(96 + ((n - 1) % 26 + 1))}.',
    'i' => '${_roman(n)}.',
    _ => '$n.',
  };
}

String _roman(int n) {
  const table = [(10, 'x'), (9, 'ix'), (5, 'v'), (4, 'iv'), (1, 'i')];
  final buf = StringBuffer();
  var rest = n;
  for (final (value, glyph) in table) {
    while (rest >= value) {
      buf.write(glyph);
      rest -= value;
    }
  }
  return buf.toString();
}

/// T07 — Unordered list with nested items and directional markers.
///
/// Markers sit on the logical start side; nesting indents with the spacing
/// scale. Items read in document order for screen readers.
class FwBulletList extends StatelessWidget {
  const FwBulletList({super.key, required this.items, this.gap});

  final List<FwListItemData> items;
  final FwSpace? gap;

  @override
  Widget build(BuildContext context) {
    return _FwListBody(
      items: items,
      gap: gap,
      markerFor: (depth, _) => _bulletMarkers[depth % _bulletMarkers.length],
    );
  }
}

/// T07 — Ordered list with nested items; numbering style changes per depth
/// (1. / a. / i.), markers on the logical start side.
class FwOrderedList extends StatelessWidget {
  const FwOrderedList({super.key, required this.items, this.gap});

  final List<FwListItemData> items;
  final FwSpace? gap;

  @override
  Widget build(BuildContext context) {
    return _FwListBody(items: items, gap: gap, markerFor: _orderedMarker);
  }
}

class _FwListBody extends StatelessWidget {
  const _FwListBody({required this.items, required this.markerFor, this.gap});

  final List<FwListItemData> items;
  final String Function(int depth, int index) markerFor;
  final FwSpace? gap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final rowGap = theme.spaceScale.of(gap ?? FwSpace.s2, context);
    final indent = theme.spaceScale.of(FwSpace.s4, context);
    final style = theme.typeScale.resolve(FwTextRole.body, context);
    Widget rows(List<FwListItemData> items, int depth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: indent,
                  child: Text(
                    markerFor(depth, i),
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(child: Text(items[i].text, style: style)),
              ],
            ),
            if (items[i].children.isNotEmpty)
              Padding(
                padding: EdgeInsetsDirectional.only(start: indent),
                child: rows(items[i].children, depth + 1),
              ),
            if (i < items.length - 1) SizedBox(height: rowGap),
          ],
        ],
      );
    }

    return rows(items, 0);
  }
}

/// T08 — Keyboard shortcut chip, e.g. `FwKbd(keys: ['⌘', 'K'])`.
///
/// Renders each key in a tokenized monospace chip, joined by "+".
/// Screen readers hear the keys joined with "plus".
class FwKbd extends StatelessWidget {
  const FwKbd({super.key, required this.keys, this.semanticLabel});

  /// Key labels; must not be empty.

  final List<String> keys;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final gap = theme.spaceScale.of(FwSpace.s1, context);
    final chipStyle = theme.typeScale
        .resolve(FwTextRole.code, context)
        .copyWith(color: theme.colors.of(FwColorRole.onSurface));
    Widget chip(String key) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spaceScale.of(FwSpace.s2, context),
        vertical: theme.spaceScale.of(FwSpace.s1, context) / 2,
      ),
      decoration: BoxDecoration(
        color: theme.colors.of(FwColorRole.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
        border: Border.all(
          color: theme.colors.of(FwColorRole.surfaceMuted),
          width: theme.borders.hairline.resolve(context),
        ),
      ),
      child: Text(key, style: chipStyle),
    );
    return Semantics(
      label: semanticLabel ?? keys.join(' plus '),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: gap,
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            chip(keys[i]),
            if (i < keys.length - 1)
              Text(
                '+',
                style: theme.typeScale.resolve(FwTextRole.caption, context),
              ),
          ],
        ],
      ),
    );
  }
}

/// T08 — Inline monospace code span with a tokenized surface.
class FwInlineCode extends StatelessWidget {
  const FwInlineCode({super.key, required this.code, this.semanticLabel});

  final String code;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final style = theme.typeScale.resolve(FwTextRole.code, context);
    final text = Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spaceScale.of(FwSpace.s1, context),
      ),
      decoration: BoxDecoration(
        color: theme.colors
            .of(FwColorRole.surfaceContainerHigh)
            .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
      ),
      child: Text(code, style: style),
    );
    if (semanticLabel == null) return text;
    return Semantics(label: semanticLabel, child: text);
  }
}

/// T08 — Code block with wrap-or-scroll and a copy action.
///
/// Code is rendered verbatim — no syntax highlighting in core (that is
/// optional adapter work per the contract). [onCopied] fires after the
/// clipboard write so the app can confirm (e.g. a toast).
class FwCodeBlock extends StatelessWidget {
  const FwCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.wrap = false,
    this.maxLines,
    this.onCopied,
    this.semanticLabel,
  });

  final String code;
  final String? language;
  final bool wrap;
  final int? maxLines;
  final VoidCallback? onCopied;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final gap = theme.spaceScale.of(FwSpace.s2, context);
    final style = theme.typeScale.resolve(FwTextRole.code, context);
    final codeText = Text(
      code,
      style: style,
      maxLines: wrap ? maxLines : null,
      overflow: wrap ? TextOverflow.ellipsis : null,
    );
    return Semantics(
      label: semanticLabel ?? (language == null ? 'Code' : '$language code'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.of(FwColorRole.surfaceContainerLow),
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
          border: Border.all(
            color: theme.colors.of(FwColorRole.surfaceMuted),
            width: theme.borders.hairline.resolve(context),
          ),
        ),
        padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s3, context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (language != null)
                  Text(
                    language!,
                    style: theme.typeScale.resolve(FwTextRole.caption, context),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy code',
                  iconSize: style.fontSize! * 1.1,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    onCopied?.call();
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            SizedBox(height: gap),
            wrap
                ? codeText
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: codeText,
                  ),
          ],
        ),
      ),
    );
  }
}
