import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

// ---------------------------------------------------------------------------
// Accordion (D03).
// ---------------------------------------------------------------------------

/// One accordion panel.
///
/// [id] is the stable identity used in [FwAccordion.openIds] and
/// [FwAccordion.onOpenChanged]. [header] is the tappable header content
/// (typically text); [body] is the collapsible content.
@immutable
class FwAccordionItem {
  const FwAccordionItem({
    required this.id,
    required this.header,
    required this.body,
    this.enabled = true,
    this.keepAlive = true,
  });

  /// Stable panel identity.
  final String id;

  /// Header content; rendered inside the header button row.
  final Widget header;

  /// Collapsible panel content.
  final Widget body;

  /// Disabled panels do not respond to taps and report disabled semantics.
  final bool enabled;

  /// When true (default) the body state is retained while closed and the
  /// content is hidden from semantics/focus. When false the body is
  /// disposed while closed.
  final bool keepAlive;
}

/// Accordion/collapse (D03): a list of expandable panels.
///
/// State is controlled: [openIds] holds the currently open panel IDs and
/// [onOpenChanged] reports the next set after applying the
/// [allowMultiple] policy (single-open clears the others). Disabled panels
/// never toggle. Each header is a keyboard-operable button reporting
/// expanded semantics; closed content is removed from the semantics tree
/// and cannot take focus (focus inside a closing panel moves to its
/// header). Bodies animate open/closed on the motion token.
class FwAccordion extends StatefulWidget {
  const FwAccordion({
    super.key,
    required this.items,
    this.openIds = const <String>{},
    this.onOpenChanged,
    this.allowMultiple = false,
    this.showDividers = true,
    this.expandIcon = Icons.expand_more,
    this.headerPadding,
    this.bodyPadding,
    this.animationSpeed = FwMotionSpeed.fast,
  });

  /// Panels in display order. IDs must be unique.
  final List<FwAccordionItem> items;

  /// Currently open panel IDs (controlled).
  final Set<String> openIds;

  /// Called with the next open set after the single/multiple policy.
  final ValueChanged<Set<String>>? onOpenChanged;

  /// When false (default) opening a panel closes the others.
  final bool allowMultiple;

  /// Draw hairline dividers between panels.
  final bool showDividers;

  /// Trailing expand/collapse glyph; rotates 180° when open.
  final IconData expandIcon;

  /// Padding inside each header button.
  final EdgeInsetsGeometry? headerPadding;

  /// Padding around each panel body.
  final EdgeInsetsGeometry? bodyPadding;

  /// Motion speed for expand/collapse.
  final FwMotionSpeed animationSpeed;

  @override
  State<FwAccordion> createState() => _FwAccordionState();
}

class _FwAccordionState extends State<FwAccordion> {
  final Map<String, FocusScopeNode> _bodyScopes = {};
  final Map<String, FocusNode> _headerNodes = {};

  @override
  void dispose() {
    for (final node in _bodyScopes.values) {
      node.dispose();
    }
    for (final node in _headerNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _toggle(FwAccordionItem item) {
    if (!item.enabled) return;
    final wasOpen = widget.openIds.contains(item.id);
    if (wasOpen) {
      // Focus must not stay inside hidden content.
      final scope = _bodyScopes[item.id];
      if (scope != null && scope.hasFocus) {
        _headerNodes[item.id]?.requestFocus();
      }
    }
    final next = Set<String>.of(widget.openIds);
    if (wasOpen) {
      next.remove(item.id);
    } else {
      if (!widget.allowMultiple) next.clear();
      next.add(item.id);
    }
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final children = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isOpen = widget.openIds.contains(item.id);
      if (i > 0 && widget.showDividers) {
        children.add(const _Hairline());
      }
      children.add(
        _Header(
          item: item,
          isOpen: isOpen,
          focusNode: _headerNodes.putIfAbsent(item.id, FocusNode.new),
          expandIcon: widget.expandIcon,
          padding: widget.headerPadding,
          animationSpeed: widget.animationSpeed,
          onTap: () => _toggle(item),
        ),
      );
      children.add(
        ClipRect(
          child: AnimatedSize(
            duration: theme.motion.durationFor(context, widget.animationSpeed),
            curve: theme.motion.curveFor(context),
            child: _PanelBody(
              item: item,
              isOpen: isOpen,
              scopeNode: _bodyScopes.putIfAbsent(item.id, FocusScopeNode.new),
              padding: widget.bodyPadding,
            ),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Hairline divider between panels (theme hairline, decorative).
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return ExcludeSemantics(
      child: Container(
        height: theme.borders.hairline.resolve(context),
        color: theme.colors.of(FwColorRole.border),
      ),
    );
  }
}

/// Header button row with expanded semantics and rotating glyph.
class _Header extends StatelessWidget {
  const _Header({
    required this.item,
    required this.isOpen,
    required this.focusNode,
    required this.expandIcon,
    required this.padding,
    required this.animationSpeed,
    required this.onTap,
  });

  final FwAccordionItem item;
  final bool isOpen;
  final FocusNode focusNode;
  final IconData expandIcon;
  final EdgeInsetsGeometry? padding;
  final FwMotionSpeed animationSpeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final spacing = theme.spaceScale;
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: spacing.of(FwSpace.s4, context),
          vertical: spacing.of(FwSpace.s3, context),
        );
    final iconColor = theme.colors.of(
      item.enabled ? FwColorRole.textMuted : FwColorRole.textSubtle,
    );
    return Semantics(
      button: true,
      expanded: isOpen,
      enabled: item.enabled,
      child: InkWell(
        focusNode: focusNode,
        onTap: item.enabled ? onTap : null,
        child: Padding(
          padding: resolvedPadding,
          child: Row(
            children: [
              Expanded(child: item.header),
              SizedBox(width: spacing.of(FwSpace.s2, context)),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0.0,
                duration: theme.motion.durationFor(context, animationSpeed),
                curve: theme.motion.curveFor(context),
                child: Icon(expandIcon, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel body: retained-but-hidden or disposed when closed.
class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.item,
    required this.isOpen,
    required this.scopeNode,
    required this.padding,
  });

  final FwAccordionItem item;
  final bool isOpen;
  final FocusScopeNode scopeNode;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final spacing = theme.spaceScale;
    final body = FocusScope(
      node: scopeNode,
      child: Padding(
        padding:
            padding ??
            EdgeInsets.only(
              left: spacing.of(FwSpace.s4, context),
              right: spacing.of(FwSpace.s4, context),
              bottom: spacing.of(FwSpace.s4, context),
            ),
        child: item.body,
      ),
    );
    // Visibility stays in the tree so toggling never remounts the body;
    // maintainState decides whether closed content is retained or disposed.
    return Visibility(
      visible: isOpen,
      maintainState: item.keepAlive,
      maintainAnimation: true,
      child: body,
    );
  }
}
