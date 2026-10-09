import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';
import 'package:fw_layout/fw_layout.dart';

/// Wave 0, M0.2: grid/breakpoint tokens and the responsive layout scaffold.
void main() {
  test('viewport classes split at 600 and 1240', () {
    expect(FwGrid.classOf(599), FwViewportClass.compact);
    expect(FwGrid.classOf(600), FwViewportClass.medium);
    expect(FwGrid.classOf(1239), FwViewportClass.medium);
    expect(FwGrid.classOf(1240), FwViewportClass.expanded);
  });

  test('column counts follow the 4/8/12 convention', () {
    expect(FwGrid.specFor(FwViewportClass.compact).columns, 4);
    expect(FwGrid.specFor(FwViewportClass.medium).columns, 8);
    expect(FwGrid.specFor(FwViewportClass.expanded).columns, 12);
  });

  testWidgets('grid spec resolves against the viewport width', (tester) async {
    FwGridSpec? spec;
    Future<void> pumpAt(double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                spec = const FwGrid().of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    }

    await pumpAt(400);
    expect(spec!.columns, 4);
    await pumpAt(800);
    expect(spec!.columns, 8);
    await pumpAt(1400);
    expect(spec!.columns, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('responsive layout applies grid margins and centers content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const childKey = ValueKey('content');
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light().toThemeData(),
        home: const Scaffold(
          body: FwResponsiveLayout(
            maxWidth: 800,
            child: SizedBox(key: childKey, width: 2000, height: 50),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byKey(childKey));
    // Expanded margins are 2rem = 32px at root 16; the 800px content is
    // centered in the remaining 1400 - 64 = 1336px.
    expect(rect.left, closeTo(32 + (1336 - 800) / 2, 0.5));
    expect(rect.width, 800);
    expect(find.byType(SafeArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact layout uses 1rem margins', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const childKey = ValueKey('content');
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light().toThemeData(),
        home: const Scaffold(
          body: FwResponsiveLayout(
            child: SizedBox(key: childKey, width: 2000, height: 50),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byKey(childKey));
    expect(rect.left, closeTo(16, 0.5));
    expect(rect.right, closeTo(400 - 16, 0.5));
    expect(tester.takeException(), isNull);
  });
}
