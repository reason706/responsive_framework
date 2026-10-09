import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw/fw.dart';

import '../lib/recipes.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: SingleChildScrollView(child: child)),
  ),
);

void main() {
  group('DataPageRecipe (Phase 6 exit gate)', () {
    // Default sort is name ascending; page 1 holds:
    // Apparatus, Contraption, Doohickey, Gizmo, Implement.
    testWidgets('search filters the table', (tester) async {
      await tester.pumpWidget(host(const DataPageRecipe()));
      await tester.pumpAndSettle();
      expect(find.text('Acme Apparatus'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'gizmo');
      await tester.pumpAndSettle();
      expect(find.text('Acme Gizmo'), findsOneWidget);
      expect(find.text('Acme Thingamajig'), findsOneWidget);
      expect(find.text('Acme Apparatus'), findsNothing);
    });

    testWidgets('sort header reorders rows', (tester) async {
      await tester.pumpWidget(host(const DataPageRecipe()));
      await tester.pumpAndSettle();
      // Sort by price: first tap ascending, second descending.
      await tester.tap(find.text('Price'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price'));
      await tester.pumpAndSettle();
      // Highest price first on page 1: Thingamajig $99.99.
      expect(find.text('Acme Thingamajig'), findsOneWidget);
      expect(find.text('Acme Doohickey'), findsNothing);
    });

    testWidgets('pagination changes the page', (tester) async {
      await tester.pumpWidget(host(const DataPageRecipe()));
      await tester.pumpAndSettle();
      expect(find.text('Acme Apparatus'), findsOneWidget);
      // Go to page 2 (Thingamajig, Utensil, Widget).
      await tester.ensureVisible(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('Acme Widget'), findsOneWidget);
      expect(find.text('Acme Apparatus'), findsNothing);
    });

    testWidgets('delete removes the product after confirm', (tester) async {
      await tester.pumpWidget(host(const DataPageRecipe()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete Acme Apparatus'));
      await tester.pumpAndSettle();
      // Confirm dialog appears.
      expect(find.text('Delete Acme Apparatus?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Acme Apparatus'), findsNothing);
      // Stats reflect the removal.
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('phone width shows cards with all essential fields', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      try {
        await tester.pumpWidget(host(const DataPageRecipe()));
        await tester.pumpAndSettle();
        // Cards, not the table.
        expect(find.byType(Card), findsWidgets);
        expect(find.byType(Table), findsNothing);
        // Essential fields present in the first card.
        expect(find.text('Acme Apparatus'), findsOneWidget);
        expect(find.textContaining('Contraptions'), findsWidgets);
        expect(find.textContaining('\$79.99'), findsOneWidget);
        expect(find.textContaining('Stock: 45'), findsOneWidget);
        expect(find.text('New arrival'), findsOneWidget);
        // Row action available.
        expect(find.byTooltip('Delete Acme Apparatus'), findsOneWidget);
        // Selection available.
        expect(find.byType(Checkbox), findsWidgets);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });

    testWidgets('large text does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      try {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: host(const DataPageRecipe()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  });
}
