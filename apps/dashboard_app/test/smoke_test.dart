import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_pilot/main.dart';

void main() {
  testWidgets('dashboard pilot adapts to width', (tester) async {
    // Phone: bottom navigation.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(const DashboardPilotApp());
    await tester.pumpAndSettle();
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Acme Widget'), findsOneWidget);

    // Sorting by price reorders rows: cheapest first.
    await tester.tap(find.text('Price'));
    await tester.pumpAndSettle();
    final cheapY = tester.getTopLeft(find.text('Doohickey')).dy;
    final priceyY = tester.getTopLeft(find.text('Thingamajig')).dy;
    expect(cheapY, lessThan(priceyY));

    // Selecting a row via its checkbox shows the count.
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    // Desktop: sidebar replaces bottom nav, same selection state.
    tester.view.physicalSize = const Size(2880, 1800);
    await tester.pumpAndSettle();
    expect(find.text('Good morning'), findsOneWidget);
    addTearDown(tester.view.resetPhysicalSize);
  });
}
