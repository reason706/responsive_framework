import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

/// Finds the first Container whose decoration is a BoxDecoration.
BoxDecoration cardDecoration(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere((c) => c.decoration is BoxDecoration);
  return container.decoration! as BoxDecoration;
}

void main() {
  group('P3.1 elevation defaults (M3)', () {
    testWidgets('FwCard elevated defaults to level 1 with tint', (
      tester,
    ) async {
      late BoxDecoration expected;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              expected = const FwElevation().decoration(context, 1);
              return const FwCard(content: Text('hi'));
            },
          ),
        ),
      );
      final actual = cardDecoration(tester);
      expect(actual.boxShadow, expected.boxShadow);
      expect(actual.color, expected.color);
    });

    testWidgets('FwCard outlined/filled default to level 0', (tester) async {
      for (final variant in [FwCardVariant.outlined, FwCardVariant.filled]) {
        await tester.pumpWidget(
          host(FwCard(variant: variant, content: const Text('hi'))),
        );
        final actual = cardDecoration(tester);
        expect(actual.boxShadow, isEmpty, reason: '$variant');
      }
    });

    testWidgets('FwCard honors explicit elevation and tonal:false', (
      tester,
    ) async {
      late BoxDecoration tinted;
      late BoxDecoration flat;
      late Color surface;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              tinted = const FwElevation().decoration(context, 4);
              flat = const FwElevation().decoration(context, 4, tonal: false);
              surface = context.fwTheme.colors.of(FwColorRole.surface);
              return const FwCard(elevation: 4, content: Text('hi'));
            },
          ),
        ),
      );
      expect(cardDecoration(tester).boxShadow, tinted.boxShadow);
      // Level 4 maps to the lg shadow preset.
      expect(tinted.boxShadow, isNotEmpty);

      await tester.pumpWidget(
        host(const FwCard(elevation: 4, tonal: false, content: Text('hi'))),
      );
      final actual = cardDecoration(tester);
      expect(actual.boxShadow, flat.boxShadow);
      expect(actual.color, surface); // no tint blended
    });

    testWidgets('FwDialog defaults to level 3', (tester) async {
      late BoxDecoration expected;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              expected = const FwElevation().decoration(context, 3);
              return const FwDialog(content: Text('body'));
            },
          ),
        ),
      );
      expect(cardDecoration(tester).boxShadow, expected.boxShadow);
    });

    testWidgets('FwDialog honors explicit elevation', (tester) async {
      await tester.pumpWidget(
        host(const FwDialog(content: Text('body'), elevation: 0)),
      );
      expect(cardDecoration(tester).boxShadow, isEmpty);
    });

    testWidgets('FwSheet defaults to level 1 (M3)', (tester) async {
      late BoxDecoration expected;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              expected = const FwElevation().decoration(context, 1);
              return FwSheet(content: const Text('sheet'));
            },
          ),
        ),
      );
      expect(cardDecoration(tester).boxShadow, expected.boxShadow);
    });

    test('surface prop defaults match the M3 table', () {
      expect(const FwToastHost(child: SizedBox()).elevation, 3);
      expect(
        FwPopover(
          controller: FwPopoverController(),
          anchor: const SizedBox(),
          content: const SizedBox(),
        ).elevation,
        3,
      );
      expect(
        const FwMenu<String>(
          entries: [],
          onSelected: _noop,
          trigger: _trigger,
        ).elevation,
        3,
      );
      expect(const FwDrawer(content: SizedBox()).elevation, 1);
      expect(const FwFab(onPressed: null, icon: Icon(Icons.add)).elevation, 3);
      expect(const FwDialog(content: Text('x')).elevation, 3);
      expect(FwSheet(content: const Text('x')).elevation, 1);
    });

    testWidgets('FwDrawer maps elevation onto the native drawer', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FwDrawer(content: Text('nav'))));
      expect(tester.widget<Drawer>(find.byType(Drawer)).elevation, 1.0);
    });

    testWidgets('FwFab maps elevation onto the button style', (tester) async {
      await tester.pumpWidget(
        host(const FwFab(onPressed: null, icon: Icon(Icons.add))),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style!.elevation!.resolve({}), 3.0);
    });

    test('out-of-range elevation asserts', () {
      expect(
        () => FwCard(elevation: 6, content: const Text('x')),
        throwsAssertionError,
      );
      expect(
        () => FwDialog(content: const Text('x'), elevation: -1),
        throwsAssertionError,
      );
    });
  });
}

void _noop(String _) {}

Widget _trigger(BuildContext context, MenuController controller) =>
    const SizedBox();
