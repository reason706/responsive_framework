import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('DS-11 typed-token migration', () {
    testWidgets('button control padding is root-relative', (tester) async {
      await tester.pumpWidget(
        host(
          const FwButton(label: 'Save', onPressed: null),
          theme: FwTheme.light().copyWith(
            metrics: const FwMetrics(rootSize: 20),
          ),
        ),
      );
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      final padding = style.padding!
          .resolve(<WidgetState>{})!
          .resolve(TextDirection.ltr);
      // controlInline = 1rem, controlBlock = 0.5rem at root 20.
      expect(padding.left, 20);
      expect(padding.top, 10);
    });

    testWidgets('compact density shrinks padding, not the touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwButton(label: 'Save', onPressed: null),
          theme: FwTheme.light(density: FwDensity.compact),
        ),
      );
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      final padding = style.padding!
          .resolve(<WidgetState>{})!
          .resolve(TextDirection.ltr);
      // 16 * 0.875 compact gap scale.
      expect(padding.left, 14);
      final size = style.minimumSize!.resolve(<WidgetState>{})!;
      expect(size.width, 48);
      expect(size.height, 48);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('button focus ring uses the focus role', (tester) async {
      await tester.pumpWidget(
        host(const FwButton(label: 'Save', onPressed: null)),
      );
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      final side = style.side!.resolve({WidgetState.focused})!;
      expect(side.color, FwTheme.light().colors.of(FwColorRole.focusRing));
      expect(side.width, 2);
    });

    testWidgets('card uses semantic surface, border, and body roles', (
      tester,
    ) async {
      late BoxDecoration expected;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              // P3.1: elevated cards consume the level-1 token (tint + shadow).
              expected = const FwElevation().decoration(
                context,
                1,
                color: context.fwTheme.colors.of(FwColorRole.surface),
              );
              return const FwCard(content: Text('content'));
            },
          ),
          theme: FwTheme.light().copyWith(
            metrics: const FwMetrics(rootSize: 20),
          ),
        ),
      );
      final decoration =
          tester
                  .widgetList<Container>(
                    find.descendant(
                      of: find.byType(FwCard),
                      matching: find.byType(Container),
                    ),
                  )
                  .firstWhere((c) => c.decoration is BoxDecoration)
                  .decoration!
              as BoxDecoration;
      // Elevated (default): level-1 tint over the surface fill, resting
      // shadow, no border.
      expect(decoration.color, expected.color);
      expect(decoration.boxShadow, expected.boxShadow);
      expect(decoration.border, isNull);
      // Card inset is root-relative: 1rem at root 20.
      // (Container renders an internal zero Padding; select the inset.)
      final padding = tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byType(FwCard),
              matching: find.byType(Padding),
            ),
          )
          .map((w) => w.padding.resolve(TextDirection.ltr))
          .firstWhere((p) => p != EdgeInsets.zero);
      expect(padding.left, 20);
    });
  });
}
