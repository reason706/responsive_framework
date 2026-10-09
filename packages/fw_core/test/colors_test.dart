import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  group('semantic status pairs', () {
    test('every status pair meets 4.5:1 in both modes', () {
      for (final brightness in Brightness.values) {
        final colors = FwColors(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: brightness,
          ),
        );
        final pairs = [
          (colors.success, colors.onSuccess),
          (colors.successContainer, colors.onSuccessContainer),
          (colors.warning, colors.onWarning),
          (colors.warningContainer, colors.onWarningContainer),
          (colors.info, colors.onInfo),
          (colors.infoContainer, colors.onInfoContainer),
        ];
        for (final pair in pairs) {
          expect(
            contrastRatio(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '$brightness ${pair.$1} on ${pair.$2}',
          );
        }
      }
    });

    test('status pairs do not depend on the seed', () {
      // Status colors are explicitly generated, not seed-derived.
      final a = FwColors(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      );
      final b = FwColors(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF006A80),
          brightness: Brightness.light,
        ),
      );
      expect(a.success, b.success);
      expect(a.warning, b.warning);
      expect(a.info, b.info);
    });

    test('text roles meet 4.5:1 for the example seeds', () {
      for (final brightness in Brightness.values) {
        for (final seed in [const Color(0xFF6750A4), const Color(0xFF006A80)]) {
          final colors = FwColors(
            ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
          );
          expect(
            contrastRatio(
              colors.of(FwColorRole.text),
              colors.of(FwColorRole.surface),
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(
              colors.of(FwColorRole.textMuted),
              colors.of(FwColorRole.surface),
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });

    test('focus ring stays visible against surfaces', () {
      for (final brightness in Brightness.values) {
        for (final seed in [const Color(0xFF6750A4), const Color(0xFF006A80)]) {
          final colors = FwColors(
            ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
          );
          expect(
            contrastRatio(
              colors.of(FwColorRole.focusRing),
              colors.of(FwColorRole.surface),
            ),
            greaterThanOrEqualTo(3),
            reason: '$brightness seed $seed',
          );
        }
      }
    });

    test('every role resolves without throwing', () {
      for (final brightness in Brightness.values) {
        final colors = FwColors(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: brightness,
          ),
        );
        for (final role in FwColorRole.values) {
          expect(() => colors.of(role), returnsNormally, reason: '$role');
        }
      }
    });
  });

  group('FwStateRoles', () {
    FwColors colors() => FwColors(
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
    );

    const roles = FwStateRoles(
      base: FwColorRole.primary,
      hovered: FwColorRole.secondary,
      pressed: FwColorRole.primaryContainer,
      focused: FwColorRole.info,
      selected: FwColorRole.success,
      disabled: FwColorRole.disabled,
      invalid: FwColorRole.error,
    );

    test('disabled overrides activation states', () {
      final c = colors();
      expect(
        roles.resolve({WidgetState.disabled, WidgetState.pressed}, c),
        c.of(FwColorRole.disabled),
      );
      expect(
        roles.resolve({WidgetState.disabled, WidgetState.hovered}, c),
        c.of(FwColorRole.disabled),
      );
    });

    test('pressed beats hovered beats base', () {
      final c = colors();
      expect(
        roles.resolve({WidgetState.pressed, WidgetState.hovered}, c),
        c.of(FwColorRole.primaryContainer),
      );
      expect(
        roles.resolve({WidgetState.hovered}, c),
        c.of(FwColorRole.secondary),
      );
      expect(roles.resolve(<WidgetState>{}, c), c.of(FwColorRole.primary));
    });

    test('invalid and focused coexist with invalid winning the color', () {
      final c = colors();
      // Invalid selects the color; focus keeps its separately drawn ring.
      expect(
        roles.resolve({WidgetState.error, WidgetState.focused}, c),
        c.of(FwColorRole.error),
      );
      expect(roles.resolve({WidgetState.focused}, c), c.of(FwColorRole.info));
    });

    test('selected is distinct from hovered', () {
      final c = colors();
      expect(
        roles.resolve({WidgetState.selected}, c),
        c.of(FwColorRole.success),
      );
    });

    test('unconfigured roles resolve to null', () {
      const empty = FwStateRoles();
      expect(empty.roleFor({WidgetState.pressed}), isNull);
      expect(empty.resolve({WidgetState.pressed}, colors()), isNull);
    });
  });

  group('FwColors copy/lerp', () {
    test('copyWith replaces only the given fields', () {
      final colors = FwColors(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      );
      final changed = colors.copyWith(success: const Color(0xFF000000));
      expect(changed.success, const Color(0xFF000000));
      expect(changed.warning, colors.warning);
      expect(changed.scheme, colors.scheme);
    });

    test('lerp endpoints are exact', () {
      final light = FwColors(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      );
      final dark = FwColors(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      );
      expect(light.lerp(dark, 0).success, light.success);
      expect(light.lerp(dark, 1).success, dark.success);
    });
  });
}
