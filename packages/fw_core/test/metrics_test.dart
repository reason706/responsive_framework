import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

/// Pumps [builder] with a Material app carrying [theme] (or the default
/// light theme) inside a fixed-width box so container queries resolve.
///
/// The test surface is enlarged so explicit widths up to 1440 logical
/// pixels are honored (the default 800px surface would clamp them).
Future<void> pumpFw(
  WidgetTester tester,
  WidgetBuilder builder, {
  FwTheme? theme,
  FwMetrics? rootMetrics,
  double width = 800,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final effectiveTheme = theme ?? FwTheme.light();
  Widget app = MaterialApp(
    theme: effectiveTheme.toThemeData(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: FwContainerQuery(child: Builder(builder: builder)),
        ),
      ),
    ),
  );
  if (rootMetrics != null) {
    app = FwRootScope(metrics: rootMetrics, child: app);
  }
  await tester.pumpWidget(Directionality(textDirection: direction, child: app));
  await tester.pumpAndSettle();
}

void main() {
  group('FwMetrics', () {
    testWidgets('defaults to root 16 and comfortable density', (tester) async {
      late FwMetrics metrics;
      await pumpFw(tester, (context) {
        metrics = FwMetrics.of(context);
        return const SizedBox();
      });
      expect(metrics.rootSize, 16);
      expect(metrics.density, FwDensity.comfortable);
      expect(metrics.responsiveRoot, isNull);
    });

    testWidgets('explicit root scope overrides the theme default', (
      tester,
    ) async {
      late double resolved;
      await pumpFw(tester, (context) {
        resolved = FwRem(1).resolve(context);
        return const SizedBox();
      }, rootMetrics: const FwMetrics(rootSize: 20));
      expect(resolved, 20);
    });

    testWidgets('responsive root resolves against the explicit width', (
      tester,
    ) async {
      const metrics = FwMetrics(responsiveRoot: Responsive(base: 16, lg: 18));
      late double narrow;
      late double wide;
      await pumpFw(
        tester,
        (context) {
          narrow = FwRem(1).resolve(context);
          return const SizedBox();
        },
        rootMetrics: metrics,
        width: 800,
      );
      await pumpFw(
        tester,
        (context) {
          wide = FwRem(1).resolve(context);
          return const SizedBox();
        },
        rootMetrics: metrics,
        width: 1000,
      );
      expect(narrow, 16);
      expect(wide, 18);
    });

    testWidgets('nested color scope does not redefine rem', (tester) async {
      late double resolved;
      await pumpFw(
        tester,
        (context) {
          // A nested theme override (as a dialog would apply) must inherit
          // the root; only an explicit FwRootScope may change it.
          resolved = FwRem(1).resolve(context);
          return const SizedBox();
        },
        rootMetrics: const FwMetrics(rootSize: 20),
        theme: FwTheme.light(seed: const Color(0xFF006A80)),
      );
      expect(resolved, 20);
    });

    testWidgets('explicit nested root scope is honored', (tester) async {
      late double resolved;
      await pumpFw(tester, (context) {
        return FwRootScope(
          metrics: const FwMetrics(rootSize: 18),
          child: Builder(
            builder: (context) {
              resolved = FwRem(1).resolve(context);
              return const SizedBox();
            },
          ),
        );
      }, rootMetrics: const FwMetrics(rootSize: 20));
      expect(resolved, 18);
    });

    testWidgets('theme-configured metrics are used without a scope', (
      tester,
    ) async {
      late double resolved;
      await pumpFw(
        tester,
        (context) {
          resolved = FwRem(1).resolve(context);
          return const SizedBox();
        },
        theme: FwTheme.light().copyWith(metrics: const FwMetrics(rootSize: 18)),
      );
      expect(resolved, 18);
    });

    test('rejects non-positive responsive root values at resolve time', () {
      const metrics = FwMetrics(responsiveRoot: Responsive(base: 0));
      expect(
        () => metrics.effectiveRootSize(FwBreakpoints.standard, 800),
        throwsStateError,
      );
    });
  });

  group('FwSpaceScale', () {
    testWidgets('token resolution has root-16 parity with legacy spacing', (
      tester,
    ) async {
      const legacy = FwSpacing();
      const scale = FwSpaceScale();
      late Map<FwSpace, double> resolved;
      await pumpFw(tester, (context) {
        resolved = {for (final t in FwSpace.values) t: scale.of(t, context)};
        return const SizedBox();
      });
      for (final token in FwSpace.values) {
        expect(resolved[token], legacy.of(token), reason: 'token $token');
      }
    });

    testWidgets('tokens follow an explicit root of 18', (tester) async {
      late double s4;
      await pumpFw(tester, (context) {
        s4 = const FwSpaceScale().of(FwSpace.s4, context);
        return const SizedBox();
      }, rootMetrics: const FwMetrics(rootSize: 18));
      expect(s4, 18);
    });

    testWidgets('semantic page inset is responsive', (tester) async {
      const scale = FwSpaceScale();
      Future<double> atWidth(double width) async {
        late double value;
        await pumpFw(tester, (context) {
          value = scale.resolveAlias(FwSpaceAlias.pageInset, context);
          return const SizedBox();
        }, width: width);
        return value;
      }

      expect(await atWidth(400), 16); // base 1rem
      expect(await atWidth(800), 24); // md 1.5rem
      expect(await atWidth(1000), 32); // lg 2rem
    });

    testWidgets('density scales semantic aliases, not raw tokens', (
      tester,
    ) async {
      const scale = FwSpaceScale();
      Future<double> alias(FwDensity density) async {
        late double value;
        await pumpFw(tester, (context) {
          value = scale.resolveAlias(FwSpaceAlias.controlBlock, context);
          return const SizedBox();
        }, rootMetrics: FwMetrics(density: density));
        return value;
      }

      Future<double> token(FwDensity density) async {
        late double value;
        await pumpFw(tester, (context) {
          value = scale.of(FwSpace.s2, context);
          return const SizedBox();
        }, rootMetrics: FwMetrics(density: density));
        return value;
      }

      // controlBlock is 0.5rem = 8 at root 16.
      expect(await alias(FwDensity.comfortable), 8);
      expect(await alias(FwDensity.compact), 7); // 8 * 0.875
      expect(await alias(FwDensity.spacious), 10); // 8 * 1.25
      // Raw tokens ignore density.
      expect(await token(FwDensity.compact), 8);
      expect(await token(FwDensity.spacious), 8);
    });

    testWidgets('FwDensityScope overrides density per subtree', (tester) async {
      const scale = FwSpaceScale();
      late FwDensity outer;
      late FwDensity inner;
      await pumpFw(tester, (context) {
        outer = FwMetrics.of(context).density;
        return FwDensityScope(
          density: FwDensity.compact,
          child: Builder(
            builder: (context) {
              inner = FwMetrics.of(context).density;
              // Aliases resolve against the scoped density…
              expect(
                scale.resolveAlias(FwSpaceAlias.controlBlock, context),
                7, // 8 * 0.875
              );
              // …while the root size is untouched.
              expect(FwMetrics.of(context).rootSize, 16);
              return const SizedBox();
            },
          ),
        );
      });
      expect(outer, FwDensity.comfortable);
      expect(inner, FwDensity.compact);
    });

    testWidgets('FwDensityScope.of reads the nearest scope', (tester) async {
      late FwDensity scoped;
      late FwDensity unscoped;
      await pumpFw(tester, (context) {
        unscoped = FwDensityScope.of(context);
        return FwDensityScope(
          density: FwDensity.spacious,
          child: Builder(
            builder: (context) {
              scoped = FwDensityScope.of(context);
              return const SizedBox();
            },
          ),
        );
      });
      expect(unscoped, FwDensity.comfortable);
      expect(scoped, FwDensity.spacious);
    });
  });

  group('FwEmScope', () {
    testWidgets('FwEm resolves against the declared size', (tester) async {
      late double resolved;
      await pumpFw(tester, (context) {
        return FwEmScope(
          declaredSize: 14,
          child: Builder(
            builder: (context) {
              resolved = FwEm(2).resolve(context);
              return const SizedBox();
            },
          ),
        );
      });
      expect(resolved, 28);
    });

    testWidgets('FwEm without a scope throws an actionable error', (
      tester,
    ) async {
      await pumpFw(tester, (context) {
        return Builder(
          builder: (context) {
            FwEm(1).resolve(context);
            return const SizedBox();
          },
        );
      });
      expect(tester.takeException(), isFlutterError);
    });
  });

  group('FwInsets', () {
    testWidgets('directional insets resolve with metrics', (tester) async {
      late EdgeInsetsDirectional insets;
      await pumpFw(tester, (context) {
        insets = FwInsets.directional(
          start: FwRem(1),
          top: FwPx(4),
          bottom: FwSpaceRef(FwSpace.s2),
        ).resolve(context);
        return const SizedBox();
      });
      expect(insets.start, 16);
      expect(insets.end, 0);
      expect(insets.top, 4);
      expect(insets.bottom, 8);
    });

    testWidgets('insets follow text direction', (tester) async {
      late EdgeInsetsDirectional resolvedLtr;
      late EdgeInsetsDirectional resolvedRtl;
      await pumpFw(tester, (context) {
        resolvedLtr = FwInsets.directional(start: FwRem(1)).resolve(context);
        return const SizedBox();
      }, direction: TextDirection.ltr);
      await pumpFw(tester, (context) {
        resolvedRtl = FwInsets.directional(start: FwRem(1)).resolve(context);
        return const SizedBox();
      }, direction: TextDirection.rtl);
      final ltr = resolvedLtr.resolve(TextDirection.ltr);
      final rtl = resolvedRtl.resolve(TextDirection.rtl);
      expect(ltr.left, 16);
      expect(ltr.right, 0);
      expect(rtl.right, 16);
      expect(rtl.left, 0);
    });

    test('rejects mixing directional and physical edges', () {
      expect(
        () => FwInsets.only(start: FwRem(1), left: FwPx(2)),
        throwsArgumentError,
      );
    });
  });
}
