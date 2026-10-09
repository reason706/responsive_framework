import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('E2 button icon placement', () {
    testWidgets('icon at start renders before the label in LTR', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Save',
            icon: Icon(Icons.save),
            onPressed: null,
          ),
        ),
      );
      final iconLeft = tester.getTopLeft(find.byIcon(Icons.save)).dx;
      final labelLeft = tester.getTopLeft(find.text('Save')).dx;
      expect(iconLeft, lessThan(labelLeft));
    });

    testWidgets('icon at end renders after the label in LTR', (tester) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Save',
            icon: Icon(Icons.save),
            iconPosition: FwIconPosition.end,
            onPressed: null,
          ),
        ),
      );
      final iconLeft = tester.getTopLeft(find.byIcon(Icons.save)).dx;
      final labelLeft = tester.getTopLeft(find.text('Save')).dx;
      expect(iconLeft, greaterThan(labelLeft));
    });

    testWidgets('start/end flip in RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: FwButton(
                  label: 'Save',
                  icon: Icon(Icons.save),
                  onPressed: null,
                ),
              ),
            ),
          ),
        ),
      );
      // "start" in RTL is the right side: icon right of label.
      final iconLeft = tester.getTopLeft(find.byIcon(Icons.save)).dx;
      final labelLeft = tester.getTopLeft(find.text('Save')).dx;
      expect(iconLeft, greaterThan(labelLeft));
    });

    testWidgets('icon on top stacks above the label', (tester) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Save',
            icon: Icon(Icons.save),
            iconPosition: FwIconPosition.top,
            onPressed: null,
          ),
        ),
      );
      final iconTop = tester.getTopLeft(find.byIcon(Icons.save)).dy;
      final labelTop = tester.getTopLeft(find.text('Save')).dy;
      expect(iconTop, lessThan(labelTop));
    });

    testWidgets('FwButton.icon carries the semantic label', (tester) async {
      await tester.pumpWidget(
        host(
          const FwButton.icon(
            icon: Icon(Icons.add),
            semanticLabel: 'Add item',
            onPressed: null,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Add item'), findsOneWidget);
      // Square metrics with the minimum touch target.
      final size = tester.getSize(find.byType(FwButton));
      expect(size.width, size.height);
      expect(size.width, greaterThanOrEqualTo(48));
    });

    test('icon-only without semanticLabel throws', () {
      expect(
        () => FwButton(
          label: '',
          icon: const Icon(Icons.add),
          iconPosition: FwIconPosition.only,
          onPressed: null,
        ),
        throwsAssertionError,
      );
    });

    test('icon and leading/trailing are mutually exclusive', () {
      expect(
        () => FwButton(
          label: 'Save',
          icon: const Icon(Icons.save),
          leading: const Icon(Icons.star),
          onPressed: null,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('tonal variant renders with a tinted background', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Tonal',
            variant: FwButtonVariant.tonal,
            onPressed: null,
          ),
        ),
      );
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      final bg = style.backgroundColor!.resolve(const <WidgetState>{})!;
      final solidBg = FwTheme.light().colors.of(FwColorRole.primary);
      // Tonal is a tint, not the full-strength solid color.
      expect(bg, isNot(solidBg));
      expect(bg.a, greaterThan(0));
    });

    testWidgets('reduced motion replaces the spinner with a static glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: FwButton(label: 'Save', loading: true, onPressed: null),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    });

    testWidgets('all FwSize values render at the minimum target', (
      tester,
    ) async {
      for (final size in FwSize.values) {
        await tester.pumpWidget(
          host(FwButton(label: 'S', size: size, onPressed: null)),
        );
        final buttonSize = tester.getSize(find.byType(FilledButton));
        expect(buttonSize.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('keepWidthWhileLoading holds the idle width', (tester) async {
      Widget build(bool loading) => host(
        FwButton(
          label: 'Save changes',
          icon: const Icon(Icons.save),
          loading: loading,
          onPressed: null,
        ),
      );
      await tester.pumpWidget(build(false));
      final idleWidth = tester.getSize(find.byType(FilledButton)).width;
      await tester.pumpWidget(build(true));
      final loadingWidth = tester.getSize(find.byType(FilledButton)).width;
      expect(loadingWidth, moreOrLessEquals(idleWidth));
    });

    testWidgets('loading indicator can sit at the end', (tester) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Save',
            loading: true,
            loadingPosition: FwLoadingPosition.end,
            keepWidthWhileLoading: false,
            onPressed: null,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final spinnerLeft = tester
          .getTopLeft(find.byType(CircularProgressIndicator))
          .dx;
      final labelLeft = tester.getTopLeft(find.text('Save')).dx;
      expect(spinnerLeft, greaterThan(labelLeft));
    });
  });

  group('E2 FwAsyncButton', () {
    testWidgets('success phase shows then reverts on a timer', (tester) async {
      final gate = Completer<void>();
      await tester.pumpWidget(
        host(
          FwAsyncButton(
            label: 'Upload',
            onPressed: () => gate.future,
            successDuration: const Duration(seconds: 5),
          ),
        ),
      );
      await tester.tap(find.byType(FwAsyncButton));
      await tester.pump();
      // Future still pending: loading spinner visible.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pump();
      // Success phase shows the check icon.
      expect(find.byIcon(Icons.check), findsOneWidget);
      // Timed revert returns to idle.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('error phase shows the error icon', (tester) async {
      await tester.pumpWidget(
        host(
          FwAsyncButton(
            label: 'Upload',
            onPressed: () async {
              throw StateError('nope');
            },
            errorDuration: const Duration(seconds: 30),
          ),
        ),
      );
      await tester.tap(find.byType(FwAsyncButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('disposed button never updates state', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(
          FwAsyncButton(
            label: 'Upload',
            onPressed: () async {
              tapped = true;
            },
          ),
        ),
      );
      await tester.tap(find.byType(FwAsyncButton));
      // Remove the button while the future is in flight.
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump(const Duration(seconds: 5));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('E2 FAB', () {
    testWidgets('sizes respect the minimum touch target', (tester) async {
      // small clamps its 40dp visual to the 48dp framework minimum.
      for (final entry in {
        FwFabSize.small: 48.0,
        FwFabSize.regular: 56.0,
        FwFabSize.large: 96.0,
      }.entries) {
        await tester.pumpWidget(
          host(
            FwFab(
              onPressed: () {},
              icon: const Icon(Icons.add),
              size: entry.key,
            ),
          ),
        );
        final size = tester.getSize(find.byType(ElevatedButton));
        expect(size.width, moreOrLessEquals(entry.value));
      }
    });

    testWidgets('extended FAB shows icon and label', (tester) async {
      await tester.pumpWidget(
        host(
          FwFab(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: 'Create',
            tooltip: 'Create',
          ),
        ),
      );
      expect(find.text('Create'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('speed dial opens, closes on Escape, and runs actions', (
      tester,
    ) async {
      var ran = '';
      await tester.pumpWidget(
        host(
          FwSpeedDial(
            children: [
              FwSpeedDialChild(
                icon: const Icon(Icons.edit),
                label: 'Edit',
                onTap: () => ran = 'edit',
              ),
              FwSpeedDialChild(
                icon: const Icon(Icons.share),
                label: 'Share',
                onTap: () => ran = 'share',
              ),
            ],
          ),
        ),
      );
      expect(find.text('Edit'), findsNothing);
      await tester.tap(find.byType(FwFab).first);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      // Escape closes.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
      // Reopen and choose an action.
      await tester.tap(find.byType(FwFab).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(ran, 'share');
      expect(find.text('Edit'), findsNothing);
    });
  });

  group('E2 FwFocusRing token', () {
    test('defaults and copyWith/lerp', () {
      const ring = FwFocusRing();
      expect(ring.width, 2);
      expect(ring.offset, 2);
      expect(ring.copyWith(width: 4).width, 4);
      expect(ring.lerp(const FwFocusRing(width: 4, offset: 4), 0.5).width, 3);
    });

    testWidgets('focused button shows the ring width', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        host(
          FwButton(label: 'Focus me', onPressed: () {}, focusNode: focusNode),
          theme: FwTheme.light().copyWith(
            focusRing: const FwFocusRing(width: 5),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      final side = style.side!.resolve({WidgetState.focused})!;
      expect(side.width, 5);
      expect(side.color, FwTheme.light().colors.of(FwColorRole.focusRing));
    });
  });
}
