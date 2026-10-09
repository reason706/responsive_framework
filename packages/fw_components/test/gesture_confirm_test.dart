import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

class FakeClipboard extends FwClipboard {
  String? lastText;
  bool shouldThrow = false;

  @override
  Future<void> setText(String text) async {
    if (shouldThrow) throw StateError('denied');
    lastText = text;
  }
}

void main() {
  group('FwCopyAction', () {
    testWidgets('copies text and shows bounded copied feedback', (
      tester,
    ) async {
      final clipboard = FakeClipboard();
      await tester.pumpWidget(
        host(
          FwCopyAction(
            text: 'secret-code',
            clipboard: clipboard,
            feedbackDuration: const Duration(milliseconds: 50),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();
      expect(clipboard.lastText, 'secret-code');
      // Feedback is exposed through the tooltip (the accessible name).
      expect(find.byTooltip('Copied'), findsOneWidget);
      // Feedback reverts after the bounded duration.
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byTooltip('Copy'), findsOneWidget);
    });

    testWidgets('clipboard failure shows error, never logs the text', (
      tester,
    ) async {
      final clipboard = FakeClipboard()..shouldThrow = true;
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwCopyAction(
              text: 'secret-code',
              clipboard: clipboard,
              feedbackDuration: const Duration(milliseconds: 50),
            ),
          ),
        );
        await tester.tap(find.byTooltip('Copy'));
        await tester.pump();
        await tester.pump();
        // Error status is announced through the live region...
        final semantics = tester.getSemantics(find.byType(FwCopyAction));
        expect(semantics.label, 'Copy failed');
        // ...while the secret itself never appears in the widget tree.
        expect(find.text('secret-code'), findsNothing);
        await tester.pump(const Duration(milliseconds: 60));
      } finally {
        handle.dispose();
      }
    });
  });

  group('FwSlideToConfirm', () {
    testWidgets('drag past threshold confirms; partial drag snaps back', (
      tester,
    ) async {
      var confirmed = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: FwSlideToConfirm(onConfirm: () => confirmed++),
          ),
        ),
      );
      // Partial drag: no confirm, thumb returns.
      await tester.drag(
        find.byKey(const ValueKey('fw-slide-thumb')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmed, 0);

      // Full drag past the 0.85 threshold confirms.
      await tester.drag(
        find.byKey(const ValueKey('fw-slide-thumb')),
        const Offset(300, 0),
      );
      await tester.pump();
      await tester.pump();
      expect(confirmed, 1);
      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('fallback button is the non-gesture path', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: FwSlideToConfirm(
              onConfirm: () => confirmed++,
              fallbackLabel: 'Confirm payment',
            ),
          ),
        ),
      );
      await tester.tap(find.text('Confirm payment'));
      await tester.pump();
      await tester.pump();
      expect(confirmed, 1);
    });

    testWidgets('RTL drags right-to-left', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: FwSlideToConfirm(onConfirm: () => confirmed++),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.drag(
        find.byKey(const ValueKey('fw-slide-thumb')),
        const Offset(-300, 0),
      );
      await tester.pump();
      await tester.pump();
      expect(confirmed, 1);
    });

    testWidgets('async failure shows failure state, not success', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: FwSlideToConfirm(
              onConfirm: () => throw StateError('declined'),
            ),
          ),
        ),
      );
      await tester.drag(
        find.byKey(const ValueKey('fw-slide-thumb')),
        const Offset(300, 0),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Failed — try again'), findsOneWidget);
    });
  });

  group('FwHoldToConfirm', () {
    testWidgets('holding for the duration confirms; early release cancels', (
      tester,
    ) async {
      var confirmed = 0;
      await tester.pumpWidget(
        host(
          FwHoldToConfirm(
            onConfirm: () => confirmed++,
            holdDuration: const Duration(milliseconds: 400),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(FwHoldToConfirm));
      // Early release: no confirm.
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pump();
      expect(confirmed, 0);

      // Full hold: confirms. The zero-duration pump anchors the ticker's
      // start time; without it the first timed pump's duration is lost.
      final gesture2 = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await gesture2.up();
      await tester.pump();
      expect(confirmed, 1);
    });

    testWidgets('fallback button confirms without the gesture', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        host(
          FwHoldToConfirm(
            onConfirm: () => confirmed++,
            fallbackLabel: 'Delete now',
          ),
        ),
      );
      await tester.tap(find.text('Delete now'));
      await tester.pump();
      expect(confirmed, 1);
    });

    testWidgets('reduced motion: a tap confirms immediately', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: FwHoldToConfirm(onConfirm: () => confirmed++),
          ),
        ),
      );
      await tester.tap(find.byType(FwHoldToConfirm));
      await tester.pump();
      expect(confirmed, 1);
    });
  });
}
