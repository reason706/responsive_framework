import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

void main() {
  test(
    'light/dark semantic text pairs meet AA for supported example seeds',
    () {
      for (final brightness in Brightness.values) {
        for (final seed in [
          const Color(0xFF6750A4),
          const Color(0xFF006A80),
          Colors.yellow,
        ]) {
          final scheme = FwTheme.fromSeed(
            seed: seed,
            brightness: brightness,
          ).colors.scheme;
          for (final pair in [
            (scheme.primary, scheme.onPrimary),
            (scheme.surface, scheme.onSurface),
            (scheme.surfaceContainerLow, scheme.onSurface),
            (scheme.error, scheme.onError),
          ]) {
            expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
          }
        }
      }
    },
  );

  test(
    'copyWith preserves unrelated groups and lerp covers numeric tokens',
    () {
      final light = FwTheme.light();
      final thresholds = FwBreakpoints(sm: 500);
      final changed = light.copyWith(
        spacing: const FwSpacing(unit: 8),
        radii: const FwRadii(md: 16),
        breakpoints: thresholds,
        minTapTarget: 56,
        focusRing: const FwFocusRing(width: 4, offset: 3),
      );
      expect(changed.colors, same(light.colors));
      expect(changed.typography, same(light.typography));
      final halfway = light.lerp(changed, 0.5);
      expect(halfway.spacing.unit, 6);
      expect(halfway.radii.md, 12);
      expect(halfway.minTapTarget, 52);
      expect(halfway.focusRing.width, 3);
      expect(halfway.focusRing.offset, 2.5);
      expect(halfway.breakpoints, same(thresholds));
      expect(light.lerp(changed, 0).breakpoints, same(light.breakpoints));
    },
  );

  testWidgets('missing registration gives an actionable error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) => Text(context.fwTheme.toString())),
      ),
    );
    expect(tester.takeException().toString(), contains('FwTheme is missing'));
  });
}
