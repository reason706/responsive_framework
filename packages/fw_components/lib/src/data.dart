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

// ---------------------------------------------------------------------------
// Data table (D04) + responsive data list (D05).
// ---------------------------------------------------------------------------

/// Column schema for [FwDataTable].
///
/// The table never sorts, filters, or pages by itself — the app owns the
/// data. Mark a column [sortable] and handle [FwDataTable.onSort] to
/// re-query or re-sort in the app.
@immutable
class FwDataColumn<T> {
  const FwDataColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.sortable = false,
    this.numeric = false,
    this.width,
  });

  /// Stable column identity, reported to [FwDataTable.onSort].
  final String id;

  /// Header text.
  final String label;

  /// Cell content for a row.
  final Widget Function(T row) cell;

  /// Whether the header is a sort button.
  final bool sortable;

  /// Right-aligns header and cells.
  final bool numeric;

  /// Fixed column width in logical pixels; null flexes to fill.
  final double? width;
}

/// Row action for [FwDataTable]; rendered as an icon button in the
/// trailing actions column (and available to the compact builder).
@immutable
class FwDataRowAction<T> {
  const FwDataRowAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onInvoked,
  });

  final String id;

  /// Tooltip and accessible label.
  final String label;
  final IconData icon;
  final ValueChanged<T> onInvoked;
}

/// Row scope handed to [FwDataTable.compactBuilder] so phone cards can
/// offer the same selection and actions as the table.
@immutable
class FwDataRowScope<T> {
  const FwDataRowScope({
    required this.row,
    required this.selected,
    required this.onSelected,
    required this.actions,
  });

  final T row;
  final bool selected;
  final ValueChanged<bool> onSelected;

  /// Resolved row actions for this row.
  final List<FwDataRowAction<T>> actions;
}

/// Small-data table (D04) with responsive card fallback (D05).
///
/// Bounded data sets only — recommended under ~500 rows; cells should be
/// simple (text, badges, buttons). Complex cell content (nested tables,
/// editors) and virtualization are out of scope.
///
/// Sorting and selection are app-owned: the table reports sort taps and
/// selection changes, and announces sort direction and selection state.
/// Filtering and pagination are table-owned conveniences: pass [filter] +
/// [filterTest] to narrow rows client-side, and [pageSize] for built-in
/// paging with a range label and prev/next controls. For server-driven
/// data, leave those off and page/filter the [rows] yourself.
///
/// On narrow widths (below [compactBreakpoint]) with a [compactBuilder],
/// rows render as cards instead of a table — essential columns must be
/// represented by the builder, never silently dropped. Without a
/// [compactBuilder] the table scrolls horizontally.
class FwDataTable<T> extends StatefulWidget {
  FwDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.getRowId,
    this.sortColumnId,
    this.sortAscending = true,
    this.onSort,
    this.selectable = false,
    this.selectedIds = const <String>{},
    this.onSelectionChanged,
    this.rowActions,
    this.isLoading = false,
    this.loadingLabel = 'Loading…',
    this.error,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.emptyLabel = 'No results',
    this.semanticLabel,
    this.compactBreakpoint = 600,
    this.compactBuilder,
    this.filter = '',
    this.filterTest,
    this.pageSize = -1,
  }) : assert(columns.length > 0, 'FwDataTable needs at least one column.'),
       assert(
         filter.isEmpty || filterTest != null,
         'filterTest is required when filter is non-empty',
       ),
       assert(pageSize != 0, 'pageSize of 0 is ambiguous; use -1 to disable');

  final List<FwDataColumn<T>> columns;
  final List<T> rows;

  /// Stable row identity for selection.
  final String Function(T row) getRowId;

  /// Currently sorted column; null means unsorted.
  final String? sortColumnId;
  final bool sortAscending;

  /// Called with the column id when a sortable header is tapped.
  final ValueChanged<String>? onSort;

  /// Whether the checkbox column is shown.
  final bool selectable;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>>? onSelectionChanged;

  /// Trailing row actions, resolved per row.
  final List<FwDataRowAction<T>> Function(T row)? rowActions;

  final bool isLoading;
  final String loadingLabel;
  final String? error;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String emptyLabel;

  /// Accessible label for the table.
  final String? semanticLabel;

  /// Below this width the compact card layout is used (when provided).
  final double compactBreakpoint;
  final Widget Function(BuildContext context, FwDataRowScope<T> scope)?
  compactBuilder;

  /// Client-side filter query; matched via [filterTest]. Empty disables.
  final String filter;

  /// Whether [row] matches [filter]. Required when [filter] is non-empty.
  final bool Function(T row, String filter)? filterTest;

  /// Rows per page for built-in pagination. Negative disables.
  final int pageSize;

  @override
  State<FwDataTable<T>> createState() => _FwDataTableState<T>();
}

