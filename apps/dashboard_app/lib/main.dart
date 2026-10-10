/// Dashboard pilot: an adaptive dashboard built ONLY on public fw exports.
///
/// Exercises: adaptive navigation (bottom nav / rail / sidebar on one
/// selection model), FwStat, FwDataTable (sort/select), FwCard, FwAlert.
import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

void main() => runApp(const DashboardPilotApp());

class DashboardPilotApp extends StatelessWidget {
  const DashboardPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard pilot',
      theme: FwTheme.light().toThemeData(),
      darkTheme: FwTheme.dark().toThemeData(),
      home: const FwViewportQuery(child: DashboardShell()),
    );
  }
}

class _Product {
  const _Product(this.id, this.name, this.category, this.price, this.stock);
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
}

const _products = [
  _Product('p1', 'Acme Widget', 'Widgets', 19.99, 142),
  _Product('p2', 'Gizmo Pro', 'Gizmos', 49.50, 37),
  _Product('p3', 'Doohickey', 'Widgets', 9.99, 508),
  _Product('p4', 'Thingamajig', 'Gizmos', 129.00, 12),
  _Product('p5', 'Whatchamacallit', 'Misc', 24.75, 89),
];

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  String _destination = 'home';

  static final _destinations = [
    const FwDestination(id: 'home', label: 'Home', icon: Icon(Icons.home_outlined)),
    const FwDestination(id: 'orders', label: 'Orders', icon: Icon(Icons.receipt_long_outlined)),
    const FwDestination(id: 'settings', label: 'Settings', icon: Icon(Icons.settings_outlined)),
  ];

  @override
  Widget build(BuildContext context) {
    return FwResponsiveBuilder(
      builder: (context, width, breakpoint) {
        final body = _destination == 'home'
            ? const DashboardBody()
            : Center(child: FwText('$_destination — placeholder', role: FwTextRole.h2));
        if (width < 600) {
          return Scaffold(
            body: body,
            bottomNavigationBar: FwBottomNavigation(
              destinations: _destinations,
              selectedId: _destination,
              onDestinationSelected: (id) => setState(() => _destination = id),
            ),
          );
        }
        if (width < 1024) {
          return Scaffold(
            body: Row(
              children: [
                FwNavigationRail(
                  destinations: _destinations,
                  selectedId: _destination,
                  onDestinationSelected: (id) => setState(() => _destination = id),
                ),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              FwSidebar(
                destinations: _destinations,
                selectedId: _destination,
                onDestinationSelected: (id) => setState(() => _destination = id),
              ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  String? _sortColumn;
  bool _ascending = true;
  Set<String> _selected = {};

  List<_Product> get _rows {
    final rows = List<_Product>.of(_products);
    if (_sortColumn == 'price') {
      rows.sort((a, b) => _ascending
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price));
    } else if (_sortColumn == 'stock') {
      rows.sort((a, b) => _ascending
          ? a.stock.compareTo(b.stock)
          : b.stock.compareTo(a.stock));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: FwInsets.token(FwSpace.s4).resolve(context),
      child: FwVStack(
        gap: FwSpace.s4,
        children: [
          const FwText('Good morning', role: FwTextRole.h1, heading: true),
          const FwAlert(
            intent: FwAlertIntent.info,
            title: '3 orders need review before noon.',
          ),
          const FwAutoGrid(
            minItemWidth: 160,
            gap: FwSpace.s3,
            children: [
              FwStat(
                value: '\$12.4k',
                label: 'Revenue',
                trend: FwTrendDirection.up,
                trendLabel: '+8.2%',
                trendGoodness: FwTrendGoodness.goodUp,
                comparisonLabel: 'vs last week',
              ),
              FwStat(
                value: '1,284',
                label: 'Orders',
                trend: FwTrendDirection.up,
                trendLabel: '+3.1%',
                trendGoodness: FwTrendGoodness.goodUp,
                comparisonLabel: 'vs last week',
              ),
              FwStat(
                value: '4.2%',
                label: 'Churn',
                trend: FwTrendDirection.down,
                trendLabel: '-0.6%',
                trendGoodness: FwTrendGoodness.goodDown,
                comparisonLabel: 'vs last week',
              ),
            ],
          ),
          const FwText('Products', role: FwTextRole.h2, heading: true),
          FwDataTable<_Product>(
            columns: [
              FwDataColumn(
                id: 'name',
                label: 'Name',
                cell: (p) => Text(p.name),
              ),
              FwDataColumn(
                id: 'price',
                label: 'Price',
                numeric: true,
                sortable: true,
                cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
              ),
              FwDataColumn(
                id: 'stock',
                label: 'Stock',
                numeric: true,
                sortable: true,
                cell: (p) => Text('${p.stock}'),
              ),
            ],
            rows: _rows,
            getRowId: (p) => p.id,
            sortColumnId: _sortColumn,
            sortAscending: _ascending,
            onSort: (id) => setState(() {
              if (_sortColumn == id) {
                _ascending = !_ascending;
              } else {
                _sortColumn = id;
                _ascending = true;
              }
            }),
            selectable: true,
            selectedIds: _selected,
            onSelectionChanged: (ids) => setState(() => _selected = ids),
          ),
          if (_selected.isNotEmpty)
            FwText('${_selected.length} selected', role: FwTextRole.label),
        ],
      ),
    );
  }
}
