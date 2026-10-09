import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  test('every shipped preset maps to a Material theme', () {
    expect(FwTheme.presets.map((p) => p.name).toSet().length, 6);
    for (final preset in FwTheme.presets) {
      expect(
        () => preset.theme.toThemeData(),
        returnsNormally,
        reason: preset.name,
      );
    }
  });

  test('high-contrast presets target 7:1 for text', () {
    for (final theme in [
      FwTheme.highContrastLight(),
      FwTheme.highContrastDark(),
    ]) {
      final colors = theme.colors;
      final surface = colors.of(FwColorRole.surface);
      expect(
        contrastRatio(colors.of(FwColorRole.text), surface),
        greaterThanOrEqualTo(7),
      );
      expect(
        contrastRatio(colors.of(FwColorRole.textMuted), surface),
        greaterThanOrEqualTo(7),
      );
      // Brand pairs stay AA even in high contrast.
      expect(
        contrastRatio(
          colors.of(FwColorRole.primary),
          colors.of(FwColorRole.onPrimary),
        ),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('density variants carry their density without shrinking text', () {
    final compact = FwTheme.light(density: FwDensity.compact);
    final comfortable = FwTheme.light(density: FwDensity.comfortable);
    expect(compact.metrics.density, FwDensity.compact);
    expect(comfortable.metrics.density, FwDensity.comfortable);
    expect(compact.metrics.rootSize, 16);
    // The 48px touch-target invariant survives density changes.
    expect(compact.minTapTarget, 48);
  });

  testWidgets('preset gallery renders all presets without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final preset in FwTheme.presets)
                  MaterialApp(
                    theme: preset.theme.toThemeData(),
                    home: Builder(
                      builder: (context) => Card(
                        color: context.fwTheme.colors.of(FwColorRole.surface),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            preset.name,
                            style: context.fwTheme.typeScale.resolve(
                              FwTextRole.label,
                              context,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark · High contrast'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
