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
/// editors) and virtualization are out of scope. Sorting, filtering, and
/// paging are app-owned: the table reports sort taps and selection
/// changes, and announces sort direction and selection state.
///
/// On narrow widths (below [compactBreakpoint]) with a [compactBuilder],
/// rows render as cards instead of a table — essential columns must be
/// represented by the builder, never silently dropped. Without a
/// [compactBuilder] the table scrolls horizontally.
class FwDataTable<T> extends StatelessWidget {
  const FwDataTable({
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
  }) : assert(columns.length > 0, 'FwDataTable needs at least one column.');

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

  void _toggleSelect(String id, bool select) {
    final next = Set<String>.of(selectedIds);
    if (select) {
      next.add(id);
    } else {
      next.remove(id);
    }
    onSelectionChanged?.call(next);
  }

  void _toggleSelectAll(bool select) {
    onSelectionChanged?.call(select ? rows.map(getRowId).toSet() : <String>{});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    if (isLoading) {
      return _TableState(
        semanticLabel: loadingLabel,
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
                loadingLabel,
                style: theme.typeScale.resolve(FwTextRole.body, context),
              ),
            ),
          ],
        ),
      );
    }
    if (error != null) {
      return _TableState(
        semanticLabel: error,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error!,
              style: theme.typeScale.resolve(FwTextRole.body, context),
            ),
            if (onRetry != null) ...[
              SizedBox(height: theme.spaceScale.of(FwSpace.s3, context)),
              TextButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      );
    }
    if (rows.isEmpty) {
      return _TableState(
        semanticLabel: emptyLabel,
        child: Text(
          emptyLabel,
          style: theme.typeScale
              .resolve(FwTextRole.body, context)
              .copyWith(color: theme.colors.of(FwColorRole.textMuted)),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (compactBuilder != null &&
            constraints.maxWidth < compactBreakpoint) {
          return _compactList(context);
        }
        return _table(context, constraints.maxWidth);
      },
    );
  }

  /// Phone layout: cards via the app-supplied builder.
  Widget _compactList(BuildContext context) {
    final builder = compactBuilder!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          builder(
            context,
            FwDataRowScope(
              row: row,
              selected: selectedIds.contains(getRowId(row)),
              onSelected: (select) => _toggleSelect(getRowId(row), select),
              actions: rowActions?.call(row) ?? const [],
            ),
          ),
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

    final columnWidths = <int, TableColumnWidth>{};
    var index = 0;
    if (selectable) {
      columnWidths[index++] = const FixedColumnWidth(48);
    }
    for (final column in columns) {
      columnWidths[index++] = column.width == null
          ? const FlexColumnWidth()
          : FixedColumnWidth(column.width!);
    }
    final hasActions = rowActions != null;
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
      final isSorted = sortColumnId == column.id;
      final Widget content;
      if (column.sortable && onSort != null) {
        final sortLabel = isSorted
            ? '${column.label}, sorted ${sortAscending ? 'ascending' : 'descending'}. Activate to sort ${sortAscending ? 'descending' : 'ascending'}.'
            : 'Sort by ${column.label}';
        content = Semantics(
          button: true,
          label: sortLabel,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => onSort!(column.id),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: column.numeric
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Flexible(child: label),
                if (isSorted)
                  Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
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
      final id = getRowId(row);
      final selected = selectedIds.contains(id);
      final cells = <TableCell>[
        for (final column in columns)
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
      if (selectable) {
        cells.insert(
          0,
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Checkbox(
                value: selected,
                onChanged: onSelectionChanged == null
                    ? null
                    : (value) => _toggleSelect(id, value ?? false),
              ),
            ),
          ),
        );
      }
      if (hasActions) {
        final actions = rowActions!.call(row);
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
        if (selectable)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Checkbox(
                value: selectedIds.length == rows.length && rows.isNotEmpty,
                tristate: true,
                onChanged: onSelectionChanged == null
                    ? null
                    : (value) => _toggleSelectAll(value ?? false),
              ),
            ),
          ),
        for (final column in columns) headerCell(column),
        if (hasActions)
          const TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: SizedBox.shrink(),
          ),
      ],
    );

    return Semantics(
      label: semanticLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: viewportWidth),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              headerRow,
              for (final row in rows)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colors.of(FwColorRole.border),
                        width: theme.borders.hairline.resolve(context),
                      ),
                    ),
                    color: selectedIds.contains(getRowId(row))
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
}

/// Vertical timeline (D07): grouped events with status dots, time labels,
/// and optional actions.
///
/// Events render in list order for assistive technology. The connecting
/// line is decorative and excluded from semantics; the dot is decorative
/// unless [FwTimelineEvent.statusLabel] gives it a meaning.
class FwTimeline extends StatelessWidget {
  const FwTimeline({super.key, required this.events, this.semanticLabel});

  final List<FwTimelineEvent> events;

  /// Accessible label for the whole timeline.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < events.length; i++)
            _TimelineRow(event: events[i], isLast: i == events.length - 1),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final FwTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final spacing = theme.spaceScale;
    final (dotRole, _) = intentRoles(event.intent);
    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: colors.of(dotRole),
        shape: BoxShape.circle,
      ),
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
            width: spacing.of(FwSpace.s5, context),
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
          SizedBox(width: spacing.of(FwSpace.s3, context)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : spacing.of(FwSpace.s5, context),
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
