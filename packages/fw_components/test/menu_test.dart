import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  group('FwDrawer', () {
    testWidgets('opens, shows slots, scrim tap closes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: FwViewportQuery(
              child: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    child: const Text('Menu'),
                  ),
                ),
              ),
            ),
            drawer: const FwDrawer(
              header: Text('Acme'),
              content: Text('Nav items'),
              footer: Text('v1.0'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Acme'), findsOneWidget);
      expect(find.text('Nav items'), findsOneWidget);
      expect(find.text('v1.0'), findsOneWidget);
      // Scrim tap closes.
      await tester.tapAt(const Offset(700, 300));
      await tester.pumpAndSettle();
      expect(find.text('Nav items'), findsNothing);
    });

    testWidgets('endDrawer opens from the end side', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: FwViewportQuery(
              child: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    child: const Text('Filters'),
                  ),
                ),
              ),
            ),
            endDrawer: const FwDrawer(content: Text('Filter panel')),
          ),
        ),
      );
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      final drawerBox = tester.getRect(find.text('Filter panel'));
      // End drawer hugs the right edge.
      expect(drawerBox.right, greaterThan(700));
    });
  });

  group('FwPopover', () {
    testWidgets('toggle shows and hides content', (tester) async {
      final controller = FwPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          FwPopover(
            controller: controller,
            anchor: TextButton(
              onPressed: controller.toggle,
              child: const Text('Info'),
            ),
            content: const Text('Details here'),
          ),
        ),
      );
      expect(find.text('Details here'), findsNothing);
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();
      expect(find.text('Details here'), findsOneWidget);
      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();
      expect(find.text('Details here'), findsNothing);
    });

    testWidgets('tap outside dismisses', (tester) async {
      final controller = FwPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          FwPopover(
            controller: controller,
            anchor: TextButton(
              onPressed: controller.toggle,
              child: const Text('Info'),
            ),
            content: const Text('Details here'),
          ),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Details here'), findsOneWidget);
      await tester.tapAt(const Offset(10, 590));
      await tester.pumpAndSettle();
      expect(find.text('Details here'), findsNothing);
      expect(controller.isShowing, isFalse);
    });

    testWidgets('Escape dismisses', (tester) async {
      final controller = FwPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          FwPopover(
            controller: controller,
            anchor: TextButton(
              onPressed: controller.toggle,
              child: const Text('Info'),
            ),
            content: const Text('Details here'),
          ),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Details here'), findsNothing);
    });

    testWidgets('start placement is RTL-aware', (tester) async {
      for (final direction in TextDirection.values) {
        final controller = FwPopoverController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: FwTheme.light().toThemeData(),
            home: Scaffold(
              body: FwViewportQuery(
                child: Directionality(
                  textDirection: direction,
                  child: Center(
                    child: FwPopover(
                      controller: controller,
                      placement: FwPopoverPlacement.start,
                      anchor: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Text('A'),
                      ),
                      content: const SizedBox(
                        width: 120,
                        height: 40,
                        child: Text('Details'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        controller.show();
        await tester.pumpAndSettle();
        final anchorX = tester.getCenter(find.text('A')).dx;
        final contentX = tester.getCenter(find.text('Details')).dx;
        if (direction == TextDirection.ltr) {
          expect(contentX, lessThan(anchorX));
        } else {
          expect(contentX, greaterThan(anchorX));
        }
      }
    });

    testWidgets('overflowing bottom placement flips to top', (tester) async {
      final controller = FwPopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          // Anchor pinned to the bottom edge: no room below.
          Align(
            alignment: Alignment.bottomCenter,
            child: FwPopover(
              controller: controller,
              placement: FwPopoverPlacement.bottom,
              anchor: const SizedBox(width: 40, height: 40, child: Text('A')),
              content: const SizedBox(
                width: 120,
                height: 120,
                child: Text('Details'),
              ),
            ),
          ),
        ),
      );
      controller.show();
      await tester.pumpAndSettle();
      final anchorY = tester.getCenter(find.text('A')).dy;
      final contentY = tester.getCenter(find.text('Details')).dy;
      expect(contentY, lessThan(anchorY));
    });
  });

  group('FwMenu', () {
    List<FwMenuEntry<String>> entries() => const [
      FwMenuLabel('File'),
      FwMenuAction(value: 'new', label: 'New'),
      FwMenuAction(value: 'open', label: 'Open', checked: true),
      FwMenuSeparator(),
      FwMenuAction(value: 'exit', label: 'Exit', enabled: false),
      FwMenuSubmenu(
        label: 'More',
        children: [FwMenuAction(value: 'about', label: 'About')],
      ),
    ];

    testWidgets('selecting an item reports its typed value', (tester) async {
      String? selected;
      await tester.pumpWidget(
        host(
          FwMenu<String>(
            entries: entries(),
            onSelected: (v) => selected = v,
            trigger: (context, controller) => TextButton(
              onPressed: controller.open,
              child: const Text('Open menu'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      expect(find.text('File'), findsOneWidget); // group label
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(selected, 'open');
      expect(find.text('New'), findsNothing); // menu closed
    });

    testWidgets('disabled item cannot be selected', (tester) async {
      String? selected;
      await tester.pumpWidget(
        host(
          FwMenu<String>(
            entries: entries(),
            onSelected: (v) => selected = v,
            trigger: (context, controller) => TextButton(
              onPressed: controller.open,
              child: const Text('Open menu'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exit'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, isNull);
    });

    testWidgets('checked item shows a check mark', (tester) async {
      await tester.pumpWidget(
        host(
          FwMenu<String>(
            entries: entries(),
            onSelected: (_) {},
            trigger: (context, controller) => TextButton(
              onPressed: controller.open,
              child: const Text('Open menu'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Escape closes the menu and restores focus', (tester) async {
      await tester.pumpWidget(
        host(
          FwMenu<String>(
            entries: entries(),
            onSelected: (_) {},
            trigger: (context, controller) => TextButton(
              onPressed: controller.open,
              child: const Text('Open menu'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      // Keyboard flow: focus moves into the menu, then Escape dismisses.
      Focus.of(tester.element(find.text('New'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('New'), findsNothing);
      // Focus returns to the trigger.
      expect(Focus.of(tester.element(find.text('Open menu'))).hasFocus, isTrue);
    });
  });

  group('FwContextMenuRegion', () {
    testWidgets('secondary click opens the menu at the pointer', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        host(
          FwContextMenuRegion<String>(
            entries: const [
              FwMenuAction(value: 'cut', label: 'Cut'),
              FwMenuAction(value: 'copy', label: 'Copy'),
            ],
            onSelected: (v) => selected = v,
            child: const SizedBox(width: 200, height: 200, child: Text('File')),
          ),
        ),
      );
      await tester.tap(find.text('File'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(selected, 'copy');
    });

    testWidgets('long-press opens the menu (touch alternative)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FwContextMenuRegion<String>(
            entries: const [FwMenuAction(value: 'cut', label: 'Cut')],
            onSelected: (_) {},
            child: const SizedBox(width: 200, height: 200, child: Text('File')),
          ),
        ),
      );
      await tester.longPress(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
    });

    testWidgets('keyboard Menu key opens the menu', (tester) async {
      await tester.pumpWidget(
        host(
          FwContextMenuRegion<String>(
            entries: const [FwMenuAction(value: 'cut', label: 'Cut')],
            onSelected: (_) {},
            child: const SizedBox(width: 200, height: 200, child: Text('File')),
          ),
        ),
      );
      await tester.tap(find.text('File')); // focuses the region
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
    });
  });
}
