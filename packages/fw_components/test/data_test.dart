import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(
      child: Center(child: SizedBox(width: 400, child: child)),
    ),
  ),
);

/// All non-empty labels in the semantics subtree rooted at [node].
List<String> semanticsLabels(SemanticsNode node) {
  final labels = <String>[];
  void walk(SemanticsNode n) {
    if (n.label.isNotEmpty) labels.add(n.label);
    n.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(node);
  return labels;
}

/// Nodes in the subtree that carry an expanded/collapsed state.
List<SemanticsNode> expandedStateNodes(SemanticsNode node) {
  final out = <SemanticsNode>[];
  void walk(SemanticsNode n) {
    if (n.getSemanticsData().flagsCollection.hasExpandedState) out.add(n);
    n.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(node);
  return out;
}

class _User {
  const _User(this.id, this.name, this.role);
  final String id;
  final String name;
  final String role;
}

List<FwDataColumn<_User>> _userColumns() => [
  FwDataColumn<_User>(
    id: 'name',
    label: 'Name',
    sortable: true,
    cell: (u) => Text(u.name),
  ),
  FwDataColumn<_User>(id: 'role', label: 'Role', cell: (u) => Text(u.role)),
];

const _users = [
  _User('u1', 'Ada', 'Engineer'),
  _User('u2', 'Grace', 'Admiral'),
];

void main() {
  group('B09 FwStatusDot', () {
    testWidgets('renders dot and caller-supplied label', (tester) async {
      await tester.pumpWidget(host(const FwStatusDot(label: 'Online')));
      expect(find.text('Online'), findsOneWidget);
      // The dot is a circle container.
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(FwStatusDot),
          matching: find.byType(Container),
        ),
      );
      expect((dot.decoration! as BoxDecoration).shape, BoxShape.circle);
    });

    testWidgets('dot uses the intent color', (tester) async {
      await tester.pumpWidget(
        host(const FwStatusDot(label: 'Degraded', intent: FwIntent.warning)),
      );
      final theme = FwTheme.light();
      final (role, _) = intentRoles(FwIntent.warning);
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(FwStatusDot),
          matching: find.byType(Container),
        ),
      );
      expect((dot.decoration! as BoxDecoration).color, theme.colors.of(role));
    });

    testWidgets('single semantic node announces the label', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwStatusDot(
              label: 'Away',
              intent: FwIntent.neutral,
              semanticLabel: 'Away — back in 5 minutes',
            ),
          ),
        );
        final labels = semanticsLabels(
          tester.getSemantics(find.byType(FwStatusDot)),
        );
        expect(labels, ['Away — back in 5 minutes']);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('D03 FwAccordion', () {
    List<FwAccordionItem> items({
      bool secondDisabled = false,
      bool keepAlive = true,
    }) => [
      FwAccordionItem(
        id: 'a',
        header: const Text('Panel A'),
        body: const Text('Body A content'),
        keepAlive: keepAlive,
      ),
      FwAccordionItem(
        id: 'b',
        header: const Text('Panel B'),
        body: const Text('Body B content'),
        enabled: !secondDisabled,
        keepAlive: keepAlive,
      ),
    ];

    testWidgets('tap toggles and reports the next open set', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(items: items(), onOpenChanged: (ids) => reported = ids),
        ),
      );
      await tester.tap(find.text('Panel A'));
      expect(reported, {'a'});
      // Controlled: parent applies the set.
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(),
            openIds: const {'a'},
            onOpenChanged: (ids) => reported = ids,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Body A content'), findsOneWidget);
      await tester.tap(find.text('Panel A'));
      expect(reported, isEmpty);
    });

    testWidgets('single-open policy closes the other panel', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(),
            openIds: const {'a'},
            onOpenChanged: (ids) => reported = ids,
          ),
        ),
      );
      await tester.tap(find.text('Panel B'));
      expect(reported, {'b'});
    });

    testWidgets('allowMultiple keeps other panels open', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(),
            openIds: const {'a'},
            allowMultiple: true,
            onOpenChanged: (ids) => reported = ids,
          ),
        ),
      );
      await tester.tap(find.text('Panel B'));
      expect(reported, {'a', 'b'});
    });

    testWidgets('disabled panel does not toggle', (tester) async {
      var called = false;
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(secondDisabled: true),
            onOpenChanged: (_) => called = true,
          ),
        ),
      );
      await tester.tap(find.text('Panel B'));
      expect(called, isFalse);
    });

    testWidgets('headers report expanded semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(FwAccordion(items: items(), openIds: const {'a'})),
        );
        await tester.pumpAndSettle();
        final nodes = expandedStateNodes(
          tester.getSemantics(find.byType(FwAccordion)),
        );
        expect(
          nodes.map((n) => n.getSemanticsData().flagsCollection.isExpanded),
          [true, false],
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('closed body leaves the semantics tree', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(FwAccordion(items: items())));
        await tester.pumpAndSettle();
        var labels = semanticsLabels(
          tester.getSemantics(find.byType(FwAccordion)),
        );
        expect(labels.join(' '), isNot(contains('Body A content')));
        // Open it (uncontrolled shell for the test).
        await tester.pumpWidget(
          host(FwAccordion(items: items(), openIds: const {'a'})),
        );
        await tester.pumpAndSettle();
        labels = semanticsLabels(tester.getSemantics(find.byType(FwAccordion)));
        expect(labels.join(' '), contains('Body A content'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('keyboard Enter toggles the focused header', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(items: items(), onOpenChanged: (ids) => reported = ids),
        ),
      );
      // Focus the first header button explicitly, then press Enter.
      final focus = tester.widget<Focus>(
        find
            .descendant(
              of: find.byType(FwAccordion),
              matching: find.byType(Focus),
            )
            .first,
      );
      focus.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(reported, {'a'});
    });

    testWidgets('keepAlive retains body state across close', (tester) async {
      await tester.pumpWidget(
        host(
          const FwAccordion(
            openIds: {'a'},
            items: [
              FwAccordionItem(
                id: 'a',
                header: Text('Panel A'),
                body: TextField(key: ValueKey('field')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('field')), 'hello');
      // Close (parent applies empty set), then reopen.
      await tester.pumpWidget(
        host(
          const FwAccordion(
            items: [
              FwAccordionItem(
                id: 'a',
                header: Text('Panel A'),
                body: TextField(key: ValueKey('field')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        host(
          const FwAccordion(
            openIds: {'a'},
            items: [
              FwAccordionItem(
                id: 'a',
                header: Text('Panel A'),
                body: TextField(key: ValueKey('field')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('field')))
            .controller,
        isNull,
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('focus leaves the body when its panel closes', (tester) async {
      final bodyFocus = FocusNode();
      Set<String> open = {'a'};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              return FwAccordion(
                openIds: open,
                onOpenChanged: (ids) => setState(() => open = ids),
                items: [
                  FwAccordionItem(
                    id: 'a',
                    header: const Text('Panel A'),
                    body: TextField(focusNode: bodyFocus),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(bodyFocus.hasFocus, isTrue);
      // Tap the header to close; the accordion moves focus to the header.
      await tester.tap(find.text('Panel A'));
      await tester.pumpAndSettle();
      expect(bodyFocus.hasFocus, isFalse);
      bodyFocus.dispose();
    });
  });

  // D04/D05/D07 groups.
  group('D04 FwDataTable', () {
    testWidgets('renders headers and cells', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Grace'), findsOneWidget);
    });

    testWidgets('sortable header tap reports the column id', (tester) async {
      String? sorted;
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
            onSort: (id) => sorted = id,
          ),
        ),
      );
      await tester.tap(find.text('Name'));
      expect(sorted, 'name');
      // Non-sortable header is not a button.
      await tester.tap(find.text('Role'));
      expect(sorted, 'name');
    });

    testWidgets('sort direction is announced', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwDataTable<_User>(
              columns: _userColumns(),
              rows: _users,
              getRowId: (u) => u.id,
              sortColumnId: 'name',
              sortAscending: false,
              onSort: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final labels = semanticsLabels(
          tester.getSemantics(find.byType(FwDataTable<_User>)),
        );
        expect(labels.join(' '), contains('Name, sorted descending'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('row selection reports the id set', (tester) async {
      Set<String>? selected;
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
            selectable: true,
            onSelectionChanged: (ids) => selected = ids,
          ),
        ),
      );
      // Two row checkboxes + one header checkbox.
      expect(find.byType(Checkbox), findsNWidgets(3));
      await tester.tap(find.byType(Checkbox).at(1));
      expect(selected, {'u1'});
    });

    testWidgets('header checkbox selects all', (tester) async {
      Set<String>? selected;
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
            selectable: true,
            onSelectionChanged: (ids) => selected = ids,
          ),
        ),
      );
      await tester.tap(find.byType(Checkbox).first);
      expect(selected, {'u1', 'u2'});
    });

    testWidgets('row actions render and invoke per row', (tester) async {
      _User? acted;
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
            rowActions: (u) => [
              FwDataRowAction<_User>(
                id: 'edit',
                label: 'Edit ${u.name}',
                icon: Icons.edit,
                onInvoked: (row) => acted = row,
              ),
            ],
          ),
        ),
      );
      expect(find.byTooltip('Edit Ada'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit Grace'));
      expect(acted?.id, 'u2');
    });

    testWidgets('empty, loading, and error states', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: const [],
            getRowId: (u) => u.id,
            emptyLabel: 'Nothing here',
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);

      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: const [],
            getRowId: (u) => u.id,
            isLoading: true,
            loadingLabel: 'Fetching users…',
          ),
        ),
      );
      expect(find.text('Fetching users…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      var retried = false;
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: const [],
            getRowId: (u) => u.id,
            error: 'Could not load users.',
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text('Could not load users.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('D05 responsive data list', () {
    Widget table({required double width}) => MaterialApp(
      theme: FwTheme.light().toThemeData(),
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
            compactBuilder: (context, scope) => Card(
              child: ListTile(
                title: Text(scope.row.name),
                subtitle: Text(scope.row.role),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('phone width renders cards, not the table', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      try {
        await tester.pumpWidget(table(width: 320));
        await tester.pumpAndSettle();
        // Cards render…
        expect(find.byType(Card), findsNWidgets(2));
        // …and the native Table does not.
        expect(find.byType(Table), findsNothing);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });

    testWidgets('wide width renders the table', (tester) async {
      await tester.pumpWidget(table(width: 900));
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('no compact builder falls back to horizontal scroll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: FwTheme.light().toThemeData(),
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: FwDataTable<_User>(
                  columns: _userColumns(),
                  rows: _users,
                  getRowId: (u) => u.id,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Table), findsOneWidget);
        final scroller = tester.widget<SingleChildScrollView>(
          find
              .descendant(
                of: find.byType(FwDataTable<_User>),
                matching: find.byType(SingleChildScrollView),
              )
              .first,
        );
        expect(scroller.scrollDirection, Axis.horizontal);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });

    testWidgets('pageSize slices rows with a range label', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: const [
              _User('u1', 'Ada', 'Engineer'),
              _User('u2', 'Grace', 'Admiral'),
              _User('u3', 'Hopper', 'Admiral'),
            ],
            getRowId: (u) => u.id,
            pageSize: 2,
          ),
        ),
      );
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Grace'), findsOneWidget);
      expect(find.text('Hopper'), findsNothing);
      expect(find.text('1–2 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Next page'));
      await tester.pump();
      expect(find.text('Ada'), findsNothing);
      expect(find.text('Hopper'), findsOneWidget);
      expect(find.text('3–3 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous page'));
      await tester.pump();
      expect(find.text('Ada'), findsOneWidget);
    });

    testWidgets('filter narrows rows; empty filter shows emptyLabel', (
      tester,
    ) async {
      bool matches(_User u, String q) =>
          u.name.toLowerCase().contains(q.toLowerCase());
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
            filter: 'gr',
            filterTest: matches,
          ),
        ),
      );
      expect(find.text('Ada'), findsNothing);
      expect(find.text('Grace'), findsOneWidget);

      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _userColumns(),
            rows: _users,
            getRowId: (u) => u.id,
            filter: 'zzz',
            filterTest: matches,
            emptyLabel: 'Nobody here.',
          ),
        ),
      );
      expect(find.text('Nobody here.'), findsOneWidget);
    });
  });

  group('D07 FwTimeline', () {
    List<FwTimelineEvent> events() => const [
      FwTimelineEvent(
        title: 'Order placed',
        time: '09:41',
        intent: FwIntent.success,
        statusLabel: 'Completed',
      ),
      FwTimelineEvent(
        title: 'Shipped',
        time: '14:02',
        description: 'Left the warehouse.',
        intent: FwIntent.info,
        statusLabel: 'In progress',
      ),
      FwTimelineEvent(title: 'Delivered', time: '—'),
    ];

    testWidgets('renders events in order', (tester) async {
      await tester.pumpWidget(host(FwTimeline(events: events())));
      expect(find.text('Order placed'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('09:41'), findsOneWidget);
      expect(find.text('Left the warehouse.'), findsOneWidget);
    });

    testWidgets('decorative line excluded; status announced', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(FwTimeline(events: events())));
        await tester.pumpAndSettle();
        final labels = semanticsLabels(
          tester.getSemantics(find.byType(FwTimeline)),
        );
        final joined = labels.join(' | ');
        expect(joined, contains('Completed'));
        expect(joined, contains('In progress'));
        // Titles and times are all present exactly once.
        expect('Order placed'.allMatches(joined).length, 1);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('D10 FwSwipeable', () {
    List<FwSwipeAction> trailing({VoidCallback? onDelete}) => [
      FwSwipeAction(
        label: 'Delete',
        icon: Icons.delete,
        intent: FwIntent.danger,
        onTap: onDelete ?? () {},
      ),
    ];

    Widget swipeable({VoidCallback? onDelete}) => FwSwipeable(
      trailingActions: trailing(onDelete: onDelete),
      child: const ListTile(title: Text('Item')),
    );

    testWidgets('drag reveals trailing actions', (tester) async {
      await tester.pumpWidget(host(swipeable()));
      // Actions hidden initially.
      expect(find.text('Delete'), findsNothing);
      await tester.drag(find.byType(FwSwipeable), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping an action invokes and closes', (tester) async {
      var deleted = false;
      await tester.pumpWidget(host(swipeable(onDelete: () => deleted = true)));
      await tester.drag(find.byType(FwSwipeable), const Offset(-200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('short drag snaps closed', (tester) async {
      await tester.pumpWidget(host(swipeable()));
      await tester.drag(find.byType(FwSwipeable), const Offset(-20, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('leading actions reveal on opposite drag', (tester) async {
      await tester.pumpWidget(
        host(
          FwSwipeable(
            leadingActions: const [
              FwSwipeAction(
                label: 'Archive',
                icon: Icons.archive,
                onTap: _noop,
              ),
            ],
            trailingActions: trailing(),
            child: const ListTile(title: Text('Item')),
          ),
        ),
      );
      await tester.drag(find.byType(FwSwipeable), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('open state is reported', (tester) async {
      bool? open;
      await tester.pumpWidget(
        host(
          FwSwipeable(
            trailingActions: trailing(),
            onOpenChanged: (v) => open = v,
            child: const ListTile(title: Text('Item')),
          ),
        ),
      );
      await tester.drag(find.byType(FwSwipeable), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(open, isTrue);
    });
  });

  group('D06 FwStat', () {
    testWidgets('renders value and label', (tester) async {
      await tester.pumpWidget(
        host(const FwStat(value: '\$12.4k', label: 'Revenue')),
      );
      expect(find.text('\$12.4k'), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
    });

    testWidgets('trend up with goodUp uses success color', (tester) async {
      await tester.pumpWidget(
        host(
          const FwStat(
            value: '\$12.4k',
            label: 'Revenue',
            trend: FwTrendDirection.up,
            trendLabel: '+12%',
            trendGoodness: FwTrendGoodness.goodUp,
            comparisonLabel: 'vs last month',
          ),
        ),
      );
      final theme = FwTheme.light();
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.icon, Icons.arrow_upward);
      expect(icon.color, theme.colors.of(FwColorRole.success));
      expect(find.text('+12%'), findsOneWidget);
      expect(find.text('vs last month'), findsOneWidget);
    });

    testWidgets('trend up with goodDown uses danger color', (tester) async {
      await tester.pumpWidget(
        host(
          const FwStat(
            value: '3.1%',
            label: 'Churn',
            trend: FwTrendDirection.up,
            trendLabel: '+0.4%',
            trendGoodness: FwTrendGoodness.goodDown,
          ),
        ),
      );
      final theme = FwTheme.light();
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.color, theme.colors.of(FwColorRole.error));
    });

    testWidgets('loading shows placeholder', (tester) async {
      await tester.pumpWidget(
        host(const FwStat(value: '\$12.4k', label: 'Revenue', isLoading: true)),
      );
      expect(find.text('\$12.4k'), findsNothing);
      expect(find.text('Revenue'), findsOneWidget);
    });

    testWidgets('announces composed label', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwStat(
              value: '\$12.4k',
              label: 'Revenue',
              trend: FwTrendDirection.up,
              trendLabel: '+12%',
              comparisonLabel: 'vs last month',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final labels = semanticsLabels(
          tester.getSemantics(find.byType(FwStat)),
        );
        expect(labels, hasLength(1));
        expect(labels.single, contains('\$12.4k, Revenue, +12% vs last month'));
      } finally {
        semantics.dispose();
      }
    });
  });
}

void _noop() {}
