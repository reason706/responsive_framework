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
  group('E5a timeline', () {
    testWidgets('renders events in order with times', (tester) async {
      await tester.pumpWidget(
        host(
          const FwTimeline(
            events: [
              FwTimelineEvent(
                title: 'Shipped',
                timeLabel: '10:00',
                description: 'v1.0 is live',
              ),
              FwTimelineEvent(title: 'Review', timeLabel: '09:00'),
            ],
          ),
        ),
      );
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('v1.0 is live'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      // Order: Shipped above Review.
      final shippedDy = tester.getCenter(find.text('Shipped')).dy;
      final reviewDy = tester.getCenter(find.text('Review')).dy;
      expect(shippedDy, lessThan(reviewDy));
    });

    testWidgets('icon and intent tint the dot', (tester) async {
      await tester.pumpWidget(
        host(
          const FwTimeline(
            events: [
              FwTimelineEvent(
                title: 'Alert',
                icon: Icons.warning,
                intent: FwIntent.warning,
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('E5a tour controller', () {
    FwTourController controller() => FwTourController(
      steps: [
        FwTourStep(targetKey: GlobalKey(), title: 'One', description: 'First'),
        FwTourStep(targetKey: GlobalKey(), title: 'Two', description: 'Second'),
      ],
    );

    test('step machine walks and finishes', () {
      final c = controller();
      expect(c.isActive, isFalse);
      c.start();
      expect(c.isActive, isTrue);
      expect(c.index, 0);
      c.next();
      expect(c.index, 1);
      expect(c.isLast, isTrue);
      c.next(); // finishes
      expect(c.isActive, isFalse);
    });

    test('previous walks back; stop idles', () {
      final c = controller();
      c.start();
      c.next();
      c.previous();
      expect(c.index, 0);
      c.stop();
      expect(c.isActive, isFalse);
    });

    testWidgets('overlay shows the step card and advances', (tester) async {
      final target = GlobalKey();
      final c = FwTourController(
        steps: [
          FwTourStep(targetKey: target, title: 'One', description: 'First'),
          FwTourStep(
            targetKey: GlobalKey(),
            title: 'Two',
            description: 'Second',
          ),
        ],
      );
      await tester.pumpWidget(
        host(
          FwTour(
            controller: c,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Target', key: target),
                const Text('Other'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('First'), findsNothing);
      c.start();
      await tester.pump();
      expect(find.text('First'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Second'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(c.isActive, isFalse);
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('Skip ends the tour', (tester) async {
      final c = controller();
      await tester.pumpWidget(
        host(FwTour(controller: c, child: const Text('App'))),
      );
      c.start();
      await tester.pump();
      expect(find.text('First'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(c.isActive, isFalse);
    });
  });

  group('E5a reorderable list', () {
    testWidgets('drag reorders via the callback', (tester) async {
      final items = ['A', 'B', 'C'];
      var moved = <int>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 400,
            child: FwReorderableList<String>(
              items: items,
              itemBuilder: (context, item) => ListTile(title: Text(item)),
              onReorder: (oldIndex, newIndex) => moved = [oldIndex, newIndex],
            ),
          ),
        ),
      );
      // Drag the first handle down past the second item.
      final handle = find.byIcon(Icons.drag_handle).first;
      await tester.drag(handle, const Offset(0, 120));
      await tester.pump();
      expect(moved, isNotEmpty);
      expect(moved[0], 0);
    });
  });

  group('E5a sticky headers', () {
    testWidgets('headers pin while content scrolls', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 300,
            child: FwStickyList(
              sections: [
                FwStickySection(
                  header: const Text('Section A'),
                  children: [for (var i = 0; i < 10; i++) Text('A item $i')],
                ),
                FwStickySection(
                  header: const Text('Section B'),
                  children: [for (var i = 0; i < 10; i++) Text('B item $i')],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Section B'), findsOneWidget);

      // Scroll down: Section A's header stays pinned at the top.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      expect(find.text('Section A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
