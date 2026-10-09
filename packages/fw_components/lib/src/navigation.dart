import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'icon_button.dart';
import 'menu.dart';

// ---------------------------------------------------------------------------
// N01 — Tabs.
// ---------------------------------------------------------------------------

/// Tab strip visual treatment.
enum FwTabVariant { underline, contained }

/// One tab in [FwTabs].
@immutable
class FwTabItem {
  const FwTabItem({required this.label, this.icon, this.badgeLabel});

  final String label;
  final Widget? icon;
  final String? badgeLabel;
}

/// Tabs (N01): underline or contained tab strip over a shared tab model.
///
/// Built on the native [TabBar]/[TabController]: arrow keys, scrollable
/// strips, and indicator animation come from the platform widget; this
/// facade adds token styling and the typed item model.
///
/// Activation policy is **automatic**: tapping or arrowing to a tab selects
/// it immediately. Pair with [FwTabPanels] for stateful panels.
class FwTabs extends StatefulWidget {
  const FwTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = FwTabVariant.underline,
    this.scrollable = false,
  }) : assert(items.length > 0);

  final List<FwTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final FwTabVariant variant;
  final bool scrollable;

  @override
  State<FwTabs> createState() => _FwTabsState();
}

class _FwTabsState extends State<FwTabs> with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.items.length,
      vsync: this,
      initialIndex: widget.selectedIndex,
    );
  }

  @override
  void didUpdateWidget(FwTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != _controller.length) {
      _controller.dispose();
      _controller = TabController(
        length: widget.items.length,
        vsync: this,
        initialIndex: widget.selectedIndex.clamp(0, widget.items.length - 1),
      );
      setState(() {});
    } else if (widget.selectedIndex != _controller.index) {
      _controller.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final indicatorColor = theme.colors.of(FwColorRole.primary);
    return TabBar(
      controller: _controller,
      isScrollable: widget.scrollable,
      onTap: widget.onChanged,
      labelColor: theme.colors.of(FwColorRole.primary),
      unselectedLabelColor: theme.colors.of(FwColorRole.onSurfaceMuted),
      indicator: widget.variant == FwTabVariant.underline
          ? UnderlineTabIndicator(
              borderSide: BorderSide(color: indicatorColor, width: 2),
            )
          : BoxDecoration(
              color: theme.colors.of(FwColorRole.secondaryContainer),
              borderRadius: BorderRadius.circular(theme.radii.md),
            ),
      indicatorSize: widget.variant == FwTabVariant.underline
          ? TabBarIndicatorSize.label
          : TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      tabs: [
        for (final item in widget.items)
          Tab(
            icon: item.icon,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
                if (item.badgeLabel != null) ...[
                  const SizedBox(width: 4),
                  _TabBadge(label: item.badgeLabel!),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colors.of(FwColorRole.error),
        borderRadius: BorderRadius.circular(theme.radii.md),
      ),
      child: Text(
        label,
        style: theme.typeScale
            .resolve(FwTextRole.label, context)
            .copyWith(color: theme.colors.of(FwColorRole.onError)),
      ),
    );
  }
}

/// Tab panels with an explicit state-retention policy.
///
/// [keepAlive] true (default) builds every panel once inside an
/// [IndexedStack]: state survives tab switches. False builds only the
/// selected panel (lazy, cheaper, state discarded on switch).
class FwTabPanels extends StatelessWidget {
  const FwTabPanels({
    super.key,
    required this.selectedIndex,
    required this.children,
    this.keepAlive = true,
  });

  final int selectedIndex;
  final List<Widget> children;
  final bool keepAlive;

  @override
  Widget build(BuildContext context) {
    if (keepAlive) {
      return IndexedStack(index: selectedIndex, children: children);
    }
    return children[selectedIndex.clamp(0, children.length - 1)];
  }
}

// ---------------------------------------------------------------------------
// N02 — Navbar / app header.
// ---------------------------------------------------------------------------

/// App header (N02): brand/title slot, trailing actions, compact menu
/// trigger.
///
/// Destinations are never hidden without recourse: [onMenuPressed] opens
/// the navigation drawer (the accessible overflow pattern). For trailing
/// actions, pass [compactActions] to swap in a shorter set on narrow
/// widths instead of clipping.
class FwNavbar extends StatelessWidget {
  const FwNavbar({
    super.key,
    this.brand,
    this.title,
    this.actions = const [],
    this.compactActions = const [],
    this.onMenuPressed,
    this.menuTooltip = 'Open navigation menu',
    this.bottom,
  });

  final Widget? brand;
  final String? title;
  final List<Widget> actions;

  /// Trailing actions used below [compactBreakpoint] instead of [actions].
  final List<Widget> compactActions;
  final VoidCallback? onMenuPressed;
  final String menuTooltip;
  final Widget? bottom;

  /// Below this width [compactActions] replace [actions].
  static const double compactBreakpoint = 560;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < compactBreakpoint &&
            constraints.maxWidth != double.infinity;
        final effectiveActions = compact && compactActions.isNotEmpty
            ? compactActions
            : actions;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: theme.spaceScale.of(FwSpace.s4, context),
              ),
              decoration: BoxDecoration(
                color: theme.colors.of(FwColorRole.surface),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colors.of(FwColorRole.border),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (onMenuPressed != null) ...[
                    FwIconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: menuTooltip,
                      onPressed: onMenuPressed,
                    ),
                    SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
                  ],
                  if (brand != null) brand!,
                  if (title != null)
                    Flexible(
                      child: Text(
                        title!,
                        style: theme.typeScale.resolve(FwTextRole.h4, context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  for (final action in effectiveActions) ...[
                    SizedBox(width: theme.spaceScale.of(FwSpace.s1, context)),
                    action,
                  ],
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// N03 — Sidebar.
// ---------------------------------------------------------------------------

/// A labelled group of destinations in [FwSidebar].
@immutable
class FwNavigationGroup {
  const FwNavigationGroup({
    required this.label,
    required this.destinations,
    this.expanded = true,
  });

  final String label;
  final List<FwDestination> destinations;
  final bool expanded;
}

/// Sidebar (N03): expanded or icon-only navigation with groups and nested
/// items.
///
/// Reads the shared [FwDestination] model: the same IDs drive bottom
/// navigation, rail, and the adaptive scaffold, so selection state survives
/// responsive transitions. Collapsed icons always carry tooltips (their
/// accessible names); the selected destination exposes selected semantics.
class FwSidebar extends StatelessWidget {
  FwSidebar({
    super.key,
    this.destinations = const [],
    this.groups = const [],
    required this.selectedId,
    required this.onDestinationSelected,
    this.expanded = true,
    this.header,
    this.footer,
    this.width = 280,
    this.collapsedWidth = 72,
  }) : assert(
         destinations.isNotEmpty || groups.isNotEmpty,
         'FwSidebar needs destinations or groups',
       );

  final List<FwDestination> destinations;
  final List<FwNavigationGroup> groups;
  final String selectedId;
  final ValueChanged<String> onDestinationSelected;
  final bool expanded;
  final Widget? header;
  final Widget? footer;
  final double width;
  final double collapsedWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final all = <_Entry>[
      for (final d in destinations) _DestinationEntry(d),
      for (final g in groups) _GroupEntry(g),
    ];
    return Container(
      width: expanded ? width : collapsedWidth,
      decoration: BoxDecoration(
        color: theme.colors.of(FwColorRole.surface),
        border: Border(
          right: BorderSide(color: theme.colors.of(FwColorRole.border)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s2, context)),
              children: [for (final entry in all) _buildEntry(context, entry)],
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }

  Widget _buildEntry(BuildContext context, _Entry entry) {
    return switch (entry) {
      _DestinationEntry(:final destination) => _destinationTile(
        context,
        destination,
      ),
      _GroupEntry(:final group) => _groupSection(context, group),
    };
  }

  Widget _groupSection(BuildContext context, FwNavigationGroup group) {
    final theme = context.fwTheme;
    final children = [
      for (final d in group.destinations) _destinationTile(context, d),
    ];
    if (!expanded)
      return Column(mainAxisSize: MainAxisSize.min, children: children);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme.spaceScale.of(FwSpace.s2, context),
          ),
          child: Text(
            group.label,
            style: theme.typeScale
                .resolve(FwTextRole.label, context)
                .copyWith(color: theme.colors.of(FwColorRole.textMuted)),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _destinationTile(BuildContext context, FwDestination destination) {
    final selected = destination.id == selectedId;
    final hasChildren = destination.children.isNotEmpty;

    if (hasChildren && expanded) {
      return _ExpandableTile(
        destination: destination,
        initiallyExpanded: selected,
        parentBuilder: (context, isExpanded, toggle) => _tile(
          context,
          destination,
          selected: false,
          onTap: toggle,
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          semanticsExpanded: isExpanded,
        ),
        childBuilder: (context, child) => _tile(
          context,
          child,
          selected: child.id == selectedId,
          onTap: () => onDestinationSelected(child.id),
        ),
      );
    }
    return _tile(
      context,
      destination,
      selected: selected,
      onTap: () => onDestinationSelected(destination.id),
    );
  }

  /// One sidebar tile. [onTap] null disables; [trailing] appends an
  /// affordance (e.g. the expand chevron); [semanticsExpanded] marks an
  /// expandable parent in the semantics tree.
  Widget _tile(
    BuildContext context,
    FwDestination destination, {
    required bool selected,
    required VoidCallback? onTap,
    Widget? trailing,
    bool? semanticsExpanded,
  }) {
    final theme = context.fwTheme;
    final content = expanded
        ? Row(
            children: [
              destination.icon,
              SizedBox(width: theme.spaceScale.of(FwSpace.s3, context)),
              Expanded(
                child: Text(
                  destination.label,
                  style: theme.typeScale.resolve(FwTextRole.body, context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (destination.badgeLabel != null)
                _TabBadge(label: destination.badgeLabel!),
              if (trailing != null) trailing,
            ],
          )
        : Tooltip(
            message: destination.effectiveTooltip,
            child: Stack(
              alignment: Alignment.center,
              children: [
                destination.icon,
                if (destination.badgeLabel != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _TabBadge(label: destination.badgeLabel!),
                  ),
              ],
            ),
          );
    final button = TextButton(
      onPressed: destination.disabled ? null : onTap,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          selected
              ? theme.colors.of(FwColorRole.secondaryContainer)
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return theme.colors.of(FwColorRole.onSurfaceMuted);
          }
          return selected
              ? theme.colors.of(FwColorRole.onSecondaryContainer)
              : theme.colors.of(FwColorRole.onSurface);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radii.md),
          ),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.all(theme.spaceScale.of(FwSpace.s3, context)),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      ),
      child: content,
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: theme.spaceScale.of(FwSpace.s1, context),
      ),
      child: Semantics(
        button: true,
        selected: selected,
        expanded: semanticsExpanded,
        enabled: !destination.disabled,
        label: expanded ? null : destination.effectiveTooltip,
        child: button,
      ),
    );
  }
}

/// Expandable parent tile for nested sidebar destinations.
///
/// Replaces the material [ExpansionTile]: same expand/collapse contract but
/// rendered with the framework's tile visuals. The parent row never selects;
/// only the children report selection.
class _ExpandableTile extends StatefulWidget {
  const _ExpandableTile({
    required this.destination,
    required this.initiallyExpanded,
    required this.parentBuilder,
    required this.childBuilder,
  });

  final FwDestination destination;
  final bool initiallyExpanded;
  final Widget Function(BuildContext, bool isExpanded, VoidCallback toggle)
  parentBuilder;
  final Widget Function(BuildContext, FwDestination child) childBuilder;

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.parentBuilder(
          context,
          _expanded,
          () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: theme.spaceScale.of(FwSpace.s4, context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final child in widget.destination.children)
                  widget.childBuilder(context, child),
              ],
            ),
          ),
      ],
    );
  }
}

