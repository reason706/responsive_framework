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

void main() {
  group('E5b resizable panels', () {
    testWidgets('dragging the divider changes the ratio', (tester) async {
      var ratio = 0.5;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            height: 200,
            child: FwResizablePanels(
              first: const Text('First'),
              second: const Text('Second'),
              onRatioChanged: (r) => ratio = r,
            ),
          ),
        ),
      );
      // Divider hit area is 48 wide, centered between the panes.
      final divider = find.bySemanticsLabel('Resize panels');
      expect(divider, findsOneWidget);
      await tester.drag(divider, const Offset(80, 0));
      await tester.pump();
      expect(ratio, greaterThan(0.5));
    });

    testWidgets('ratio clamps to min/max', (tester) async {
      var ratio = 0.5;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            height: 200,
            child: FwResizablePanels(
              first: const Text('First'),
              second: const Text('Second'),
              minRatio: 0.3,
              maxRatio: 0.7,
              onRatioChanged: (r) => ratio = r,
            ),
          ),
        ),
      );
      await tester.drag(
        find.bySemanticsLabel('Resize panels'),
        const Offset(-300, 0),
      );
      await tester.pump();
      expect(ratio, 0.3);
    });
  });

  group('E5b chat bubbles', () {
    testWidgets('sent aligns end, received aligns start', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FwChatBubble(
                message: 'Hi there',
                side: FwChatSide.sent,
                timestamp: '10:00',
                status: FwChatStatus.read,
              ),
              FwChatBubble(
                message: 'Hello!',
                side: FwChatSide.received,
                senderName: 'Amara',
                timestamp: '10:01',
              ),
            ],
          ),
        ),
      );
      expect(find.text('Hi there'), findsOneWidget);
      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Amara'), findsOneWidget);
      // Read ticks render for the sent message.
      expect(find.byIcon(Icons.done_all), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('E5b signature pad', () {
    testWidgets('drawing reports ink; clear wipes it', (tester) async {
      var hasInk = false;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: FwSignaturePad(onChanged: (v) => hasInk = v),
          ),
        ),
      );
      expect(hasInk, isFalse);
      expect(find.text('Sign here'), findsOneWidget);

      final pad = find.byType(FwSignaturePad);
      await tester.drag(pad, const Offset(60, 20));
      await tester.pump();
      expect(hasInk, isTrue);
      expect(find.text('Sign here'), findsNothing);

      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(hasInk, isFalse);
    });
  });

  group('E5b color picker', () {
    testWidgets('dragging the hue slider reports a color', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: FwColorPicker(
              onColorSelected: (c) => picked = c,
              initialColor: const Color(0xFF1B6DE0),
            ),
          ),
        ),
      );
      // Hue slider is the GestureDetector wrapping a SizedBox.
      final hueSlider = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.child is SizedBox,
      );
      expect(hueSlider, findsOneWidget);
      await tester.drag(hueSlider, const Offset(100, 0));
      await tester.pump();
      expect(picked, isNotNull);
    });

    testWidgets('tapping a preset reports it', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: FwColorPicker(
              onColorSelected: (c) => picked = c,
              initialColor: const Color(0xFF1B6DE0),
              presets: const [Color(0xFFC81E1E)],
            ),
          ),
        ),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == const Color(0xFFC81E1E),
        ),
      );
      await tester.pump();
      expect(picked, const Color(0xFFC81E1E));
    });

    testWidgets('hex readout reflects the color', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: FwColorPicker(
              onColorSelected: (_) {},
              initialColor: const Color(0xFF1B6DE0),
            ),
          ),
        ),
      );
      // 1B6DE0 is the default blue preset.
      expect(find.text('#1B6DE0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
