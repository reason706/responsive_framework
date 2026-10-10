import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

// ---------------------------------------------------------------------------
// Description list (P4): dense key-value list.
// ---------------------------------------------------------------------------

/// Layout for [FwDescriptionList] rows.
enum FwDescriptionListLayout {
  /// Term and description side by side (like a table row).
  horizontal,

  /// Term stacked above the description.
  stacked,
}

/// A single term/description pair in [FwDescriptionList].
class FwDescriptionItem {
  const FwDescriptionItem({
    required this.term,
    required this.description,
    this.icon,
  });

  /// The key — rendered in the label role, muted.
  final String term;

  /// The value. Any widget; typically text, a link, or a badge.
  final Widget description;

  /// Optional leading icon for the term.
  final IconData? icon;
}

/// Description list (P4): a dense key-value list for metadata, settings
/// summaries, and detail panels.
///
/// Row gaps use the density-scaled [FwSpaceAlias.fieldGap], so the list
/// compacts automatically inside [FwDensityScope] or a compact theme —
/// the P3.2 density pairing. Terms render in the label role; descriptions
/// take the remaining space.
///
/// Demand note: hosted-plan item (improvement-plan-2 §4 P4 slate).
class FwDescriptionList extends StatelessWidget {
  const FwDescriptionList({
    super.key,
    required this.items,
    this.layout = FwDescriptionListLayout.horizontal,
    this.termFlex = 2,
    this.descriptionFlex = 3,
    this.divided = false,
    this.rowGap,
  }) : assert(termFlex > 0, 'termFlex must be positive'),
       assert(descriptionFlex > 0, 'descriptionFlex must be positive');

  /// The term/description pairs.
  final List<FwDescriptionItem> items;

  /// Row arrangement.
  final FwDescriptionListLayout layout;

  /// Flex of the term column in [FwDescriptionListLayout.horizontal].
  final int termFlex;

  /// Flex of the description column in [FwDescriptionListLayout.horizontal].
  final int descriptionFlex;

  /// Whether to draw dividers between rows.
  final bool divided;

  /// Gap between rows. Null uses the density-scaled [FwSpaceAlias.fieldGap].
  final FwSpace? rowGap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final s = theme.spaceScale;
    final gap = rowGap != null
        ? s.of(rowGap!, context)
        : s.resolveAlias(FwSpaceAlias.fieldGap, context);

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      rows.add(_row(context, items[i]));
      if (divided && i < items.length - 1) {
        rows.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: gap / 2),
            child: const Divider(height: 1),
          ),
        );
      } else if (i < items.length - 1) {
        rows.add(SizedBox(height: gap));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _row(BuildContext context, FwDescriptionItem item) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final s = theme.spaceScale;

    final term = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: theme.iconSizes.of(FwIconSize.sm),
            color: colors.of(FwColorRole.onSurfaceMuted),
          ),
          SizedBox(width: s.of(FwSpace.s1, context)),
        ],
        Flexible(
          child: Text(
            item.term,
            style: theme.typeScale
                .resolve(FwTextRole.label, context)
                .copyWith(color: colors.of(FwColorRole.onSurfaceMuted)),
          ),
        ),
      ],
    );

    switch (layout) {
      case FwDescriptionListLayout.horizontal:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: termFlex, child: term),
            SizedBox(width: s.of(FwSpace.s3, context)),
            Expanded(flex: descriptionFlex, child: item.description),
          ],
        );
      case FwDescriptionListLayout.stacked:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            term,
            SizedBox(height: s.of(FwSpace.s1, context)),
            item.description,
          ],
        );
    }
  }
}
