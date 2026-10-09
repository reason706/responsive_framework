import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  test('fromColors resolves the same roles the widgets used', () {
    final theme = FwTheme.light();
    final table = FwButtonColors.fromColors(theme.colors);
    for (final intent in FwIntent.values) {
      final (bg, fg) = intentRoles(intent);
      final solidSet = table.solid[intent]!;
      expect(solidSet.background, theme.colors.of(bg), reason: '$intent bg');
      expect(solidSet.foreground, theme.colors.of(fg), reason: '$intent fg');
      final textSet = table.textTreatment[intent]!;
      expect(textSet.background, isNull, reason: '$intent transparent');
      expect(
        textSet.foreground,
        theme.colors.of(bg),
        reason: '$intent text fg',
      );
    }
  });

  test('setFor selects the solid or shared text table', () {
    final table = FwButtonColors.fromColors(FwTheme.light().colors);
    expect(
      table.setFor(filled: true, intent: FwIntent.danger).background,
      table.solid[FwIntent.danger]!.background,
    );
    expect(
      table.setFor(filled: false, intent: FwIntent.danger).foreground,
      table.textTreatment[FwIntent.danger]!.foreground,
    );
  });

  test('lerp interpolates every slot in both tables', () {
    final a = FwButtonColors.fromColors(FwTheme.light().colors);
    final b = FwButtonColors.fromColors(FwTheme.dark().colors);
    final mid = a.lerp(b, 0.5);
    expect(
      mid.solid[FwIntent.primary]!.background,
      Color.lerp(
        a.solid[FwIntent.primary]!.background,
        b.solid[FwIntent.primary]!.background,
        0.5,
      ),
    );
    expect(
      mid.textTreatment[FwIntent.primary]!.foreground,
      Color.lerp(
        a.textTreatment[FwIntent.primary]!.foreground,
        b.textTreatment[FwIntent.primary]!.foreground,
        0.5,
      ),
    );
    expect(mid.lerp(null, 0.5), mid);
  });

  test('FwTheme registers buttonColors as a ThemeExtension', () {
    final data = FwTheme.ocean().toThemeData();
    expect(data.extension<FwTheme>(), isNotNull);
    final registered = data.extension<FwButtonColors>();
    expect(registered, isNotNull);
    expect(
      registered!.solid[FwIntent.primary]!.background,
      data.extension<FwTheme>()!.colors.of(FwColorRole.primary),
    );
  });

  test('copyWith rebuilds the table when colors change', () {
    final theme = FwTheme.light();
    final recolored = theme.copyWith(colors: FwTheme.dark().colors);
    expect(
      recolored.buttonColors.solid[FwIntent.primary]!.background,
      recolored.colors.of(FwColorRole.primary),
    );
    // An explicit table survives a color change untouched.
    final custom = FwButtonColors.fromColors(theme.colors);
    expect(
      theme.copyWith(colors: FwTheme.dark().colors, buttonColors: custom),
      isNotNull,
    );
    expect(
      theme
          .copyWith(colors: FwTheme.dark().colors, buttonColors: custom)
          .buttonColors,
      same(custom),
    );
  });

  test('theme lerp carries the component table', () {
    final mid = FwTheme.light().lerp(FwTheme.dark(), 0.5);
    expect(
      mid.buttonColors.solid[FwIntent.primary]!.background,
      Color.lerp(
        FwTheme.light().colors.of(FwColorRole.primary),
        FwTheme.dark().colors.of(FwColorRole.primary),
        0.5,
      ),
    );
  });
}
