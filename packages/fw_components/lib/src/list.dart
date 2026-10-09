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
