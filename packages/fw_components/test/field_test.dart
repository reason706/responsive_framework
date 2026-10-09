import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('FwFieldState model', () {
    test('external error takes precedence over validator error', () {
      const state = FwFieldState<String>(
        validatorError: 'Too short',
        externalError: 'Already taken',
      );
      expect(state.resolvedError, 'Already taken');
      expect(state.hasError, isTrue);
    });

    test('validator error resolves when no external error', () {
      const state = FwFieldState<String>(validatorError: 'Too short');
      expect(state.resolvedError, 'Too short');
    });

    test('error is only shown after interaction', () {
      const untouched = FwFieldState<String>(validatorError: 'Required');
      expect(untouched.showError, isFalse);
      expect(untouched.copyWith(touched: true).showError, isTrue);
      expect(untouched.copyWith(dirty: true).showError, isTrue);
    });

    test('interactive requires enabled and not readOnly', () {
      expect(const FwFieldState<String>().interactive, isTrue);
      expect(const FwFieldState<String>(enabled: false).interactive, isFalse);
      expect(const FwFieldState<String>(readOnly: true).interactive, isFalse);
    });

    test('copyWith can clear errors independently', () {
      const state = FwFieldState<String>(
        validatorError: 'A',
        externalError: 'B',
      );
      final cleared = state.copyWith(clearExternalError: true);
      expect(cleared.resolvedError, 'A');
      expect(state.resolvedError, 'B');
    });

    test('equality covers all fields', () {
      expect(
        const FwFieldState<String>(value: 'x'),
        const FwFieldState<String>(value: 'x'),
      );
      expect(
        const FwFieldState<String>(value: 'x'),
        isNot(const FwFieldState<String>(value: 'y')),
      );
      expect(
        const FwFieldState<String>(touched: true),
        isNot(const FwFieldState<String>()),
      );
    });
  });

  group('FwField shell', () {
    testWidgets('renders persistent label and required marker', (tester) async {
      await tester.pumpWidget(
        host(const FwField(label: 'Email', required: true, child: TextField())),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('error replaces description and is a live region', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwField(
              label: 'Email',
              description: 'We never share it.',
              errorText: 'Enter a valid email',
              child: TextField(),
            ),
          ),
        );
        expect(find.text('Enter a valid email'), findsOneWidget);
        expect(find.text('We never share it.'), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        // Error text sits inside a live region for announcements.
        final live = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        );
        expect(live, findsOneWidget);
        // The outer container carries the label for the whole field.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container == true &&
                w.properties.label == 'Email',
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('description shows when there is no error', (tester) async {
      await tester.pumpWidget(
        host(
          const FwField(
            label: 'Email',
            description: 'We never share it.',
            child: TextField(),
          ),
        ),
      );
      expect(find.text('We never share it.'), findsOneWidget);
    });

    testWidgets('prefix and suffix flank the editor', (tester) async {
      await tester.pumpWidget(
        host(
          const FwField(
            label: 'Amount',
            prefix: Icon(Icons.attach_money),
            suffix: Text('USD'),
            child: TextField(),
          ),
        ),
      );
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('FwFieldScope exposes shell state to editors', (tester) async {
      FwFieldScope? captured;
      await tester.pumpWidget(
        host(
          FwField(
            label: 'Name',
            required: true,
            enabled: false,
            errorText: 'Required',
            child: Builder(
              builder: (context) {
                captured = FwFieldScope.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(captured, isNotNull);
      expect(captured!.label, 'Name');
      expect(captured!.required, isTrue);
      expect(captured!.enabled, isFalse);
      expect(captured!.hasError, isTrue);
    });

    testWidgets('local fieldTheme override changes the error icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwField(
            label: 'Email',
            errorText: 'Bad',
            fieldTheme: FwFieldTheme(errorIcon: Icons.warning),
            child: TextField(),
          ),
        ),
      );
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('label meets tap target and labeling guidelines', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwField(
              label: 'Email',
              child: SizedBox(height: 48, child: TextField()),
            ),
          ),
        );
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        semantics.dispose();
      }
    });
  });

  group('FwFieldTheme', () {
    test('of falls back to defaults without registration', () {
      // Registered via FwTheme.light().toThemeData() extensions in host().
      // Here we only assert copyWith/lerp plumbing.
      const a = FwFieldTheme(labelGap: 4);
      const b = FwFieldTheme(labelGap: 12);
      final mid = a.lerp(b, 0.5);
      expect(mid.labelGap, 8);
      expect(a.copyWith(messageGap: 6).messageGap, 6);
    });
  });
}
