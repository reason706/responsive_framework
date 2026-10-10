import 'package:flutter/material.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

import 'grid_spec.dart';

// ---------------------------------------------------------------------------
// L08 — Scroll area.
// ---------------------------------------------------------------------------

/// Scroll area (L08): a scrollable region with matching scrollbars.
///
/// The [controller] is caller-owned (never created internally) so scroll
/// position can be preserved and restored by the application.
class FwScrollArea extends StatelessWidget {
  const FwScrollArea({
    super.key,
    required this.child,
    this.controller,
    this.axis = Axis.vertical,
    this.showScrollbar = true,
    this.padding,
    this.primary,
  });

  final Widget child;
  final ScrollController? controller;
  final Axis axis;
  final bool showScrollbar;
  final EdgeInsetsGeometry? padding;
  final bool? primary;

  @override
  Widget build(BuildContext context) {
    final view = SingleChildScrollView(
      controller: controller,
      scrollDirection: axis,
      padding: padding,
      primary: primary,
      child: child,
    );
    if (!showScrollbar) return view;
    return Scrollbar(controller: controller, child: view);
  }
}

// ---------------------------------------------------------------------------
// L09 — Adaptive scaffold.
// ---------------------------------------------------------------------------

/// Adaptive scaffold (L09): bottom navigation on compact widths, a
/// navigation rail on medium widths, and a persistent sidebar on expanded
/// widths.
///
/// One selection model drives everything: pass the same [selectedId] and
/// [onDestinationSelected] (or a shared [FwNavigationState]) and the
/// selected destination survives responsive transitions. Bodies stay mounted
/// in an [IndexedStack], so field state and scroll position survive width
/// changes too.
class FwAdaptiveScaffold extends StatelessWidget {
  const FwAdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedId,
    required this.onDestinationSelected,
    required this.bodies,
    this.header,
    this.sidebarGroups = const [],
    this.railLeading,
    this.railTrailing,
    this.sidebarHeader,
    this.sidebarFooter,
    this.emptyBody,
  });

  final List<FwDestination> destinations;
  final String selectedId;
  final ValueChanged<String> onDestinationSelected;

  /// Body per destination id. Missing ids fall back to [emptyBody].
  final Map<String, Widget> bodies;
  final Widget? header;
  final List<FwNavigationGroup> sidebarGroups;
  final Widget? railLeading;
  final Widget? railTrailing;
  final Widget? sidebarHeader;
  final Widget? sidebarFooter;
  final Widget? emptyBody;

  int _selectedIndex() {
    final i = destinations.indexWhere((d) => d.id == selectedId);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportClass = FwGrid.classOf(constraints.maxWidth);
        final index = _selectedIndex();
        final body = IndexedStack(
          index: index,
          children: [
            for (final d in destinations)
              KeyedSubtree(
                key: ValueKey('fw-body-${d.id}'),
                child: bodies[d.id] ?? emptyBody ?? const SizedBox.shrink(),
              ),
          ],
        );

        switch (viewportClass) {
          case FwViewportClass.compact:
            return Scaffold(
              appBar: header != null
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(64),
                      child: header!,
                    )
                  : null,
              body: SafeArea(child: body),
              bottomNavigationBar: FwBottomNavigation(
                destinations: destinations,
                selectedId: selectedId,
                onDestinationSelected: onDestinationSelected,
              ),
            );
          case FwViewportClass.medium:
            return Scaffold(
              appBar: header != null
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(64),
                      child: header!,
                    )
                  : null,
              body: SafeArea(
                child: Row(
                  children: [
                    FwNavigationRail(
                      destinations: destinations,
                      selectedId: selectedId,
                      onDestinationSelected: onDestinationSelected,
                      leading: railLeading,
                      trailing: railTrailing,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                ),
              ),
            );
          case FwViewportClass.expanded:
            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    FwSidebar(
                      destinations: destinations,
                      groups: sidebarGroups,
                      selectedId: selectedId,
                      onDestinationSelected: onDestinationSelected,
                      header: header ?? sidebarHeader,
                      footer: sidebarFooter,
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// L10 — Master-detail shell (recipe).
// ---------------------------------------------------------------------------

/// Master-detail shell (L10 recipe): stacked on narrow widths, split on
/// wide ones.
///
/// On narrow widths the detail shows full-screen with system-back support
/// ([PopScope] returns to the master); both panes stay mounted in an
/// [IndexedStack] so scroll position and field state survive. On wide widths
/// both panes show side by side. A null [selectedId] means "master only".
/// [onSelected] is the route-neutral contract: the application maps it to
/// its router for deep links.
class FwMasterDetail extends StatelessWidget {
  const FwMasterDetail({
    super.key,
    required this.master,
    required this.detail,
    required this.selectedId,
    required this.onSelected,
    this.breakpoint = 720,
    this.masterWidth = 360,
    this.emptyDetail,
  });

  final Widget master;
  final Widget detail;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final double breakpoint;
  final double masterWidth;
  final Widget? emptyDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            children: [
              SizedBox(width: masterWidth, child: master),
              const VerticalDivider(width: 1),
              Expanded(
                child: selectedId == null
                    ? (emptyDetail ?? const SizedBox.shrink())
                    : detail,
              ),
            ],
          );
        }
        return PopScope(
          canPop: selectedId == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && selectedId != null) onSelected(null);
          },
          child: IndexedStack(
            index: selectedId == null ? 0 : 1,
            children: [
              master,
              if (selectedId != null) detail else const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// L12 — Sliver section adapters.
// ---------------------------------------------------------------------------

/// Padded sliver section (L12) for [CustomScrollView].
///
/// Prefer these adapters over nesting shrink-wrapped grids inside long
/// pages: slivers stay lazy and keep the scroll physics unified.
class FwSliverSection extends StatelessWidget {
  const FwSliverSection({
    super.key,
    required this.children,
    this.padding,
    this.columns = 0,
  });

  final List<Widget> children;

  /// Section padding; defaults to the pageInset alias.
  final EdgeInsetsGeometry? padding;

  /// When > 0, children lay out in a lazy grid with this many columns.
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final effectivePadding =
        padding ??
        EdgeInsets.all(
          theme.spaceScale.resolveAlias(FwSpaceAlias.pageInset, context),
        );
    if (columns > 1) {
      final gap = theme.spaceScale.of(FwSpace.s3, context);
      return SliverPadding(
        padding: effectivePadding,
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
          ),
          delegate: SliverChildListDelegate(children),
        ),
      );
    }
    return SliverPadding(
      padding: effectivePadding,
      sliver: SliverList(delegate: SliverChildListDelegate(children)),
    );
  }
}

/// Sticky header (L12): pins a section header while its content scrolls.
///
/// Paints an opaque background (defaults to the surface role) so scrolled
/// content does not show through.
class FwStickyHeader extends StatelessWidget {
  const FwStickyHeader({
    super.key,
    required this.child,
    this.minHeight = 48,
    this.maxHeight = 48,
    this.background,
    this.pinned = true,
  });

  final Widget child;
  final double minHeight;
  final double maxHeight;

  /// Background as a theme color role; defaults to [FwColorRole.surface].
  final FwColorRole? background;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: _StickyHeaderDelegate(
        minHeight: minHeight,
        maxHeight: maxHeight,
        background: theme.colors.of(background ?? FwColorRole.surface),
        padding: EdgeInsets.symmetric(
          horizontal: theme.spaceScale.resolveAlias(
            FwSpaceAlias.pageInset,
            context,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.background,
    required this.padding,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Color background;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: background,
      alignment: Alignment.centerLeft,
      padding: padding,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.background != background ||
      oldDelegate.minHeight != minHeight ||
      oldDelegate.maxHeight != maxHeight;
}