sealed class _Entry {
  const _Entry();
}

class _DestinationEntry extends _Entry {
  const _DestinationEntry(this.destination);
  final FwDestination destination;
}

class _GroupEntry extends _Entry {
  const _GroupEntry(this.group);
  final FwNavigationGroup group;
}

// ---------------------------------------------------------------------------
// N04 — Breadcrumb.
// ---------------------------------------------------------------------------

/// One crumb. [onTap] null marks the current page.
@immutable
class FwBreadcrumbItem {
  const FwBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// Breadcrumb (N04): typed trail with separator, current-page semantics,
/// and mobile truncation.
///
/// Below [collapseBreakpoint] only the first crumb, an overflow menu with
/// the collapsed ancestors, and the last two crumbs show; the collapsed
/// ancestors stay reachable through the menu.
class FwBreadcrumb extends StatelessWidget {
  const FwBreadcrumb({super.key, required this.items})
    : assert(items.length > 0);

  final List<FwBreadcrumbItem> items;

  static const double collapseBreakpoint = 400;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapse =
            constraints.maxWidth < collapseBreakpoint &&
            constraints.maxWidth != double.infinity;
        if (collapse && items.length > 3) {
          return _collapsed(context);
        }
        return _full(context, items);
      },
    );
  }

  Widget _full(BuildContext context, List<FwBreadcrumbItem> shown) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) _separator(context),
          _crumb(context, shown[i], isCurrent: i == shown.length - 1),
        ],
      ],
    );
  }

  Widget _collapsed(BuildContext context) {
    final ancestors = [for (var i = 1; i < items.length - 2; i++) items[i]];
    final tail = [items[items.length - 2], items[items.length - 1]];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _crumb(context, items.first, isCurrent: false),
        _separator(context),
        FwMenu<int>(
          entries: [
            for (var i = 0; i < ancestors.length; i++)
              FwMenuAction(value: i, label: ancestors[i].label),
          ],
          onSelected: (i) => ancestors[i].onTap?.call(),
          trigger: (context, controller) => FwIconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'Show collapsed pages',
            onPressed: controller.open,
          ),
        ),
        _separator(context),
        _crumb(context, tail[0], isCurrent: false),
        _separator(context),
        _crumb(context, tail[1], isCurrent: true),
      ],
    );
  }

  Widget _separator(BuildContext context) {
    final theme = context.fwTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spaceScale.of(FwSpace.s1, context),
      ),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: theme.colors.of(FwColorRole.textMuted),
      ),
    );
  }

  Widget _crumb(
    BuildContext context,
    FwBreadcrumbItem item, {
    required bool isCurrent,
  }) {
    final theme = context.fwTheme;
    final isClickable = item.onTap != null && !isCurrent;
    final text = Text(
      item.label,
      style: theme.typeScale
          .resolve(FwTextRole.body, context)
          .copyWith(
            color: isCurrent
                ? theme.colors.of(FwColorRole.onSurface)
                : theme.colors.of(FwColorRole.primary),
          ),
      overflow: TextOverflow.ellipsis,
    );
    if (!isClickable) {
      return Semantics(label: '${item.label}, current page', child: text);
    }
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(theme.radii.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: theme.spaceScale.of(FwSpace.s1, context),
        ),
        child: text,
      ),
    );
  }
}
