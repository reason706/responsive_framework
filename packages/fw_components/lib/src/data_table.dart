import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Column descriptor for [FwDataTable].
///
/// Either [cell] or [value] must render the cell: [cell] builds any widget,
/// [value] is stringified into a [Text]. Sortable columns need [sortValue].
class FwDataColumn<T> {
  const FwDataColumn({
    required this.label,
    this.sortable = false,
    this.numeric = false,
    this.flex = 1,
    this.sortValue,
    this.cell,
    this.value,
  }) : assert(
         !sortable || sortValue != null,
         'sortable columns need a sortValue',
       );

  /// Header label.
  final String label;

  /// Whether tapping the header sorts by this column.
  final bool sortable;

  /// Right-align the column (numbers, amounts).
  final bool numeric;

  /// Relative width weight inside the row.
  final int flex;

  /// Sort key for the row. Null for unsortable columns.
  final Comparable? Function(T row)? sortValue;

  /// Custom cell widget. Defaults to a [Text] of [value].
  final Widget Function(T row)? cell;

  /// Cell value, stringified when [cell] is null.
  final Object? Function(T row)? value;
}

/// Data table (S-tier): sorting, filtering, pagination, row selection,
/// and expandable rows over a typed row list.
///
/// The table is uncontrolled for view state (sort, page, selection,
/// expansion) and reports through callbacks; [rows], [filter], and
/// [columns] are owned by the caller. Filtering is caller-defined via
/// [filterTest] so any row shape can match.
///
/// Layout: the table never squeezes below [minTableWidth]; it scrolls
/// horizontally instead. Numeric columns right-align.
class FwDataTable<T> extends StatefulWidget {
  FwDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.selectable = false,
    this.onSelectionChanged,
    this.expandBuilder,
    this.pageSize = 10,
    this.filter = '',
    this.filterTest,
    this.emptyLabel = 'No rows to show.',
    this.minTableWidth = 560,
    this.initialSortColumn,
    this.initialSortAscending = true,
  }) : assert(pageSize != 0, 'pageSize of 0 is ambiguous; use -1 to disable'),
       assert(
         filter.isEmpty || filterTest != null,
         'filterTest is required when filter is non-empty',
       );

  /// Column descriptors.
  final List<FwDataColumn<T>> columns;

  /// All rows (unfiltered, unsorted — the table derives the view).
  final List<T> rows;

  /// Show a selection checkbox per row plus a select-all in the header.
  final bool selectable;

  /// Fires with the selected rows whenever selection changes.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Detail content for expandable rows. Null disables expansion.
  final Widget Function(T row)? expandBuilder;

  /// Rows per page. Negative disables pagination.
  final int pageSize;

  /// Filter query; matched via [filterTest].
  final String filter;

  /// Whether [row] matches [filter]. Required when [filter] is non-empty.
  final bool Function(T row, String filter)? filterTest;

  /// Shown when the derived view is empty.
  final String emptyLabel;

  /// The table scrolls horizontally rather than squeezing below this.
  final double minTableWidth;

  /// Initially sorted column, or null for row order.
  final int? initialSortColumn;

  /// Initial sort direction.
  final bool initialSortAscending;

  @override
  State<FwDataTable<T>> createState() => _FwDataTableState<T>();
}

