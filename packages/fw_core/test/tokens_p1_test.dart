import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

import 'tokens_test.dart' show pumpWithTheme;

/// P1 (improvement-plan-2): expanded spacing scale, micro aliases, and the
/// new token families (icon size, z-index, opacity, radius classes).
void main() {
  group('FwSpace hero steps', () {
    test('s32/s40 are 128px/160px at root 16', () {
      expect(FwSpaceScale.remRatio(FwSpace.s32), 8);
      expect(FwSpaceScale.remRatio(FwSpace.s40), 10);
    });

    testWidgets('s32/s40 scale with the root', (tester) async {
      Future<List<double>> resolve(double root) async {
        late double s32;
        late double s40;
        await pumpWithTheme(
          tester,
          (context) {
            s32 = FwSpaceRef(FwSpace.s32).resolve(context);
            s40 = FwSpaceRef(FwSpace.s40).resolve(context);
            return const SizedBox();
          },
          theme: FwTheme.light().copyWith(metrics: FwMetrics(rootSize: root)),
        );
        return [s32, s40];
      }

      final at16 = await resolve(16);
      final at20 = await resolve(20);
      expect(at16, [128, 160]);
      expect(at20, [160, 200]);
    });

    test('legacy FwSpacing keeps numeric parity including new steps', () {
      const spacing = FwSpacing();
      expect(spacing.of(FwSpace.s24), 96);
      expect(spacing.of(FwSpace.s32), 128);
      expect(spacing.of(FwSpace.s40), 160);
      expect(spacing.of(FwSpace.s4), 16);
    });
  });

  group('FwSpaceAlias micro aliases', () {
    testWidgets('iconGap is 2px and hairlineGap is 6px at root 16', (
      tester,
    ) async {
      late double iconGap;
      late double hairlineGap;
      await pumpWithTheme(tester, (context) {
        const scale = FwSpaceScale();
        iconGap = scale.resolveAlias(FwSpaceAlias.iconGap, context);
        hairlineGap = scale.resolveAlias(FwSpaceAlias.hairlineGap, context);
        return const SizedBox();
      });
      expect(iconGap, 2);
      expect(hairlineGap, 6);
    });

    testWidgets('micro aliases do not grow with the root', (tester) async {
      late double iconGap;
      await pumpWithTheme(
        tester,
        (context) {
          iconGap = const FwSpaceScale().resolveAlias(
            FwSpaceAlias.iconGap,
            context,
          );
          return const SizedBox();
        },
        theme: FwTheme.light().copyWith(metrics: const FwMetrics(rootSize: 20)),
      );
      expect(iconGap, 2);
    });

    testWidgets('micro aliases honor density scaling', (tester) async {
      Future<double> resolve(FwDensity density) async {
        late double value;
        await pumpWithTheme(tester, (context) {
          value = const FwSpaceScale().resolveAlias(
            FwSpaceAlias.hairlineGap,
            context,
          );
          return const SizedBox();
        }, theme: FwTheme.light(density: density));
        return value;
      }

      final comfortable = await resolve(FwDensity.comfortable);
      final compact = await resolve(FwDensity.compact);
      expect(comfortable, 6);
      expect(compact, lessThan(6));
      expect(compact, greaterThan(0));
    });
  });

  group('FwIconSizes', () {
    test('named sizes resolve to the spec pixels', () {
      const sizes = FwIconSizes();
      expect(sizes.of(FwIconSize.sm), 16);
      expect(sizes.of(FwIconSize.md), 20);
      expect(sizes.of(FwIconSize.lg), 24);
      expect(sizes.of(FwIconSize.xl), 32);
    });

    testWidgets('icon sizes ignore root and density', (tester) async {
      late double md;
      await pumpWithTheme(
        tester,
        (context) {
          md = context.fwTheme.iconSizes.of(FwIconSize.md);
          return const SizedBox();
        },
        theme: FwTheme.light(
          density: FwDensity.compact,
        ).copyWith(metrics: const FwMetrics(rootSize: 20)),
      );
      expect(md, 20);
    });

    test('theme override replaces the table', () {
      final theme = FwTheme.light().copyWith(
        iconSizes: const FwIconSizes(md: 22),
      );
      expect(theme.iconSizes.of(FwIconSize.md), 22);
      expect(theme.iconSizes.of(FwIconSize.sm), 16);
    });
  });

  group('FwZIndices', () {
    test('layers order strictly', () {
      const z = FwZIndices();
      final ordered = [
        z.of(FwZIndex.base),
        z.of(FwZIndex.raised),
        z.of(FwZIndex.overlay),
        z.of(FwZIndex.modal),
        z.of(FwZIndex.toast),
        z.of(FwZIndex.tooltip),
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i], greaterThan(ordered[i - 1]));
      }
    });

    test('spec values', () {
      const z = FwZIndices();
      expect(z.of(FwZIndex.base), 0);
      expect(z.of(FwZIndex.modal), 30);
      expect(z.of(FwZIndex.tooltip), 50);
    });
  });

  group('FwOpacities', () {
    test('spec values', () {
      const o = FwOpacities();
      expect(o.of(FwOpacity.full), 1);
      expect(o.of(FwOpacity.high), 0.87);
      expect(o.of(FwOpacity.medium), 0.6);
      expect(o.of(FwOpacity.disabled), 0.38);
      expect(o.of(FwOpacity.scrim), 0.32);
    });

    test('theme override replaces the ramp', () {
      final theme = FwTheme.light().copyWith(
        opacities: const FwOpacities(scrim: 0.5),
      );
      expect(theme.opacities.of(FwOpacity.scrim), 0.5);
      expect(theme.opacities.of(FwOpacity.full), 1);
    });
  });

  group('FwRadii.xs and FwRadiusClasses', () {
    test('xs resolves to the 2px micro radius', () {
      expect(const FwRadii().of(FwRadius.xs), 2);
    });

    test('radius classes resolve per research consensus', () {
      const classes = FwRadiusClasses();
      expect(classes.of(FwRadiusClass.button), 8);
      expect(classes.of(FwRadiusClass.input), 8);
      expect(classes.of(FwRadiusClass.card), 12);
      expect(classes.of(FwRadiusClass.modal), 16);
      expect(classes.of(FwRadiusClass.pill), 999);
    });

    test('borderRadius helper returns circular radii', () {
      expect(
        const FwRadiusClasses().borderRadius(FwRadiusClass.card),
        BorderRadius.circular(12),
      );
    });

    test('theme override replaces the class table', () {
      final theme = FwTheme.light().copyWith(
        radiusClasses: const FwRadiusClasses(button: 4),
      );
      expect(theme.radiusClasses.of(FwRadiusClass.button), 4);
      expect(theme.radiusClasses.of(FwRadiusClass.card), 12);
    });
  });

  group('FwTheme lerp covers the new families', () {
    test('lerp mixes opacities and radius classes, switches the rest', () {
      final a = FwTheme.light();
      final b = FwTheme.light().copyWith(
        opacities: const FwOpacities(scrim: 0.6),
        radiusClasses: const FwRadiusClasses(card: 20),
        iconSizes: const FwIconSizes(md: 22),
      );
      final mid = a.lerp(b, 0.5);
      expect(mid.opacities.of(FwOpacity.scrim), closeTo(0.46, 0.001));
      expect(mid.radiusClasses.of(FwRadiusClass.card), 16);
      // Structural tables switch discretely at the midpoint.
      expect(mid.iconSizes.of(FwIconSize.md), 22);
      expect(a.lerp(b, 0.25).iconSizes.of(FwIconSize.md), 20);
    });
  });
}
