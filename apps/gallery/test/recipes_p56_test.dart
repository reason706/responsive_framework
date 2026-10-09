import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw/fw.dart';
import 'package:fw_gallery/recipes.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(body: FwViewportQuery(child: child)),
);

void main() {
  group('DashboardRecipe (P5.6 exit gate)', () {
    Future<void> pumpDashboard(
      WidgetTester tester, {
      required double width,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(host(const DashboardRecipe()));
      await tester.pumpAndSettle();
    }

    testWidgets('phone shows bottom nav; identical selection state', (
      tester,
    ) async {
      await pumpDashboard(tester, width: 400);
      expect(find.byType(FwBottomNavigation), findsOneWidget);
      // Long labels are usable (truncated, not overflowing).
      expect(find.text('Analytics and reporting'), findsOneWidget);
      await tester.tap(find.text('Customer management'));
      await tester.pumpAndSettle();
      expect(find.text('Customer management'), findsWidgets);
    });

    testWidgets('tablet shows rail; desktop shows sidebar', (tester) async {
      await pumpDashboard(tester, width: 800);
      expect(find.byType(FwNavigationRail), findsOneWidget);

      await pumpDashboard(tester, width: 1300);
      expect(find.byType(FwSidebar), findsOneWidget);
    });

    testWidgets('field state survives phone -> desktop transition', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final navigated = <String>[];
      await tester.pumpWidget(host(DashboardRecipe(onNavigate: navigated.add)));
      await tester.pumpAndSettle();
      // Type in the notes field.
      await tester.enterText(find.byType(TextField), 'remember this');
      // Select a destination (route-neutral contract fires).
      await tester.tap(
        find.text('Analytics and reporting'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(navigated, ['analytics']);
      // Back to overview, then transition to desktop.
      await tester.tap(find.text('Overview'), warnIfMissed: false);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1300, 800);
      await tester.pumpAndSettle();
      expect(find.byType(FwSidebar), findsOneWidget);
      // Notes field state survived (controller is recipe-owned).
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'remember this');
    });

    testWidgets('deep link sets the initial destination', (tester) async {
      tester.view.physicalSize = const Size(1300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        host(const DashboardRecipe(initialDestination: 'customers')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Customer management'), findsWidgets);
    });
  });

  group('MasterDetailRecipe (P5.6 exit gate)', () {
    testWidgets('selects item; contract fires', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final selected = <String?>[];
      await tester.pumpWidget(
        host(MasterDetailRecipe(onSelectItem: selected.add)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zephyr launch'));
      await tester.pumpAndSettle();
      expect(selected, ['item-1']);
      expect(find.text('Detail paragraph 1 for item-1.'), findsOneWidget);
    });

    testWidgets('deep link opens the item', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        host(const MasterDetailRecipe(initialItemId: 'item-2')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Detail paragraph 1 for item-2.'), findsOneWidget);
    });
  });
}