class _FwDataTableState<T> extends State<FwDataTable<T>> {
  int? _sortColumn;
  late bool _ascending;
  final Set<int> _selected = {};
  final Set<int> _expanded = {};
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _sortColumn = widget.initialSortColumn;
    _ascending = widget.initialSortAscending;
  }

  @override
  void didUpdateWidget(FwDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new row set or filter invalidates view indices.
    if (oldWidget.rows != widget.rows || oldWidget.filter != widget.filter) {
      _page = 0;
      _selected.clear();
      _expanded.clear();
    }
  }

  List<T> get _view {
    var items = widget.rows;
    if (widget.filter.isNotEmpty) {
      final test = widget.filterTest!;
      items = items.where((r) => test(r, widget.filter)).toList();
    }
    if (_sortColumn != null) {
      final key = widget.columns[_sortColumn!].sortValue!;
      items = List.of(items)
        ..sort((a, b) {
          final ka = key(a);
          final kb = key(b);
          if (ka == null && kb == null) return 0;
          if (ka == null) return 1;
          if (kb == null) return -1;
          final c = ka.compareTo(kb);
          return _ascending ? c : -c;
        });
    }
    return items;
  }

  int get _pageCount {
    if (widget.pageSize < 0) return 1;
    final view = _view;
    if (view.isEmpty) return 1;
    return (view.length / widget.pageSize).ceil();
  }

  List<T> get _pageItems {
    final view = _view;
    if (widget.pageSize < 0) return view;
    final page = _page.clamp(0, _pageCount - 1);
    final start = page * widget.pageSize;
    return view.sublist(start, math.min(start + widget.pageSize, view.length));
  }

  /// Start index of the current page inside [_view].
  int get _pageStart {
    if (widget.pageSize < 0) return 0;
    return _page.clamp(0, _pageCount - 1) * widget.pageSize;
  }

  void _toggleSort(int index) {
    setState(() {
      if (_sortColumn == index) {
        _ascending = !_ascending;
      } else {
        _sortColumn = index;
        _ascending = true;
      }
      _page = 0;
    });
  }

  void _reportSelection() {
    final view = _view;
    widget.onSelectionChanged?.call(_selected.map((i) => view[i]).toSet());
  }

  void _toggleSelected(int viewIndex, bool? selected) {
    setState(() {
      if (selected == true) {
        _selected.add(viewIndex);
      } else {
        _selected.remove(viewIndex);
      }
    });
    _reportSelection();
  }

  void _toggleSelectAll(bool? selected) {
    setState(() {
      final start = _pageStart;
      for (var i = 0; i < _pageItems.length; i++) {
        if (selected == true) {
          _selected.add(start + i);
        } else {
          _selected.remove(start + i);
        }
      }
    });
    _reportSelection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final labelStyle = theme.typeScale.resolve(FwTextRole.label, context);
    final bodyStyle = theme.typeScale.resolve(FwTextRole.body, context);
    final headerStyle = labelStyle.copyWith(
      color: colors.of(FwColorRole.textMuted),
    );
    final dividerColor = colors.of(FwColorRole.border);
    final rowHeight = theme.spaceScale.of(FwSpace.s12, context);

    final view = _view;
    final pageItems = _pageItems;
    final page = _page.clamp(0, _pageCount - 1);
    final start = view.isEmpty ? 0 : page * widget.pageSize + 1;
    final end = view.isEmpty
        ? 0
        : math.min(start + pageItems.length - 1, view.length);

    Widget cell(Widget child, FwDataColumn<T> column) => Expanded(
      flex: column.flex,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spaceScale.of(FwSpace.s2, context),
        ),
        child: Align(
          alignment: column.numeric
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: child,
        ),
      ),
    );

    // Header.
    final headerCells = <Widget>[
      if (widget.expandBuilder != null) const SizedBox(width: 48),
      if (widget.selectable)
        SizedBox(
          width: 48,
          child: Builder(
            builder: (context) {
              final start = _pageStart;
              final allSelected =
                  pageItems.isNotEmpty &&
                  List.generate(
                    pageItems.length,
                    (i) => start + i,
                  ).every(_selected.contains);
              return Checkbox(
                value: allSelected,
                tristate: true,
                onChanged: _toggleSelectAll,
                semanticLabel: 'Select all rows on this page',
              );
            },
          ),
        ),
      for (var i = 0; i < widget.columns.length; i++)
        Builder(
          builder: (context) {
            final column = widget.columns[i];
            final sorted = _sortColumn == i;
            final header = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    column.label,
                    style: headerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sorted)
                  Icon(
                    _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: colors.of(FwColorRole.primary),
                    semanticLabel: _ascending
                        ? 'Sorted ascending'
                        : 'Sorted descending',
                  )
                else if (column.sortable)
                  Icon(
                    Icons.unfold_more,
                    size: 16,
                    color: colors.of(FwColorRole.textMuted),
                  ),
              ],
            );
            final content = cell(header, column);
            if (!column.sortable) return content;
            return Expanded(
              flex: column.flex,
              child: InkWell(
                onTap: () => _toggleSort(i),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spaceScale.of(FwSpace.s2, context),
                  ),
                  child: Align(
                    alignment: column.numeric
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: header,
                  ),
                ),
              ),
            );
          },
        ),
    ];

    // Body rows.
    final rows = <Widget>[];
    final pageStart = _pageStart;
    for (var p = 0; p < pageItems.length; p++) {
      final row = pageItems[p];
      final viewIndex = pageStart + p;
      final selected = _selected.contains(viewIndex);
      final expanded = _expanded.contains(viewIndex);
      rows.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MergeSemantics(
              child: Container(
                height: rowHeight,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.of(FwColorRole.primaryContainer)
                      : null,
                  border: Border(bottom: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    if (widget.expandBuilder != null)
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          icon: Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                          ),
                          tooltip: expanded ? 'Collapse row' : 'Expand row',
                          onPressed: () => setState(() {
                            if (expanded) {
                              _expanded.remove(viewIndex);
                            } else {
                              _expanded.add(viewIndex);
                            }
                          }),
                        ),
                      ),
                    if (widget.selectable)
                      SizedBox(
                        width: 48,
                        child: Checkbox(
                          value: selected,
                          onChanged: (v) => _toggleSelected(viewIndex, v),
                          semanticLabel: 'Select row',
                        ),
                      ),
                    for (final column in widget.columns)
                      cell(
                        column.cell?.call(row) ??
                            Text(
                              '${column.value?.call(row) ?? row}',
                              style: bodyStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                        column,
                      ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  theme.spaceScale.of(FwSpace.s3, context),
                ),
                decoration: BoxDecoration(
                  color: colors.of(FwColorRole.surfaceContainerLow),
                  border: Border(bottom: BorderSide(color: dividerColor)),
                ),
                child: widget.expandBuilder!(row),
              ),
          ],
        ),
      );
    }

    final table = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: rowHeight,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: dividerColor, width: 2)),
          ),
          child: Row(children: headerCells),
        ),
        if (pageItems.isEmpty)
          Padding(
            padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s6, context)),
            child: Text(
              widget.emptyLabel,
              style: bodyStyle.copyWith(
                color: colors.of(FwColorRole.textMuted),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...rows,
        if (widget.pageSize > 0 && _pageCount > 1)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: theme.spaceScale.of(FwSpace.s2, context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$start–$end of ${view.length}',
                  style: labelStyle.copyWith(
                    color: colors.of(FwColorRole.textMuted),
                  ),
                ),
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
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, widget.minTableWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: table),
        );
      },
    );
  }
}
