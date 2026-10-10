import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

const testItems = [
  FwDescriptionItem(term: 'Name', description: Text('Ada Lovelace')),
  FwDescriptionItem(term: 'Role', description: Text('Mathematician')),
  FwDescriptionItem(
    term: 'Location',
    description: Text('London'),
    icon: Icons.place,
  ),
];

void main() {
  group('FwDescriptionList', () {
    testWidgets('renders every term and description', (tester) async {
      await tester.pumpWidget(host(const FwDescriptionList(items: testItems)));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Mathematician'), findsOneWidget);
    });

    testWidgets('renders term icons', (tester) async {
      await tester.pumpWidget(host(const FwDescriptionList(items: testItems)));
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('horizontal layout places term and description in a row', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FwDescriptionList(items: testItems)));
      final row = tester.widget<Row>(
        find
            .descendant(
              of: find.byType(FwDescriptionList),
              matching: find.byType(Row),
            )
            .first,
      );
      expect(row.children.length, 3); // term, gap, description
    });

    testWidgets('stacked layout renders term above description', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwDescriptionList(
            items: testItems,
            layout: FwDescriptionListLayout.stacked,
          ),
        ),
      );
      final termY = tester.getTopLeft(find.text('Name')).dy;
      final descY = tester.getTopLeft(find.text('Ada Lovelace')).dy;
      expect(descY, greaterThan(termY));
    });

    testWidgets('divided shows dividers between rows', (tester) async {
      await tester.pumpWidget(
        host(const FwDescriptionList(items: testItems, divided: true)),
      );
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('no dividers by default', (tester) async {
      await tester.pumpWidget(host(const FwDescriptionList(items: testItems)));
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('description accepts any widget', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(
          FwDescriptionList(
            items: [
              FwDescriptionItem(
                term: 'Link',
                description: TextButton(
                  onPressed: () => tapped = true,
                  child: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      expect(tapped, isTrue);
    });

    testWidgets('rowGap override is accepted', (tester) async {
      await tester.pumpWidget(
        host(const FwDescriptionList(items: testItems, rowGap: FwSpace.s4)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('compacts under a compact density scope', (tester) async {
      await tester.pumpWidget(
        host(
          const FwDensityScope(
            density: FwDensity.compact,
            child: FwDescriptionList(items: testItems),
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('term flex values are honored', (tester) async {
      await tester.pumpWidget(
        host(
          const FwDescriptionList(
            items: testItems,
            termFlex: 1,
            descriptionFlex: 4,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Name'), findsOneWidget);
    });
  });
}