/// State for [FwDataTable]: ephemeral page position. Sort, selection,
/// filter text, and the row set itself stay caller-owned.
class _FwDataTableState<T> extends State<FwDataTable<T>> {
  int _page = 0;

  @override
  void didUpdateWidget(FwDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows ||
        oldWidget.filter != widget.filter ||
        oldWidget.pageSize != widget.pageSize) {
      _page = 0;
    }
  }

  /// Rows after the client-side filter; pagination slices this view.
  List<T> get _view {
    final rows = widget.rows;
    if (widget.filter.isEmpty) return rows;
    final test = widget.filterTest!;
    return rows.where((row) => test(row, widget.filter)).toList();
  }

  int get _pageCount {
    if (widget.pageSize < 0) return 1;
    final view = _view;
    if (view.isEmpty) return 1;
    return (view.length / widget.pageSize).ceil();
  }

  /// The rows on the current page (or the whole view when unpaged).
  List<T> get _pageRows {
    final view = _view;
    if (widget.pageSize < 0) return view;
    final page = _page.clamp(0, _pageCount - 1);
    final start = page * widget.pageSize;
    return view.sublist(start, (start + widget.pageSize).clamp(0, view.length));
  }

  void _toggleSelect(String id, bool select) {
    final next = Set<String>.of(widget.selectedIds);
    if (select) {
      next.add(id);
    } else {
      next.remove(id);
    }
    widget.onSelectionChanged?.call(next);
  }

  void _toggleSelectAll(List<T> pageRows, bool select) {
    widget.onSelectionChanged?.call(
      select ? pageRows.map(widget.getRowId).toSet() : <String>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    if (widget.isLoading) {
      return _TableState(
        semanticLabel: widget.loadingLabel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: theme.spaceScale.of(FwSpace.s3, context)),
            Flexible(
              child: Text(
                widget.loadingLabel,
                style: theme.typeScale.resolve(FwTextRole.body, context),
              ),
            ),
          ],
        ),
      );
    }
    if (widget.error != null) {
      return _TableState(
        semanticLabel: widget.error,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.error!,
              style: theme.typeScale.resolve(FwTextRole.body, context),
            ),
            if (widget.onRetry != null) ...[
              SizedBox(height: theme.spaceScale.of(FwSpace.s3, context)),
              TextButton(
                onPressed: widget.onRetry,
                child: Text(widget.retryLabel),
              ),
            ],
          ],
        ),
      );
    }
    if (_view.isEmpty) {
      return _TableState(
        semanticLabel: widget.emptyLabel,
        child: Text(
          widget.emptyLabel,
          style: theme.typeScale
              .resolve(FwTextRole.body, context)
              .copyWith(color: theme.colors.of(FwColorRole.textMuted)),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.compactBuilder != null &&
            constraints.maxWidth < widget.compactBreakpoint) {
          return _compactList(context);
        }
        return _table(context, constraints.maxWidth);
      },
    );
  }

  /// Phone layout: cards via the app-supplied builder.
  Widget _compactList(BuildContext context) {
    final builder = widget.compactBuilder!;
    final pageRows = _pageRows;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in pageRows)
          builder(
            context,
            FwDataRowScope(
              row: row,
              selected: widget.selectedIds.contains(widget.getRowId(row)),
              onSelected: (select) =>
                  _toggleSelect(widget.getRowId(row), select),
              actions: widget.rowActions?.call(row) ?? const [],
            ),
          ),
        _paginationFooter(context),
      ],
    );
  }

  /// Desktop/wide layout: native [Table] with horizontal scroll fallback.
  Widget _table(BuildContext context, double viewportWidth) {
    final theme = context.fwTheme;
    final spacing = theme.spaceScale;
    final headerStyle = theme.typeScale.resolve(FwTextRole.label, context);
    final cellPadding = EdgeInsets.symmetric(
      horizontal: spacing.of(FwSpace.s3, context),
      vertical: spacing.of(FwSpace.s2, context),
    );
    final pageRows = _pageRows;

    final columnWidths = <int, TableColumnWidth>{};
    var index = 0;
    if (widget.selectable) {
      columnWidths[index++] = const FixedColumnWidth(48);
    }
    for (final column in widget.columns) {
      columnWidths[index++] = column.width == null
          ? const FlexColumnWidth()
          : FixedColumnWidth(column.width!);
    }
    final hasActions = widget.rowActions != null;
    if (hasActions) {
      columnWidths[index] = const IntrinsicColumnWidth();
    }

    Widget headerCell(FwDataColumn<T> column) {
      final align = column.numeric
          ? Alignment.centerRight
          : Alignment.centerLeft;
      final label = Text(
        column.label,
        style: headerStyle,
        textAlign: column.numeric ? TextAlign.right : TextAlign.left,
      );
      final isSorted = widget.sortColumnId == column.id;
      final Widget content;
      if (column.sortable && widget.onSort != null) {
        final sortLabel = isSorted
            ? '${column.label}, sorted ${widget.sortAscending ? 'ascending' : 'descending'}. Activate to sort ${widget.sortAscending ? 'descending' : 'ascending'}.'
            : 'Sort by ${column.label}';
        content = Semantics(
          button: true,
          label: sortLabel,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => widget.onSort!(column.id),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: column.numeric
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Flexible(child: label),
                if (isSorted)
                  Icon(
                    widget.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 16,
                    color: theme.colors.of(FwColorRole.textMuted),
                  ),
              ],
            ),
          ),
        );
      } else {
        content = label;
      }
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Align(alignment: align, child: content),
      );
    }

    List<TableCell> dataCells(T row) {
      final id = widget.getRowId(row);
      final selected = widget.selectedIds.contains(id);
      final cells = <TableCell>[
        for (final column in widget.columns)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Align(
              alignment: column.numeric
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: column.cell(row),
            ),
          ),
      ];
      if (widget.selectable) {
        cells.insert(
          0,
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Checkbox(
                value: selected,
                onChanged: widget.onSelectionChanged == null
                    ? null
                    : (value) => _toggleSelect(id, value ?? false),
              ),
            ),
          ),
        );
      }
      if (hasActions) {
        final actions = widget.rowActions!.call(row);
        cells.add(
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in actions)
                  IconButton(
                    tooltip: action.label,
                    icon: Icon(action.icon),
                    onPressed: () => action.onInvoked(row),
                  ),
              ],
            ),
          ),
        );
      }
      return cells;
    }

    final headerRow = TableRow(
      children: [
        if (widget.selectable)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Checkbox(
                value:
                    pageRows.isNotEmpty &&
                    pageRows.every(
                      (row) =>
                          widget.selectedIds.contains(widget.getRowId(row)),
                    ),
                tristate: true,
                onChanged: widget.onSelectionChanged == null
                    ? null
                    : (value) => _toggleSelectAll(pageRows, value ?? false),
              ),
            ),
          ),
        for (final column in widget.columns) headerCell(column),
        if (hasActions)
          const TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: SizedBox.shrink(),
          ),
      ],
    );

    return Semantics(
      label: widget.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: viewportWidth),
              child: Table(
                columnWidths: columnWidths,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  headerRow,
                  for (final row in pageRows)
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.colors.of(FwColorRole.border),
                            width: theme.borders.hairline.resolve(context),
                          ),
                        ),
                        color: widget.selectedIds.contains(widget.getRowId(row))
                            ? theme.colors.of(FwColorRole.primaryContainer)
                            : null,
                      ),
                      children: dataCells(row).map((cell) {
                        return _PaddedCell(padding: cellPadding, child: cell);
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          _paginationFooter(context),
        ],
      ),
    );
  }

  /// Range label + prev/next controls. Empty when pagination is off.
  Widget _paginationFooter(BuildContext context) {
    if (widget.pageSize < 0) return const SizedBox.shrink();
    final theme = context.fwTheme;
    final view = _view;
    final page = _page.clamp(0, _pageCount - 1);
    final start = view.isEmpty ? 0 : page * widget.pageSize + 1;
    final end = view.isEmpty
        ? 0
        : (start + _pageRows.length - 1).clamp(0, view.length);
    final labelStyle = theme.typeScale
        .resolve(FwTextRole.label, context)
        .copyWith(color: theme.colors.of(FwColorRole.textMuted));
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.spaceScale.of(FwSpace.s2, context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$start–$end of ${view.length}', style: labelStyle),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
            onPressed: page > 0 ? () => setState(() => _page--) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next page',
            onPressed: page < _pageCount - 1
                ? () => setState(() => _page++)
                : null,
          ),
        ],
      ),
    );
  }
}

