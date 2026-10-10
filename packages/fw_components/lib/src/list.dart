import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'text.dart';

/// D02 — List tile with leading/title/subtitle/trailing slots.
///
/// A thin theme wrapper over [ListTile]: interactive tiles ([onTap])
/// expose A01 action semantics, selection is visible and announced, and
/// disabled tiles suppress invocation while keeping explicit semantics.
/// Dividers between tiles are the caller's choice — use [FwList] for the
/// divided default, or [FwDivider] directly; unlabeled dividers are
/// decorative and excluded from semantics.
class FwListTile extends StatelessWidget {
  const FwListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.semanticLabel,
    this.dense = false,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool enabled;
  final String? semanticLabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final effectiveOnTap = enabled ? onTap : null;
    final effectiveOnLongPress = enabled ? onLongPress : null;
    return Semantics(
      label: semanticLabel,
      selected: selected,
      enabled: effectiveOnTap != null || effectiveOnLongPress != null,
      excludeSemantics: semanticLabel != null,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: effectiveOnTap,
        onLongPress: effectiveOnLongPress,
        selected: selected,
        dense: dense,
        enabled: enabled,
        selectedTileColor: colors.of(FwColorRole.secondaryContainer),
        selectedColor: colors.of(FwColorRole.onSecondaryContainer),
        iconColor: colors.of(FwColorRole.textSubtle),
        textColor: colors.of(FwColorRole.text),
        contentPadding: EdgeInsets.symmetric(
          horizontal: theme.spaceScale.of(FwSpace.s4, context),
          vertical: theme.spaceScale.of(FwSpace.s1, context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
        ),
      ),
    );
  }
}

/// D02 — List of tiles with the divider policy applied.
///
/// [divided] inserts [FwDivider] separators (decorative, excluded from
/// semantics). Set false and manage your own separators when tiles need
/// grouping headers or custom spacing.
class FwList extends StatelessWidget {
  const FwList({
    super.key,
    required this.children,
    this.divided = true,
    this.padding = FwSpace.s0,
    this.controller,
  });

  final List<Widget> children;
  final bool divided;
  final FwSpace padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final pad = theme.spaceScale.of(padding, context);
    if (!divided) {
      return ListView(
        controller: controller,
        padding: EdgeInsets.all(pad),
        children: children,
      );
    }
    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.all(pad),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) => const FwDivider(),
    );
  }
}

/// Tree node data (+D11).
///
/// The tree is app-owned: [children] defines the hierarchy, expansion is
/// controlled via [expandedIds] or managed internally.
class FwTreeNode {
  const FwTreeNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.icon,
  });

  /// Stable identifier used in [FwTreeView.expandedIds].
  final String id;

  /// Visible label (app-localized).
  final String label;

  /// Child nodes. Empty means a leaf.
  final List<FwTreeNode> children;

  /// Optional leading icon.
  final Widget? icon;

  /// True when this node has children.
  bool get isParent => children.isNotEmpty;
}

/// Hierarchical expandable list (+D11).
///
/// Nodes render with indentation guides; parent rows are buttons that toggle
/// expansion. Expansion can be controlled ([expandedIds]/[onExpansionChanged])
/// or managed internally. Screen readers get the level and expanded state.
class FwTreeView extends StatefulWidget {
  const FwTreeView({
    super.key,
    required this.nodes,
    this.expandedIds,
    this.onExpansionChanged,
    this.onSelect,
    this.selectedId,
  });

  /// Root-level nodes.
  final List<FwTreeNode> nodes;

  /// Controlled set of expanded node ids. Null manages internally.
  final Set<String>? expandedIds;

  /// Called when the user toggles a node.
  final ValueChanged<Set<String>>? onExpansionChanged;

  /// Called when a leaf (or any node) is tapped.
  final ValueChanged<FwTreeNode>? onSelect;

  /// Currently selected node id.
  final String? selectedId;

  @override
  State<FwTreeView> createState() => _FwTreeViewState();
}

class _FwTreeViewState extends State<FwTreeView> {
  final Set<String> _open = {};

  Set<String> get _expanded => widget.expandedIds ?? _open;

  void _toggle(String id) {
    final next = Set<String>.of(_expanded);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onExpansionChanged?.call(next);
    if (widget.expandedIds == null) {
      setState(() {
        _open
          ..clear()
          ..addAll(next);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final node in widget.nodes) _node(context, node, 0),
      ],
    );
  }

  Widget _node(BuildContext context, FwTreeNode node, int depth) {
    final theme = context.fwTheme;
    final spacing = theme.spaceScale;
    final expanded = _expanded.contains(node.id);
    final selected = widget.selectedId == node.id;
    final indent = spacing.of(FwSpace.s5, context) * depth;

    Widget row = Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: InkWell(
        onTap: () {
          if (node.isParent) {
            _toggle(node.id);
          } else {
            widget.onSelect?.call(node);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing.of(FwSpace.s2, context),
            horizontal: spacing.of(FwSpace.s3, context),
          ),
          child: Row(
            children: [
              if (node.isParent)
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                )
              else
                const SizedBox(width: 20),
              if (node.icon != null) ...[
                node.icon!,
                SizedBox(width: spacing.of(FwSpace.s2, context)),
              ],
              Expanded(child: Text(node.label)),
            ],
          ),
        ),
      ),
    );

    // Merge semantics: label + level + expanded state.
    row = Semantics(
      button: node.isParent,
      expanded: node.isParent ? expanded : null,
      selected: selected,
      label: '${node.label}, level ${depth + 1}',
      child: ExcludeSemantics(child: row),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        if (node.isParent && expanded)
          for (final child in node.children) _node(context, child, depth + 1),
      ],
    );
  }
}
