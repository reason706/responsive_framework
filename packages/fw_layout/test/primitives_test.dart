import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';
import 'package:fw_layout/fw_layout.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

void main() {
  group('L03 stacks', () {
    testWidgets('hstack separates children by the token gap', (tester) async {
      await tester.pumpWidget(
        host(
          const FwHStack(
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      // s4 = 1rem = 16 at root 16.
      expect(b.left - a.right, 16);
      expect(a.top, b.top);
    });

    testWidgets('vstack separates children vertically', (tester) async {
      await tester.pumpWidget(
        host(
          const FwVStack(
            gap: FwSpace.s2,
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      expect(b.top - a.bottom, 8);
      expect(a.left, b.left);
    });

    testWidgets('adaptive stack switches orientation at the breakpoint', (
      tester,
    ) async {
      Future<({double dx, double dy})> offsets(double width) async {
        await tester.pumpWidget(
          host(
            SizedBox(
              width: width,
              child: const FwAdaptiveStack(
                children: [
                  SizedBox(key: ValueKey('a'), width: 50, height: 20),
                  SizedBox(key: ValueKey('b'), width: 50, height: 20),
                ],
              ),
            ),
          ),
        );
        final a = tester.getTopLeft(find.byKey(const ValueKey('a')));
        final b = tester.getTopLeft(find.byKey(const ValueKey('b')));
        return (dx: b.dx - a.dx, dy: b.dy - a.dy);
      }

      // md threshold is 768: horizontal at/above, vertical below.
      final wide = await offsets(800);
      expect(wide.dy, 0);
      expect(wide.dx, greaterThan(0));
      final narrow = await offsets(600);
      expect(narrow.dx, 0);
      expect(narrow.dy, greaterThan(0));
    });
  });

  group('L04 wrap', () {
    testWidgets('wrap flows children to the next run', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 120,
            child: FwWrap(
              gap: FwSpace.s2,
              runGap: FwSpace.s2,
              children: [
                SizedBox(key: ValueKey('a'), width: 50, height: 20),
                SizedBox(key: ValueKey('b'), width: 50, height: 20),
                SizedBox(key: ValueKey('c'), width: 50, height: 20),
              ],
            ),
          ),
        ),
      );
      final a = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final b = tester.getTopLeft(find.byKey(const ValueKey('b')));
      final c = tester.getTopLeft(find.byKey(const ValueKey('c')));
      // a and b share the first run (50 + 8 + 50 = 108 <= 120).
      expect(a.dy, b.dy);
      // c wraps to the second run with the run gap.
      expect(c.dy, greaterThan(a.dy));
      expect(c.dy - (a.dy + 20), 8);
    });
  });

  group('L05 auto grid', () {
    test('columnsFor computes from width and gap', () {
      int cols(double width, {int? max}) => FwAutoGrid.columnsFor(
        width: width,
        minItemWidth: 200,
        gapPx: 16,
        maxColumns: max,
      );
      expect(cols(500), 2); // (500 + 16) / 216 = 2.38 -> 2
      expect(cols(100), 1); // never zero columns
      expect(cols(1000), 4); // (1016) / 216 = 4.7 -> 4
      expect(cols(1000, max: 3), 3);
    });

    testWidgets('grid lays out the computed columns', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 500,
            height: 400,
            child: FwAutoGrid(
              minItemWidth: 200,
              gap: FwSpace.s4,
              children: [
                SizedBox(key: ValueKey('i0'), height: 40),
                SizedBox(key: ValueKey('i1'), height: 40),
                SizedBox(key: ValueKey('i2'), height: 40),
              ],
            ),
          ),
        ),
      );
      final first = tester.getTopLeft(find.byKey(const ValueKey('i0')));
      final second = tester.getTopLeft(find.byKey(const ValueKey('i1')));
      final third = tester.getTopLeft(find.byKey(const ValueKey('i2')));
      // Two columns: i0/i1 share a row, i2 wraps below.
      expect(first.dy, second.dy);
      expect(third.dy, greaterThan(first.dy));
    });

    testWidgets('keyed children keep state across resizes', (tester) async {
      var taps = 0;
      Widget build(double width) => host(
        SizedBox(
          width: width,
          height: 400,
          child: FwAutoGrid(
            minItemWidth: 200,
            children: [
              SizedBox(
                key: const ValueKey('counter'),
                height: 40,
                child: StatefulBuilder(
                  builder: (context, setState) => GestureDetector(
                    onTap: () {
                      taps++;
                      setState(() {});
                    },
                    child: Text('taps: $taps'),
                  ),
                ),
              ),
              const SizedBox(key: ValueKey('other'), height: 40),
            ],
          ),
        ),
      );
      await tester.pumpWidget(build(500));
      await tester.tap(find.text('taps: 0'));
      await tester.pump();
      expect(find.text('taps: 1'), findsOneWidget);
      // Resize re-computes columns; the keyed child keeps its state.
      await tester.pumpWidget(build(900));
      await tester.pump();
      expect(find.text('taps: 1'), findsOneWidget);
    });
  });

  group('L06 show and responsive builder', () {
    testWidgets('remove mode unmounts below the threshold', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 600,
            child: FwShow(below: FwBreakpoint.md, child: Text('narrow only')),
          ),
        ),
      );
      expect(find.text('narrow only'), findsOneWidget);
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 800,
            child: FwShow(below: FwBreakpoint.md, child: Text('narrow only')),
          ),
        ),
      );
      expect(find.text('narrow only'), findsNothing);
    });

    testWidgets('retain mode keeps state but hides from focus/semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const SizedBox(
              width: 800,
              child: FwShow(
                below: FwBreakpoint.md,
                mode: FwVisibilityMode.retain,
                child: Text('kept'),
              ),
            ),
          ),
        );
        // Still mounted...
        expect(find.text('kept', skipOffstage: false), findsOneWidget);
        // ...but not visible and not in semantics.
        expect(tester.getSize(find.byType(FwShow)).height, 0);
        expect(
          find.bySemanticsLabel('kept', skipOffstage: false),
          findsNothing,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('responsive builder receives width and breakpoint', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late double seenWidth;
      late FwBreakpoint seenBreakpoint;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 1000,
            child: FwResponsiveBuilder(
              builder: (context, width, breakpoint) {
                seenWidth = width;
                seenBreakpoint = breakpoint;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(seenWidth, 1000);
      expect(seenBreakpoint, FwBreakpoint.lg);
    });
  });

  group('L07 aspect and limits', () {
    test('non-positive ratios are rejected', () {
      expect(
        () => FwAspectRatio(aspectRatio: 0, child: const SizedBox()),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => FwAspectRatio(aspectRatio: -1, child: const SizedBox()),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('limits apply root-relative bounds', (tester) async {
      await tester.pumpWidget(
        host(
          FwLimits(
            maxWidth: FwRem(40), // 640 at root 16
            child: Container(
              key: const ValueKey('box'),
              width: double.infinity,
              height: 20,
              color: const Color(0xFFFF0000),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('box'))).width, 640);
    });
  });

  group('P3.2 density-scaled gaps', () {
    // s4 = 16 at root 16; compact scales by 0.875, spacious by 1.25.
    Future<double> hstackGap(WidgetTester tester, FwDensity density) async {
      await tester.pumpWidget(
        host(
          FwDensityScope(
            density: density,
            child: const FwHStack(
              children: [
                SizedBox(key: ValueKey('a'), width: 50, height: 20),
                SizedBox(key: ValueKey('b'), width: 50, height: 20),
              ],
            ),
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      return b.left - a.right;
    }

    testWidgets('hstack gap compacts and expands with density', (tester) async {
      expect(await hstackGap(tester, FwDensity.comfortable), 16);
      expect(await hstackGap(tester, FwDensity.compact), 14); // 16 * 0.875
      expect(await hstackGap(tester, FwDensity.spacious), 20); // 16 * 1.25
    });

    testWidgets('vstack gap compacts with density', (tester) async {
      await tester.pumpWidget(
        host(
          FwDensityScope(
            density: FwDensity.compact,
            child: const FwVStack(
              gap: FwSpace.s2,
              children: [
                SizedBox(key: ValueKey('a'), width: 50, height: 20),
                SizedBox(key: ValueKey('b'), width: 50, height: 20),
              ],
            ),
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      expect(b.top - a.bottom, 7); // 8 * 0.875
    });
  });
}
