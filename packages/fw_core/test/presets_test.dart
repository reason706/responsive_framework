import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  test('every shipped preset maps to a Material theme', () {
    expect(FwTheme.presets.map((p) => p.name).toSet().length, 14);
    for (final preset in FwTheme.presets) {
      expect(
        () => preset.theme.toThemeData(),
        returnsNormally,
        reason: preset.name,
      );
    }
  });

  test('brand presets meet the 4.5:1 text contrast floor', () {
    final brands = <(String, FwTheme)>[
      ('Ocean', FwTheme.ocean()),
      ('Ocean · Dark', FwTheme.ocean(brightness: Brightness.dark)),
      ('Forest', FwTheme.forest()),
      ('Forest · Dark', FwTheme.forest(brightness: Brightness.dark)),
      ('Sunset', FwTheme.sunset()),
      ('Sunset · Dark', FwTheme.sunset(brightness: Brightness.dark)),
      ('Monochrome', FwTheme.monochrome()),
      ('Monochrome · Dark', FwTheme.monochrome(brightness: Brightness.dark)),
    ];
    for (final (name, theme) in brands) {
      final colors = theme.colors;
      final surface = colors.of(FwColorRole.surface);
      expect(
        contrastRatio(colors.of(FwColorRole.text), surface),
        greaterThanOrEqualTo(4.5),
        reason: '$name text/surface',
      );
      expect(
        contrastRatio(colors.of(FwColorRole.textMuted), surface),
        greaterThanOrEqualTo(4.5),
        reason: '$name textMuted/surface',
      );
      for (final (label, bg, fg) in [
        ('primary', FwColorRole.primary, FwColorRole.onPrimary),
        ('success', FwColorRole.success, FwColorRole.onSuccess),
        ('warning', FwColorRole.warning, FwColorRole.onWarning),
        ('info', FwColorRole.info, FwColorRole.onInfo),
        ('error', FwColorRole.error, FwColorRole.onError),
      ]) {
        expect(
          contrastRatio(colors.of(fg), colors.of(bg)),
          greaterThanOrEqualTo(4.5),
          reason: '$name $label pair',
        );
      }
      // The brightness parameter is honored per brand.
      expect(
        theme.colors.scheme.brightness,
        name.endsWith('Dark') ? Brightness.dark : Brightness.light,
        reason: name,
      );
    }
  });

  test('all presets are value-swaps on identical token keys', () {
    Map<String, Color> keyMap(FwTheme theme) => {
      for (final role in FwColorRole.values) role.name: theme.colors.of(role),
    };
    final maps = {
      for (final preset in FwTheme.presets) preset.name: keyMap(preset.theme),
    };
    final referenceKeys = maps.values.first.keys.toSet();
    for (final entry in maps.entries) {
      expect(
        entry.value.keys.toSet(),
        referenceKeys,
        reason: '${entry.key} exposes the same token keys',
      );
    }
    // Same keys, different values: a brand preset is not a copy of Light.
    final lightPrimary = maps['Light']!['primary'];
    for (final name in ['Ocean', 'Forest', 'Sunset', 'Monochrome']) {
      expect(
        maps[name]!['primary'],
        isNot(equals(lightPrimary)),
        reason: '$name swaps the primary value',
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
