import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// One sticky section: a pinned [header] over [children].
class FwStickySection {
  const FwStickySection({required this.header, required this.children});

  /// Pinned header widget.
  final Widget header;

  /// Section body.
  final List<Widget> children;
}

/// Sticky headers: a scrollable list whose section headers pin to the top
/// while their section scrolls underneath.
///
/// Built on slivers: each section contributes a pinned
/// [SliverPersistentHeader] and a [SliverList]. [headerExtent] fixes the
/// header height (slivers need a known extent); headers should be that
/// tall.
class FwStickyList extends StatelessWidget {
  const FwStickyList({
    super.key,
    required this.sections,
    this.headerExtent = 48,
    this.controller,
  });

  final List<FwStickySection> sections;
  final double headerExtent;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        for (final section in sections) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              header: section.header,
              extent: headerExtent,
            ),
          ),
          SliverList(delegate: SliverChildListDelegate(section.children)),
        ],
      ],
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.header, required this.extent});

  final Widget header;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = context.fwTheme;
    // A pinned header needs an opaque backdrop so rows sliding underneath
    // don't show through.
    return Container(
      color: theme.colors.of(FwColorRole.surface),
      alignment: Alignment.centerLeft,
      child: header,
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      header != oldDelegate.header || extent != oldDelegate.extent;
}
