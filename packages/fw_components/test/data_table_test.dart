import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

class _User {
  const _User(this.name, this.age);
  final String name;
  final int age;
}

const _users = [_User('Amara', 34), _User('Boris', 28), _User('Chloe', 41)];

List<FwDataColumn<_User>> _columns() => [
  FwDataColumn<_User>(
    label: 'Name',
    sortable: true,
    sortValue: (u) => u.name,
    value: (u) => u.name,
  ),
  FwDataColumn<_User>(
    label: 'Age',
    sortable: true,
    numeric: true,
    sortValue: (u) => u.age,
    value: (u) => u.age,
  ),
];

/// Names in visual row order.
List<String> _rowOrder(WidgetTester tester) {
  const names = {'Amara', 'Boris', 'Chloe'};
  return tester
      .widgetList<Text>(
        find.byWidgetPredicate((w) => w is Text && names.contains(w.data)),
      )
      .map((t) => t.data!)
      .toList();
}

void main() {
  group('E4a data table sorting', () {
    testWidgets('tapping a header sorts ascending then descending', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FwDataTable<_User>(columns: _columns(), rows: _users)),
      );
      expect(_rowOrder(tester), ['Amara', 'Boris', 'Chloe']);

      // Sort by age ascending: Boris(28), Amara(34), Chloe(41).
      await tester.tap(find.text('Age'));
      await tester.pump();
      expect(_rowOrder(tester), ['Boris', 'Amara', 'Chloe']);

      // Again: descending.
      await tester.tap(find.text('Age'));
      await tester.pump();
      expect(_rowOrder(tester), ['Chloe', 'Amara', 'Boris']);
    });

    testWidgets('unsortable header does not sort', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: [FwDataColumn<_User>(label: 'Name', value: (u) => u.name)],
            rows: _users,
          ),
        ),
      );
      await tester.tap(find.text('Name'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_rowOrder(tester), ['Amara', 'Boris', 'Chloe']);
    });
  });

  group('E4a data table selection', () {
    testWidgets('row checkboxes report the selected rows', (tester) async {
      var selected = <_User>{};
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _columns(),
            rows: _users,
            selectable: true,
            onSelectionChanged: (s) => selected = s,
          ),
        ),
      );
      final boxes = find.byType(Checkbox);
      // First checkbox is select-all; tap the first row's box.
      await tester.tap(boxes.at(1));
      await tester.pump();
      expect(selected.map((u) => u.name), {'Amara'});
    });

    testWidgets('select-all covers the page', (tester) async {
      var selected = <_User>{};
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _columns(),
            rows: _users,
            selectable: true,
            onSelectionChanged: (s) => selected = s,
          ),
        ),
      );
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(selected.length, 3);
    });
  });

  group('E4a data table pagination', () {
    testWidgets('pages slice the rows with a range label', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(columns: _columns(), rows: _users, pageSize: 2),
        ),
      );
      expect(_rowOrder(tester), ['Amara', 'Boris']);
      expect(find.text('1–2 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Next page'));
      await tester.pump();
      expect(_rowOrder(tester), ['Chloe']);
      expect(find.text('3–3 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous page'));
      await tester.pump();
      expect(_rowOrder(tester), ['Amara', 'Boris']);
    });
  });

  group('E4a data table expandable rows', () {
    testWidgets('expanding a row reveals its detail', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _columns(),
            rows: _users,
            expandBuilder: (u) => Text('Detail for ${u.name}'),
          ),
        ),
      );
      expect(find.text('Detail for Amara'), findsNothing);
      await tester.tap(find.byTooltip('Expand row').first);
      await tester.pump();
      expect(find.text('Detail for Amara'), findsOneWidget);
    });
  });

  group('E4a data table filtering', () {
    testWidgets('filter narrows the rows', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _columns(),
            rows: _users,
            filter: 'bo',
            filterTest: (u, q) =>
                u.name.toLowerCase().contains(q.toLowerCase()),
          ),
        ),
      );
      expect(_rowOrder(tester), ['Boris']);
    });

    testWidgets('empty view shows the empty label', (tester) async {
      await tester.pumpWidget(
        host(
          FwDataTable<_User>(
            columns: _columns(),
            rows: _users,
            filter: 'zzz',
            filterTest: (u, q) =>
                u.name.toLowerCase().contains(q.toLowerCase()),
            emptyLabel: 'Nobody here.',
          ),
        ),
      );
      expect(find.text('Nobody here.'), findsOneWidget);
    });
  });
}