/// State panel (loading/error/empty) for [FwDataTable].
class _TableState extends StatelessWidget {
  const _TableState({required this.semanticLabel, required this.child});

  final String? semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Semantics(
      label: semanticLabel,
      child: Padding(
        padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s6, context)),
        child: Center(child: child),
      ),
    );
  }
}

/// Applies cell padding around a [TableCell].
class _PaddedCell extends StatelessWidget {
  const _PaddedCell({required this.padding, required this.child});

  final EdgeInsets padding;
  final TableCell child;

  @override
  Widget build(BuildContext context) {
    // TableCell must be a direct child of TableRow; pad its inner content.
    final inner = child.child;
    return TableCell(
      verticalAlignment: child.verticalAlignment,
      child: Padding(padding: padding, child: inner),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline (D07).
// ---------------------------------------------------------------------------

/// One event in [FwTimeline].
@immutable
class FwTimelineEvent {
  const FwTimelineEvent({
    required this.title,
    this.time,
    this.description,
    this.intent = FwIntent.neutral,
    this.statusLabel,
    this.action,
    this.icon,
  });

  /// Event heading (app-localized).
  final String title;

  /// App-formatted time label; formatting/timezone belong to the app.
  final String? time;

  /// Optional detail text.
  final String? description;

  /// Dot color intent.
  final FwIntent intent;

  /// Announced status (e.g. "Completed"); null leaves the dot decorative.
  final String? statusLabel;

  /// Optional trailing action (e.g. a button).
  final Widget? action;

  /// Glyph drawn inside the dot. Null keeps the plain dot.
  final IconData? icon;
}

/// Vertical timeline (D07): grouped events with status dots, time labels,
/// and optional actions.
///
/// Events render in list order for assistive technology. The connecting
/// line is decorative and excluded from semantics; the dot is decorative
/// unless [FwTimelineEvent.statusLabel] gives it a meaning.
class FwTimeline extends StatelessWidget {
  const FwTimeline({
    super.key,
    required this.events,
    this.semanticLabel,
    this.dense = false,
  });

  final List<FwTimelineEvent> events;

  /// Accessible label for the whole timeline.
  final String? semanticLabel;

  /// Compact spacing.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < events.length; i++)
            _TimelineRow(
              event: events[i],
              isLast: i == events.length - 1,
              dense: dense,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isLast,
    required this.dense,
  });

  final FwTimelineEvent event;
  final bool isLast;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final spacing = theme.spaceScale;
    final (dotRole, _) = intentRoles(event.intent);
    // Plain dots stay 12px; icon dots grow to fit the glyph.
    final dotSize = event.icon == null ? 12.0 : 28.0;
    final dot = Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: colors.of(dotRole),
        shape: BoxShape.circle,
      ),
      child: event.icon == null
          ? null
          : Icon(event.icon, size: 16, color: colors.of(FwColorRole.onPrimary)),
    );
    final dotSemantics = event.statusLabel == null
        ? ExcludeSemantics(child: dot)
        : Semantics(
            label: event.statusLabel,
            child: ExcludeSemantics(child: dot),
          );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gutter: dot plus the decorative connecting line.
          SizedBox(
            width: spacing.of(dense ? FwSpace.s4 : FwSpace.s5, context),
            child: Column(
              children: [
                SizedBox(height: spacing.of(FwSpace.s1, context)),
                dotSemantics,
                if (!isLast)
                  Expanded(
                    child: ExcludeSemantics(
                      child: Container(
                        width: theme.borders.hairline.resolve(context),
                        color: colors.of(FwColorRole.border),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: spacing.of(dense ? FwSpace.s2 : FwSpace.s3, context)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast
                    ? 0
                    : spacing.of(dense ? FwSpace.s3 : FwSpace.s5, context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.time != null)
                    Text(
                      event.time!,
                      style: theme.typeScale
                          .resolve(FwTextRole.caption, context)
                          .copyWith(color: colors.of(FwColorRole.textMuted)),
                    ),
                  Text(
                    event.title,
                    style: theme.typeScale.resolve(FwTextRole.body, context),
                  ),
                  if (event.description != null)
                    Text(
                      event.description!,
                      style: theme.typeScale.resolve(
                        FwTextRole.bodySm,
                        context,
                      ),
                    ),
                  if (event.action != null) ...[
                    SizedBox(height: spacing.of(FwSpace.s2, context)),
                    event.action!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipeable list actions (D10).
// ---------------------------------------------------------------------------

/// One swipe-revealed action.
@immutable
class FwSwipeAction {
  const FwSwipeAction({
    required this.label,
    this.icon,
    required this.onTap,
    this.intent = FwIntent.neutral,
  });

  /// Accessible label (and tooltip).
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  /// Background fill for the action pane.
  final FwIntent intent;
}

/// Swipe-to-reveal list actions (D10).
///
/// Drag the [child] toward the logical start to reveal [trailingActions],
/// toward the logical end to reveal [leadingActions]. Releasing past the
/// threshold (or flinging) snaps open; otherwise it springs closed.
/// Tapping an action invokes it and closes the pane.
///
/// Actions are real buttons while revealed and [Offstage] while hidden.
/// Critical actions should also be reachable without the gesture — this
/// widget does not provide a switch-access open affordance.
class FwSwipeable extends StatefulWidget {
  const FwSwipeable({
    super.key,
    required this.child,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.actionExtent = 72.0,
    this.onOpenChanged,
  }) : assert(
         leadingActions.length + trailingActions.length > 0,
         'FwSwipeable needs at least one action.',
       );

  final Widget child;

  /// Revealed by dragging toward the logical end.
  final List<FwSwipeAction> leadingActions;

  /// Revealed by dragging toward the logical start.
  final List<FwSwipeAction> trailingActions;

  /// Width per action in logical pixels.
  final double actionExtent;

  /// Called when the open state changes; null means closed.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<FwSwipeable> createState() => _FwSwipeableState();
}

class _FwSwipeableState extends State<FwSwipeable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// -1 = leading open, 0 = closed, 1 = trailing open.
  int _side = 0;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _trailingWidth =>
      widget.trailingActions.length * widget.actionExtent;
  double get _leadingWidth =>
      widget.leadingActions.length * widget.actionExtent;

  /// Logical drag delta: positive drags toward the logical end.
  double _logical(double dx, BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? -dx : dx;

  void _onDragUpdate(DragUpdateDetails details) {
    final logical = _logical(details.delta.dx, context);
    // Trailing actions live at the logical end; reveal by dragging
    // toward the logical start (negative logical delta).
    setState(() {
      _dragOffset += logical;
      final maxTrailing = -_trailingWidth;
      final maxLeading = _leadingWidth;
      _dragOffset = _dragOffset.clamp(maxTrailing, maxLeading);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = _logical(details.velocity.pixelsPerSecond.dx, context);
    var targetSide = 0;
    var targetOffset = 0.0;
    if (_dragOffset < -_trailingWidth * 0.4 || velocity < -400) {
      targetSide = 1;
      targetOffset = -_trailingWidth;
    } else if (_dragOffset > _leadingWidth * 0.4 || velocity > 400) {
      targetSide = -1;
      targetOffset = _leadingWidth;
    }
    _animateTo(targetSide, targetOffset);
  }

  void _animateTo(int side, double offset) {
    final start = _dragOffset;
    final tween = Tween<double>(begin: start, end: offset);
    _controller.reset();
    final animation = tween.animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    animation.addListener(() {
      setState(() => _dragOffset = animation.value);
    });
    _controller.forward().then((_) {
      if (_side != side) {
        _side = side;
        widget.onOpenChanged?.call(side != 0);
      }
    });
  }

  void _close() => _animateTo(0, 0.0);

  Widget _actionPane(
    BuildContext context,
    List<FwSwipeAction> actions,
    bool isTrailing,
  ) {
    // The side being revealed: drag direction wins, else the open side.
    final int activeSide;
    if (_dragOffset < 0) {
      activeSide = 1; // trailing
    } else if (_dragOffset > 0) {
      activeSide = -1; // leading
    } else {
      activeSide = _side;
    }
    final visible = activeSide == (isTrailing ? 1 : -1);
    return Offstage(
      offstage: !visible,
      child: Row(
        mainAxisAlignment: isTrailing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          for (final action in actions)
            _SwipeActionButton(
              action: action,
              width: widget.actionExtent,
              onTap: () {
                action.onTap();
                _close();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Stack(
      children: [
        Positioned.fill(
          child: _actionPane(context, widget.leadingActions, false),
        ),
        Positioned.fill(
          child: _actionPane(context, widget.trailingActions, true),
        ),
        GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onTap: _side != 0 ? _close : null,
          child: Transform.translate(
            offset: Offset(
              Directionality.of(context) == TextDirection.rtl
                  ? -_dragOffset
                  : _dragOffset,
              0,
            ),
            child: Container(
              color: theme.colors.of(FwColorRole.surface),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

/// One action button inside the revealed pane.
class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.action,
    required this.width,
    required this.onTap,
  });

  final FwSwipeAction action;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final (bg, fg) = intentRoles(action.intent);
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          color: theme.colors.of(bg),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (action.icon != null)
                  Icon(
                    action.icon,
                    size: 20,
                    color: theme.colors.of(fg),
                    semanticLabel: action.label,
                  ),
                Text(
                  action.label,
                  style: theme.typeScale
                      .resolve(FwTextRole.caption, context)
                      .copyWith(color: theme.colors.of(fg)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat / metric (D06).
// ---------------------------------------------------------------------------

/// Trend direction for [FwStat].
enum FwTrendDirection { up, down, flat }

/// Whether "up" is good news, bad news, or neutral for this metric.
enum FwTrendGoodness { goodUp, goodDown, neutral }

/// Stat/metric card (D06): value, label, trend, comparison period.
///
/// Formats are caller-supplied (the widget never formats numbers). The
/// trend icon and color follow [trendGoodness]: e.g. revenue going up is
/// good, churn going up is bad. The whole stat is one semantic node.
class FwStat extends StatelessWidget {
  const FwStat({
    super.key,
    required this.value,
    required this.label,
    this.trend,
    this.trendLabel,
    this.trendGoodness = FwTrendGoodness.neutral,
    this.comparisonLabel,
    this.isLoading = false,
    this.semanticLabel,
  });

  /// App-formatted value, e.g. "\$12.4k".
  final String value;

  /// What the value measures.
  final String label;

  final FwTrendDirection? trend;

  /// App-formatted trend text, e.g. "+12%".
  final String? trendLabel;

  /// Whether up/down is good, bad, or neutral.
  final FwTrendGoodness trendGoodness;

  /// Comparison period, e.g. "vs last month".
  final String? comparisonLabel;

  final bool isLoading;

  /// Announced instead of the composed text.
  final String? semanticLabel;

  FwIntent _trendIntent() {
    return switch ((trend, trendGoodness)) {
      (FwTrendDirection.up, FwTrendGoodness.goodUp) => FwIntent.success,
      (FwTrendDirection.up, FwTrendGoodness.goodDown) => FwIntent.danger,
      (FwTrendDirection.down, FwTrendGoodness.goodUp) => FwIntent.danger,
      (FwTrendDirection.down, FwTrendGoodness.goodDown) => FwIntent.success,
      _ => FwIntent.neutral,
    };
  }

  IconData _trendIcon() {
    return switch (trend) {
      FwTrendDirection.up => Icons.arrow_upward,
      FwTrendDirection.down => Icons.arrow_downward,
      FwTrendDirection.flat => Icons.remove,
      null => Icons.remove,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    if (isLoading) {
      return Semantics(
        label: 'Loading $label',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 28,
              decoration: BoxDecoration(
                color: colors.of(FwColorRole.surfaceContainer),
                borderRadius: BorderRadius.circular(
                  theme.radii.of(FwRadius.sm),
                ),
              ),
            ),
            SizedBox(height: theme.spaceScale.of(FwSpace.s1, context)),
            Text(
              label,
              style: theme.typeScale.resolve(FwTextRole.caption, context),
            ),
          ],
        ),
      );
    }

    final trendText = [
      if (trendLabel != null) trendLabel,
      if (comparisonLabel != null) comparisonLabel,
    ].join(' ');
    final announced =
        semanticLabel ??
        '$value, $label${trendText.isNotEmpty ? ', $trendText' : ''}';

    final (trendBg, _) = intentRoles(_trendIntent());
    final trendColor = trend == null
        ? colors.of(FwColorRole.textMuted)
        : colors.of(trendBg);

    return Semantics(
      label: announced,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: theme.typeScale.resolve(FwTextRole.h4, context)),
          Text(
            label,
            style: theme.typeScale
                .resolve(FwTextRole.caption, context)
                .copyWith(color: colors.of(FwColorRole.textMuted)),
          ),
          if (trend != null || trendLabel != null) ...[
            SizedBox(height: theme.spaceScale.of(FwSpace.s1, context)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_trendIcon(), size: 16, color: trendColor),
                if (trendLabel != null) ...[
                  SizedBox(width: theme.spaceScale.of(FwSpace.s1, context)),
                  Text(
                    trendLabel!,
                    style: theme.typeScale
                        .resolve(FwTextRole.bodySm, context)
                        .copyWith(color: trendColor),
                  ),
                ],
                if (comparisonLabel != null) ...[
                  SizedBox(width: theme.spaceScale.of(FwSpace.s1, context)),
                  Flexible(
                    child: Text(
                      comparisonLabel!,
                      style: theme.typeScale.resolve(
                        FwTextRole.caption,
                        context,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
