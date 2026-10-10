import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
  group('FwDialog', () {
    test('size max widths are documented and ordered', () {
      expect(FwDialogSize.sm.maxWidth, 320);
      expect(FwDialogSize.md.maxWidth, 480);
      expect(FwDialogSize.lg.maxWidth, 640);
      expect(FwDialogSize.sm.maxWidth < FwDialogSize.md.maxWidth, isTrue);
      expect(FwDialogSize.md.maxWidth < FwDialogSize.lg.maxWidth, isTrue);
    });

    testWidgets('close returns value with action reason', (tester) async {
      FwOverlayResult<String>? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FwDialog.show<String>(
                  context: context,
                  title: const Text('Delete file?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    Builder(
                      builder: (context) => ElevatedButton(
                        onPressed: () => FwDialog.close(context, 'deleted'),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete file?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.value, 'deleted');
      expect(result!.reason, FwDismissReason.action);
    });

    testWidgets('barrier tap dismisses with barrier reason', (tester) async {
      FwOverlayResult<String>? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FwDialog.show<String>(
                  context: context,
                  title: const Text('Title'),
                  content: const Text('Body'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Tap the barrier: top-left corner, outside the centered card.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsNothing);
      expect(result, isNotNull);
      expect(result!.value, isNull);
      expect(result!.reason, FwDismissReason.barrier);
    });

    testWidgets('barrierDismissible false keeps the dialog open', (
      tester,
    ) async {
      var completed = false;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await FwDialog.show<String>(
                  context: context,
                  title: const Text('Locked'),
                  content: const Text('Body'),
                  barrierDismissible: false,
                );
                completed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Locked'), findsOneWidget);
      expect(completed, isFalse);
    });

    testWidgets('Escape dismisses with systemBack reason', (tester) async {
      FwOverlayResult<String>? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FwDialog.show<String>(
                  context: context,
                  title: const Text('Title'),
                  content: const Text('Body'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsNothing);
      expect(result, isNotNull);
      expect(result!.reason, FwDismissReason.systemBack);
    });

    testWidgets('dialog route is labelled for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FwDialog.show<String>(
                  context: context,
                  title: const Text('Title'),
                  content: const Text('Body'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Walk up from the title's semantics node to the labelled route.
      var node = tester.getSemantics(find.text('Title'));
      var found = false;
      SemanticsNode? current = node;
      while (current != null && !found) {
        found =
            current.flagsCollection.scopesRoute &&
            current.flagsCollection.namesRoute;
        current = current.parent;
      }
      expect(found, isTrue);
      semantics.dispose();
    });

    testWidgets('actions wrap instead of overflowing narrow widths', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FwDialog.show<String>(
                  context: context,
                  title: const Text('Title'),
                  content: const Text('Body'),
                  actions: [
                    for (var i = 0; i < 6; i++)
                      FwButton(
                        label: 'Very long action label $i',
                        onPressed: () {},
                      ),
                  ],
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // No RenderFlex overflow may be logged during layout.
      expect(tester.takeException(), isNull);
    });
  });

  group('FwConfirmDialog', () {
    testWidgets('confirm returns true, cancel returns false', (tester) async {
      FwOverlayResult<bool>? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FwConfirmDialog.show(
                  context: context,
                  title: 'Delete project?',
                  message: 'All data will be lost.',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete project?'), findsOneWidget);
      expect(find.text('All data will be lost.'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result!.value, isTrue);
      expect(result!.reason, FwDismissReason.action);
    });

    testWidgets('destructive confirm uses danger intent', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FwConfirmDialog.show(
                  context: context,
                  title: 'Delete?',
                  destructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final button = tester.widget<FwButton>(
        find.widgetWithText(FwButton, 'Confirm'),
      );
      expect(button.intent, FwIntent.danger);
    });

    testWidgets('busy locks barrier dismissal until resolved', (tester) async {
      final busy = ValueNotifier<bool>(true);
      addTearDown(busy.dispose);
      FwOverlayResult<bool>? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FwConfirmDialog.show(
                  context: context,
                  title: 'Working',
                  busy: busy,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      // The busy spinner is indeterminate, so settle is impossible while
      // busy — a pump is enough for the dialog to appear.
      await tester.pump();
      // Barrier tap is ignored while busy.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(find.text('Working'), findsOneWidget);
      expect(result, isNull);
      // Resolve the operation; the confirm button completes the flow.
      busy.value = false;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result!.value, isTrue);
    });
  });

  group('FwSheet', () {
    testWidgets('modal sheet shows drag handle, title, content', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FwSheet.showModal<String>(
                  context: context,
                  title: const Text('Share'),
                  content: const Text('Sheet body'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Sheet body'), findsOneWidget);
      expect(find.bySemanticsLabel('Drag handle'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('barrier tap dismisses the sheet', (tester) async {
      FwOverlayResult<String>? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FwSheet.showModal<String>(
                  context: context,
                  content: const Text('Sheet body'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(400, 40));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsNothing);
      expect(result, isNotNull);
      expect(result!.reason, FwDismissReason.barrier);
    });

    testWidgets('sheet content sits above the software keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FwSheet.showModal<String>(
                  context: context,
                  content: const TextField(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // The text field must not be hidden behind the keyboard inset.
      final fieldBox = tester.getRect(find.byType(TextField).last);
      expect(fieldBox.bottom <= 600 - 300, isTrue);
    });
  });
}
