import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

Future<TestGesture> hoverAt(WidgetTester tester, Offset location) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: location);
  return gesture;
}

void main() {
  group('FwHoverCard', () {
    testWidgets('card is hidden initially', (tester) async {
      await tester.pumpWidget(
        host(
          const FwHoverCard(
            anchor: Text('anchor'),
            content: Text('card content'),
          ),
        ),
      );
      expect(find.text('card content'), findsNothing);
    });

    testWidgets('hovering the anchor shows the card after the delay', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwHoverCard(
            anchor: Text('anchor'),
            content: Text('card content'),
            showDelay: Duration(milliseconds: 300),
          ),
        ),
      );
      final gesture = await hoverAt(tester, Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('anchor')));
      await tester.pump();
      expect(find.text('card content'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('card content'), findsOneWidget);
      await gesture.removePointer();
    });

    testWidgets('leaving the anchor hides the card after the delay', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwHoverCard(
            anchor: Text('anchor'),
            content: Text('card content'),
            showDelay: Duration.zero,
            hideDelay: Duration(milliseconds: 150),
          ),
        ),
      );
      final gesture = await hoverAt(tester, Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('anchor')));
      await tester.pump();
      expect(find.text('card content'), findsOneWidget);
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text('card content'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('card content'), findsNothing);
      await gesture.removePointer();
    });

    testWidgets('keyboard focus shows the card immediately', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          FwHoverCard(
            focusNode: node,
            anchor: const Text('anchor'),
            content: const Text('card content'),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(find.text('card content'), findsOneWidget);
      // Clean up focus so the next test starts from a neutral state.
      node.unfocus();
      await tester.pump();
    });

    testWidgets('losing focus hides the card', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          FwHoverCard(
            focusNode: node,
            anchor: const Text('anchor'),
            content: const Text('card content'),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(find.text('card content'), findsOneWidget);
      node.unfocus();
      // Two pumps: one for the focus change, one for the portal teardown.
      await tester.pump();
      await tester.pump();
      expect(find.text('card content'), findsNothing);
    });

    testWidgets('moving onto the card keeps it open (WCAG hoverable)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwHoverCard(
            anchor: Text('anchor'),
            content: Text('card content'),
            showDelay: Duration.zero,
            hideDelay: Duration(milliseconds: 150),
          ),
        ),
      );
      final gesture = await hoverAt(tester, Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('anchor')));
      await tester.pump();
      expect(find.text('card content'), findsOneWidget);
      // Move from the anchor onto the card itself.
      await gesture.moveTo(tester.getCenter(find.text('card content')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('card content'), findsOneWidget);
      await gesture.removePointer();
    });

    testWidgets('renders at the top placement without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwHoverCard(
            anchor: Text('anchor'),
            content: Text('card content'),
            placement: FwPopoverPlacement.top,
            showDelay: Duration.zero,
          ),
        ),
      );
      final gesture = await hoverAt(tester, Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('anchor')));
      await tester.pump();
      expect(find.text('card content'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await gesture.removePointer();
    });

    testWidgets('accepts elevation and tonal options', (tester) async {
      await tester.pumpWidget(
        host(
          const FwHoverCard(
            anchor: Text('anchor'),
            content: Text('card content'),
            elevation: 5,
            tonal: false,
            showDelay: Duration.zero,
          ),
        ),
      );
      final gesture = await hoverAt(tester, Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('anchor')));
      await tester.pump();
      expect(find.text('card content'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await gesture.removePointer();
    });

    testWidgets('timers are cancelled on dispose without errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwHoverCard(
            anchor: Text('anchor'),
            content: Text('card content'),
          ),
        ),
      );
      final gesture = await hoverAt(tester, Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('anchor')));
      await tester.pumpWidget(host(const Text('gone')));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await gesture.removePointer();
    });
  });
}
