import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

Future<void> pumpWithTheme(
  WidgetTester tester,
  WidgetBuilder builder, {
  FwTheme? theme,
  MediaQueryData media = const MediaQueryData(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: (theme ?? FwTheme.light()).toThemeData(),
      home: MediaQuery(
        data: media,
        child: Scaffold(body: Builder(builder: builder)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('FwBorders', () {
    testWidgets('hairlines stay pixel-based when the root grows', (
      tester,
    ) async {
      late double hairline;
      late double medium;
      await pumpWithTheme(
        tester,
        (context) {
          final borders = context.fwTheme.borders;
          hairline = borders.resolveHairline(context);
          medium = borders.resolveMedium(context);
          return const SizedBox();
        },
        theme: FwTheme.light().copyWith(metrics: const FwMetrics(rootSize: 20)),
      );
      // A 1px divider does not become thick just because the root grows.
      expect(hairline, 1);
      expect(medium, 5); // 0.25rem at root 20
    });

    testWidgets('medium border scales with the root', (tester) async {
      late double at16;
      late double at18;
      Future<double> resolve(double root) async {
        late double value;
        await pumpWithTheme(
          tester,
          (context) {
            value = context.fwTheme.borders.resolveMedium(context);
            return const SizedBox();
          },
          theme: FwTheme.light().copyWith(metrics: FwMetrics(rootSize: root)),
        );
        return value;
      }

      at16 = await resolve(16);
      at18 = await resolve(18);
      expect(at16, 4);
      expect(at18, 4.5);
    });
  });

  group('FwShadows', () {
    test('light and dark variants differ', () {
      const light = FwShadows();
      const dark = FwShadows.dark();
      expect(light.sm, isNot(dark.sm));
      expect(light.none, isEmpty);
    });

    test('theme picks the variant by brightness', () {
      expect(FwTheme.light().shadows.sm, const FwShadows().sm);
      expect(FwTheme.dark().shadows.sm, const FwShadows.dark().sm);
    });

    test('lerp interpolates matching levels', () {
      const light = FwShadows();
      const dark = FwShadows.dark();
      final atStart = light.lerp(dark, 0);
      final atEnd = light.lerp(dark, 1);
      expect(atStart.sm, light.sm);
      expect(atEnd.sm, dark.sm);
    });
  });

  group('FwMotion', () {
    testWidgets('durations resolve per speed', (tester) async {
      late Duration fast;
      late Duration medium;
      late Duration slow;
      await pumpWithTheme(tester, (context) {
        final motion = context.fwTheme.motion;
        fast = motion.durationFor(context, FwMotionSpeed.fast);
        medium = motion.durationFor(context, FwMotionSpeed.medium);
        slow = motion.durationFor(context, FwMotionSpeed.slow);
        return const SizedBox();
      });
      expect(fast, const Duration(milliseconds: 120));
      expect(medium, const Duration(milliseconds: 200));
      expect(slow, const Duration(milliseconds: 320));
    });

    testWidgets('reduced motion collapses durations and linearizes curves', (
      tester,
    ) async {
      late Duration duration;
      late Curve curve;
      await pumpWithTheme(tester, (context) {
        final motion = context.fwTheme.motion;
        duration = motion.durationFor(context, FwMotionSpeed.slow);
        curve = motion.curveFor(context);
        return const SizedBox();
      }, media: const MediaQueryData(disableAnimations: true));
      expect(duration, Duration.zero);
      expect(curve, Curves.linear);
    });

    testWidgets('reduced motion can be opted out per theme', (tester) async {
      late Duration duration;
      await pumpWithTheme(
        tester,
        (context) {
          duration = context.fwTheme.motion.durationFor(
            context,
            FwMotionSpeed.slow,
          );
          return const SizedBox();
        },
        theme: FwTheme.light().copyWith(
          motion: const FwMotion(respectReducedMotion: false),
        ),
        media: const MediaQueryData(disableAnimations: true),
      );
      expect(duration, const Duration(milliseconds: 320));
    });
  });

  group('touch target invariant', () {
    test('theme rejects targets below 48 logical pixels', () {
      expect(
        () => FwTheme.light().copyWith(minTapTarget: 40),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
