import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

/// Wave 0, M0.2: elevation levels 0–5 resolve to surface-tint + shadow
/// tokens; out-of-range levels throw.
void main() {
  Future<FwElevationLevel> levelAt(
    WidgetTester tester,
    int level, {
    FwTheme? theme,
  }) async {
    late FwElevationLevel resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: (theme ?? FwTheme.light()).toThemeData(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              resolved = const FwElevation().of(context, level);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    // MaterialApp animates theme changes; settle so the new theme applies.
    await tester.pumpAndSettle();
    return resolved;
  }

  testWidgets('levels 0-5 resolve with increasing tint', (tester) async {
    final levels = <FwElevationLevel>[];
    for (var level = 0; level <= 5; level++) {
      levels.add(await levelAt(tester, level));
    }
    // Tint alpha grows monotonically; level 0 has no tint and no shadow.
    var previous = -1.0;
    for (final resolved in levels) {
      final alpha = resolved.surfaceTint.a;
      expect(alpha, greaterThanOrEqualTo(previous));
      previous = alpha;
    }
    expect(levels[0].surfaceTint.a, 0);
    expect(levels[0].shadows, isEmpty);
    expect(levels[5].shadows, isNotEmpty);
    expect(levels[5].surfaceTint.a, greaterThan(levels[1].surfaceTint.a));
  });

  testWidgets('shadows come from the theme shadow tokens', (tester) async {
    final light = await levelAt(tester, 4);
    final dark = await levelAt(tester, 4, theme: FwTheme.dark());
    // Same level, different shadow colors per color mode.
    expect(light.shadows.first.color, isNot(dark.shadows.first.color));
  });

  testWidgets('out-of-range levels throw RangeError', (tester) async {
    for (final bad in [-1, 6, 99]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(
                  () => const FwElevation().of(context, bad),
                  throwsRangeError,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('decoration blends tint over the surface', (tester) async {
    late BoxDecoration decoration;
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light().toThemeData(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              decoration = const FwElevation().decoration(context, 3);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.color, isNotNull);
  });
}
