import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

/// Nonlinear test scaler: 1.2x below 20 logical pixels, 2x at and above.
/// Mirrors the platform reality that one multiplication factor is not enough.
///
/// [textScaleFactor] reports the small-text factor; [scale] is the source of
/// truth used by text rendering, which is intentionally nonlinear here.
class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double get textScaleFactor => 1.2;

  @override
  double scale(double fontSize) =>
      fontSize < 20 ? fontSize * 1.2 : fontSize * 2.0;

  @override
  TextScaler clamp({double? minScaleFactor, double? maxScaleFactor}) => this;

  @override
  bool operator ==(Object other) => other is _NonlinearScaler;

  @override
  int get hashCode => 7;
}

void main() {
  group('TextScaler is applied exactly once', () {
    testWidgets('framework hands declared sizes to text rendering', (
      tester,
    ) async {
      late TextStyle style;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light(
            // Root 18: body declares 18 logical pixels.
          ).copyWith(metrics: const FwMetrics(rootSize: 18)).toThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Builder(
              builder: (context) {
                style = context.fwTheme.typeScale.resolve(
                  FwTextRole.body,
                  context,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      // Declared size only — never pre-scaled by the framework. Flutter's
      // text system applies the 1.5x scaler exactly once at render time.
      expect(style.fontSize, 18);
    });

    test('linear example from the spec: declared 18 renders at 27', () {
      const scaler = TextScaler.linear(1.5);
      expect(scaler.scale(18), 27);
      // Not 40.5: pre-scaling and then scaling again would double-apply.
      expect(scaler.scale(scaler.scale(18)), 40.5);
    });

    test('rendered text honors a nonlinear scaler exactly once', () {
      const scaler = _NonlinearScaler();
      const declared = TextStyle(fontSize: 18, height: 1.5);
      final scaled = TextPainter(
        text: const TextSpan(text: 'Ag', style: declared),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final plain = TextPainter(
        text: const TextSpan(text: 'Ag', style: declared),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      // Rendered ratio matches scaler.scale(18) / 18 = 1.2, proving Flutter
      // scaled the declared size once — not zero times, not twice.
      expect(
        scaled.size.height / plain.size.height,
        moreOrLessEquals(scaler.scale(18) / 18, epsilon: 0.05),
      );
    });

    testWidgets('spacing never multiplies by the text scaler', (tester) async {
      late double spacing;
      late double token;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Builder(
              builder: (context) {
                spacing = FwRem(1).resolve(context);
                token = const FwSpaceScale().of(FwSpace.s4, context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(spacing, 16);
      expect(token, 16);
    });
  });

  group('large text layout without clipping', () {
    testWidgets('long labels wrap without clipping at 2x text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  // Enlarged content scrolls instead of clipping: no fixed
                  // label heights, no forced truncation of essential text.
                  child: SingleChildScrollView(
                    child: FwContainerQuery(
                      child: Column(
                        children: [
                          Builder(
                            builder: (context) => Text(
                              'Enlarged heading specimen',
                              style: context.fwTheme.typeScale.resolve(
                                FwTextRole.h1,
                                context,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'A card whose text containers grow through '
                                'content-driven height and wrapping instead of '
                                'fixed label heights or forced truncation.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Flutter reports clipping/overflow as exceptions in tests.
      expect(tester.takeException(), isNull);
    });
  });
}
