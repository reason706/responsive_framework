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

/// Pumps [child] under an explicit text direction.
Widget directedHost(Widget child, TextDirection direction, {FwTheme? theme}) =>
    MaterialApp(
      theme: (theme ?? FwTheme.light()).toThemeData(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Directionality(textDirection: direction, child: child),
        ),
      ),
    );

void main() {
  group('P2.1 FwGap', () {
    testWidgets('vertical gap inserts the token height', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              FwGap(FwSpace.s4),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      // s4 = 1rem = 16 at root 16, comfortable density (scale 1.0).
      expect(b.top - a.bottom, 16);
    });

    testWidgets('horizontal gap inserts the token width', (tester) async {
      await tester.pumpWidget(
        host(
          const Row(
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              FwGap(FwSpace.s2, axis: Axis.horizontal),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      // s2 = 0.5rem = 8 at root 16.
      expect(b.left - a.right, 8);
    });

    testWidgets('named constructors set the axis', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              FwGap.horizontal(FwSpace.s4),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
        ),
      );
      final gap = tester.getSize(find.byType(FwGap));
      expect(gap.width, 16);
      expect(gap.height, 0);
    });

    testWidgets('default axis is vertical', (tester) async {
      const gap = FwGap(FwSpace.s4);
      expect(gap.axis, Axis.vertical);
      expect(const FwGap.vertical(FwSpace.s4).axis, Axis.vertical);
    });

    testWidgets('zero token collapses', (tester) async {
      await tester.pumpWidget(host(const FwGap(FwSpace.s0)));
      expect(tester.getSize(find.byType(FwGap)), Size.zero);
    });

    testWidgets('compact density shrinks the gap', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              FwGap(FwSpace.s4),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
          theme: FwTheme.light(density: FwDensity.compact),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      // 16 * 0.875 = 14.
      expect(b.top - a.bottom, 14);
    });

    testWidgets('spacious density grows the gap', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              FwGap(FwSpace.s4),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
          theme: FwTheme.light(density: FwDensity.spacious),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      // 16 * 1.25 = 20.
      expect(b.top - a.bottom, 20);
    });

    testWidgets('gap is RTL-neutral', (tester) async {
      Future<Rect> gapRect(TextDirection direction) async {
        await tester.pumpWidget(
          directedHost(
            const Row(
              children: [
                SizedBox(key: ValueKey('a'), width: 50, height: 20),
                FwGap(FwSpace.s4, axis: Axis.horizontal),
                SizedBox(key: ValueKey('b'), width: 50, height: 20),
              ],
            ),
            direction,
          ),
        );
        return tester.getRect(find.byType(FwGap));
      }

      final ltr = await gapRect(TextDirection.ltr);
      final rtl = await gapRect(TextDirection.rtl);
      // A horizontal spacer occupies width only — like SizedBox(width:), it
      // contributes no height inside a Row. RTL changes nothing.
      expect(ltr.size, const Size(16, 0));
      expect(rtl.size, const Size(16, 0));
    });

    testWidgets('hero token resolves', (tester) async {
      await tester.pumpWidget(host(const FwGap(FwSpace.s32)));
      // s32 = 128px at root 16.
      expect(tester.getSize(find.byType(FwGap)).height, 128);
    });
  });

  group('P2.2 FwBox', () {
    testWidgets('uniform padding insets the child on all sides', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwBox(
            padding: FwSpace.s4,
            child: SizedBox(key: ValueKey('c'), width: 10, height: 10),
          ),
        ),
      );
      final c = tester.getRect(find.byKey(const ValueKey('c')));
      expect(c.left, 16);
      expect(c.top, 16);
      final box = tester.getRect(find.byType(FwBox));
      expect(box.size, const Size(42, 42));
    });

    testWidgets('paddingInline maps to start/end in LTR', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBox(
            paddingInline: FwSpace.s4,
            child: SizedBox(key: ValueKey('c'), width: 10, height: 10),
          ),
        ),
      );
      final c = tester.getRect(find.byKey(const ValueKey('c')));
      expect(c.left, 16);
      expect(c.top, 0);
      expect(tester.getRect(find.byType(FwBox)).size, const Size(42, 10));
    });

    testWidgets('paddingBlock maps to top/bottom', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBox(
            paddingBlock: FwSpace.s2,
            child: SizedBox(key: ValueKey('c'), width: 10, height: 10),
          ),
        ),
      );
      final c = tester.getRect(find.byKey(const ValueKey('c')));
      expect(c.left, 0);
      expect(c.top, 8);
    });

    testWidgets('paddingInlineStart lands on the right in RTL', (tester) async {
      await tester.pumpWidget(
        directedHost(
          const FwBox(
            paddingInlineStart: FwSpace.s4,
            child: SizedBox(key: ValueKey('c'), width: 10, height: 10),
          ),
          TextDirection.rtl,
        ),
      );
      final box = tester.getRect(find.byType(FwBox));
      final c = tester.getRect(find.byKey(const ValueKey('c')));
      // Start inset is on the right in RTL: child hugs the left edge.
      expect(c.left, 0);
      expect(box.right - c.right, 16);
    });

    testWidgets('most specific prop wins', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBox(
            padding: FwSpace.s4,
            paddingInline: FwSpace.s2,
            paddingInlineStart: FwSpace.s1,
            paddingBlock: FwSpace.s6,
            paddingBlockEnd: FwSpace.s3,
            child: SizedBox(key: ValueKey('c'), width: 10, height: 10),
          ),
        ),
      );
      final box = tester.getRect(find.byType(FwBox));
      final c = tester.getRect(find.byKey(const ValueKey('c')));
      // start: s1=4 (beats inline s2=8, beats padding s4=16).
      expect(c.left, 4);
      // end: s2=8.
      expect(box.right - c.right, 8);
      // top: s6=24.
      expect(c.top, 24);
      // bottom: s3=12 (beats block s6=24).
      expect(box.bottom - c.bottom, 12);
    });

    testWidgets('no padding leaves the child at the origin', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBox(
            child: SizedBox(key: ValueKey('c'), width: 10, height: 10),
          ),
        ),
      );
      final c = tester.getRect(find.byKey(const ValueKey('c')));
      expect(c.topLeft, Offset.zero);
    });

    testWidgets('compact density shrinks padding', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBox(
            padding: FwSpace.s4,
            child: SizedBox(key: ValueKey('c'), width: 10, height: 10),
          ),
          theme: FwTheme.light(density: FwDensity.compact),
        ),
      );
      final c = tester.getRect(find.byKey(const ValueKey('c')));
      // 16 * 0.875 = 14.
      expect(c.left, 14);
      expect(c.top, 14);
    });
  });

  group('P2.4 FwInline', () {
    testWidgets('lays out children with the token gap', (tester) async {
      await tester.pumpWidget(
        host(
          const FwInline(
            gap: FwSpace.s2,
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
        ),
      );
      final a = tester.getTopLeft(find.byKey(const ValueKey('a')));
      final b = tester.getTopLeft(find.byKey(const ValueKey('b')));
      expect(a.dy, b.dy);
      expect(b.dx - (a.dx + 50), 8);
    });

    testWidgets('wraps with the row gap', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 120,
            child: FwInline(
              gap: FwSpace.s2,
              rowGap: FwSpace.s4,
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
      expect(a.dy, b.dy);
      expect(c.dy, greaterThan(a.dy));
      // run gap s4 = 16 between the runs.
      expect(c.dy - (a.dy + 20), 16);
    });

    testWidgets('mirrors inline order in RTL', (tester) async {
      Future<Offset> firstChildTopLeft(TextDirection direction) async {
        await tester.pumpWidget(
          directedHost(
            const SizedBox(
              width: 400,
              child: FwInline(
                children: [
                  SizedBox(key: ValueKey('a'), width: 50, height: 20),
                  SizedBox(key: ValueKey('b'), width: 50, height: 20),
                ],
              ),
            ),
            direction,
          ),
        );
        return tester.getTopLeft(find.byKey(const ValueKey('a')));
      }

      final ltr = await firstChildTopLeft(TextDirection.ltr);
      final rtl = await firstChildTopLeft(TextDirection.rtl);
      expect(ltr.dx, 0);
      // In RTL the first child starts from the right edge.
      expect(rtl.dx, 400 - 50);
    });

    testWidgets('compact density shrinks gaps', (tester) async {
      await tester.pumpWidget(
        host(
          const FwInline(
            gap: FwSpace.s4,
            children: [
              SizedBox(key: ValueKey('a'), width: 50, height: 20),
              SizedBox(key: ValueKey('b'), width: 50, height: 20),
            ],
          ),
          theme: FwTheme.light(density: FwDensity.compact),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      expect(b.left - a.right, 14);
    });

    testWidgets('respects row alignment', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: FwInline(
              alignment: WrapAlignment.center,
              children: [SizedBox(key: ValueKey('a'), width: 50, height: 20)],
            ),
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      // (200 - 50) / 2 = 75.
      expect(a.left, 75);
    });
  });
}
