import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  group('FwTypography defaults', () {
    final scale = FwTypography.defaults();

    test('covers every role', () {
      for (final role in FwTextRole.values) {
        expect(scale.roles.containsKey(role), isTrue, reason: '$role');
      }
    });

    test('body sizes follow the root', () {
      TextStyle body(double root) => scale
          .of(FwTextRole.body)
          .resolveRaw(rootSize: root, fonts: scale.effectiveFonts);
      expect(body(16).fontSize, 16);
      expect(body(18).fontSize, 18);
      expect(body(20).fontSize, 20);
      expect(body(16).height, 1.5);
    });

    test('fluid headings interpolate across the container width', () {
      TextStyle h1(double width) => scale
          .of(FwTextRole.h1)
          .resolveRaw(
            rootSize: 16,
            fonts: scale.effectiveFonts,
            explicitWidth: width,
          );
      expect(h1(360).fontSize, 28); // 1.75rem min
      expect(h1(780).fontSize, 34); // midpoint
      expect(h1(1200).fontSize, 40); // 2.5rem max
      expect(h1(200).fontSize, 28); // clamped below
      expect(h1(5000).fontSize, 40); // clamped above
    });

    test('fixed roles do not grow with width', () {
      TextStyle body(double width) => scale
          .of(FwTextRole.body)
          .resolveRaw(
            rootSize: 16,
            fonts: scale.effectiveFonts,
            explicitWidth: width,
          );
      expect(body(360).fontSize, 16);
      expect(body(1400).fontSize, 16);
    });

    test('weights use installed font faces', () {
      // The spec table suggests 600 for h2-h6/label; the bundled example
      // faces (Roboto Regular/Medium/Bold) have no 600 face, so the default
      // preset uses the supported 500 face instead of nearest-weight fallback.
      expect(
        scale.of(FwTextRole.h2).weight,
        FontWeight.w500,
        reason: 'documented deviation: 500 instead of 600',
      );
      expect(scale.of(FwTextRole.h1).weight, FontWeight.w700);
      expect(scale.of(FwTextRole.body).weight, FontWeight.w400);
      expect(scale.of(FwTextRole.label).weight, FontWeight.w500);
    });

    test('line heights are multipliers', () {
      expect(scale.of(FwTextRole.h1).lineHeight, 1.2);
      expect(scale.of(FwTextRole.body).lineHeight, 1.5);
    });

    test('code role uses the monospace slot', () {
      expect(scale.of(FwTextRole.code).fontRole, FwFontRole.monospace);
      final style = scale
          .of(FwTextRole.code)
          .resolveRaw(rootSize: 16, fonts: scale.effectiveFonts);
      expect(style.fontFamily, 'RobotoMono');
    });

    test('heading roles default to the body family when unset', () {
      final style = scale
          .of(FwTextRole.h1)
          .resolveRaw(rootSize: 16, fonts: scale.effectiveFonts);
      expect(style.fontFamily, 'Roboto');
    });

    test('custom heading family is honored', () {
      final custom = FwTypography.defaults().copyWith(
        fonts: const FwFontFamilies(heading: 'Custom Serif'),
      );
      final style = custom
          .of(FwTextRole.h1)
          .resolveRaw(rootSize: 16, fonts: custom.effectiveFonts);
      expect(style.fontFamily, 'Custom Serif');
      final body = custom
          .of(FwTextRole.body)
          .resolveRaw(rootSize: 16, fonts: custom.effectiveFonts);
      expect(body.fontFamily, 'Roboto');
    });

    test('rejects a missing role', () {
      expect(() => FwTypography(roles: const {}), throwsArgumentError);
    });

    test('rejects a non-positive line height', () {
      expect(
        () => FwTextStyle(size: FwRem(1), lineHeight: 0),
        throwsArgumentError,
      );
    });

    test('overline follows the research micro-label spec', () {
      // P3.3: 11px, w600, 0.06em tracking. Uppercase is a content transform
      // in FwText (Flutter has no text-transform), not a style property.
      final style = scale
          .of(FwTextRole.overline)
          .resolveRaw(rootSize: 16, fonts: scale.effectiveFonts, emSize: 11);
      expect(style.fontSize, 11);
      expect(style.fontWeight, FontWeight.w600);
      // 0.06em of 11px = 0.66px.
      expect(style.letterSpacing, closeTo(0.66, 0.001));
    });

    test('numeric uses tabular figures at body metrics', () {
      final role = scale.of(FwTextRole.numeric);
      final style = role.resolveRaw(rootSize: 16, fonts: scale.effectiveFonts);
      expect(style.fontSize, 16);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });
  });

  group('Material mapping', () {
    test('snapshot captures declared sizes at the root', () {
      final theme = FwTypography.defaults().toMaterialTextTheme(rootSize: 16);
      expect(theme.bodyMedium!.fontSize, 16);
      expect(theme.bodySmall!.fontSize, 14);
      expect(theme.labelMedium!.fontSize, 12);
      // Fluid roles snapshot at their minimum endpoint.
      expect(theme.displayLarge!.fontSize, 40);
      expect(theme.displaySmall!.fontSize, 28);
    });

    test('snapshot follows a larger root', () {
      final theme = FwTypography.defaults().toMaterialTextTheme(rootSize: 18);
      expect(theme.bodyMedium!.fontSize, 18);
    });

    test('FwTheme maps the type scale into toThemeData', () {
      final fwTheme = FwTheme.light();
      final material = fwTheme.toThemeData();
      expect(material.textTheme.bodyMedium!.fontSize, 16);
      // Explicit TextTheme overrides still win.
      final custom = FwTheme.light().copyWith(
        typography: const TextTheme(bodyMedium: TextStyle(fontSize: 42)),
      );
      expect(custom.toThemeData().textTheme.bodyMedium!.fontSize, 42);
    });
  });

  group('context resolution', () {
    testWidgets('roles resolve with root metrics in context', (tester) async {
      late TextStyle h1;
      late TextStyle body;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Center(
              // Fluid roles resolve against the explicit container width.
              child: SizedBox(
                width: 780,
                child: FwContainerQuery(
                  child: Builder(
                    builder: (context) {
                      final scale = context.fwTheme.typeScale;
                      h1 = scale.resolve(FwTextRole.h1, context);
                      body = scale.resolve(FwTextRole.body, context);
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Declared sizes only — the ambient TextScaler applies once at render.
      expect(body.fontSize, 16);
      // h1 is fluid 1.75→2.5rem over 360→1200: 34 at width 780.
      expect(h1.fontSize, 34);
      expect(body.height, 1.5);
    });

    testWidgets('fluid headings use the container width', (tester) async {
      late TextStyle h1;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 780,
                child: FwContainerQuery(
                  child: Builder(
                    builder: (context) {
                      h1 = context.fwTheme.typeScale.resolve(
                        FwTextRole.h1,
                        context,
                      );
                      // Wrap the declared size in an em scope for descendants.
                      return FwEmScope(
                        declaredSize: h1.fontSize!,
                        child: const SizedBox(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(h1.fontSize, 34);
    });
  });
}
