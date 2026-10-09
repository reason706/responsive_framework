import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  group('FwThemeScope', () {
    testWidgets('overrides colors for descendants only', (tester) async {
      late Brightness outer;
      late Brightness inner;
      late Brightness outerAfter;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                outer = context.fwTheme.colors.scheme.brightness;
                return FwThemeScope(
                  theme: context.fwTheme.copyWith(
                    colors: FwColors(
                      ColorScheme.fromSeed(
                        seedColor: Colors.blue,
                        brightness: Brightness.dark,
                      ),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      inner = context.fwTheme.colors.scheme.brightness;
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      // A sibling subtree keeps the outer theme.
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                outerAfter = context.fwTheme.colors.scheme.brightness;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(outer, Brightness.light);
      expect(inner, Brightness.dark);
      expect(outerAfter, Brightness.light);
    });

    testWidgets('propagates the Material adapter to native primitives', (
      tester,
    ) async {
      late ColorScheme materialScheme;
      late FwTheme scopedExtension;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => FwThemeScope(
                theme: context.fwTheme.copyWith(
                  colors: FwColors(
                    ColorScheme.fromSeed(
                      seedColor: Colors.teal,
                      brightness: Brightness.dark,
                    ),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    materialScheme = Theme.of(context).colorScheme;
                    scopedExtension = Theme.of(context).extension<FwTheme>()!;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      // Native Material widgets inside the scope see the scoped scheme...
      expect(materialScheme.brightness, Brightness.dark);
      // ...and the FwTheme extension matches the scoped theme.
      expect(scopedExtension.colors.scheme.brightness, Brightness.dark);
    });

    testWidgets('unspecified properties inherit from the parent theme', (
      tester,
    ) async {
      late FwTheme inner;
      final parent = FwTheme.light().copyWith(
        metrics: const FwMetrics(rootSize: 18),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: parent.toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => FwThemeScope(
                theme: context.fwTheme.copyWith(
                  colors: FwColors(
                    ColorScheme.fromSeed(
                      seedColor: Colors.red,
                      brightness: Brightness.dark,
                    ),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    inner = context.fwTheme;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(inner.metrics.rootSize, 18);
      expect(inner.spacing, parent.spacing);
      expect(inner.radii, parent.radii);
      expect(inner.motion, parent.motion);
      expect(inner.colors.scheme.brightness, Brightness.dark);
    });

    testWidgets('a color scope never redefines rem', (tester) async {
      late double resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => FwThemeScope(
                theme: context.fwTheme.copyWith(
                  colors: FwColors(
                    ColorScheme.fromSeed(
                      seedColor: Colors.purple,
                      brightness: Brightness.dark,
                    ),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    resolved = FwRem(1).resolve(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(resolved, 16);
    });
  });

  group('FwOverride', () {
    test('absent keeps the inherited value', () {
      const override = FwOverride<String>.absent();
      expect(override.present, isFalse);
      expect(override.resolve('inherited'), 'inherited');
      expect(override.resolve(null), isNull);
    });

    test('explicit value wins, including explicit null', () {
      expect(const FwOverride.value('x').resolve('inherited'), 'x');
      // Explicit clearing is distinguishable from "not specified".
      expect(const FwOverride<String>.value(null).resolve('inherited'), isNull);
      expect(const FwOverride<String>.value(null).present, isTrue);
    });

    test('compares by presence and value', () {
      expect(const FwOverride.value(1), const FwOverride.value(1));
      expect(const FwOverride.value(1), isNot(const FwOverride.value(2)));
      expect(
        const FwOverride<int>.absent(),
        isNot(const FwOverride<int>.value(1)),
      );
    });
  });
}
