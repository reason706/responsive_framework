import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_pilot/main.dart';

void main() {
  testWidgets('marketing pilot builds all sections', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(const MarketingPilotApp());
    await tester.pumpAndSettle();

    expect(find.text('Ship beautiful apps faster'), findsOneWidget);
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    // FAQ accordion expands.
    await tester.ensureVisible(find.text('Is it really free for starters?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Is it really free for starters?'));
    await tester.pumpAndSettle();
    expect(find.text('Yes — the Starter tier is free forever.'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
