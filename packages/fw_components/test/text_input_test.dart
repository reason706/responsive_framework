import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('FwTextField', () {
    testWidgets('renders shell label and hint', (tester) async {
      await tester.pumpWidget(
        host(
          const FwTextField(label: 'Email', hintText: 'you@x.com'),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('you@x.com'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('validator error appears after user interaction', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FwTextField(
            label: 'Email',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ),
      );
      // Nothing flashes on first paint.
      expect(find.text('Required'), findsNothing);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('external error takes precedence and shows immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FwTextField(
            label: 'Email',
            externalError: 'Already taken',
            validator: (v) => 'Local error',
            autovalidateMode: AutovalidateMode.always,
          ),
        ),
      );
      expect(find.text('Already taken'), findsOneWidget);
      expect(find.text('Local error'), findsNothing);
    });

    testWidgets('clear action empties the field', (tester) async {
      await tester.pumpWidget(
        host(const FwTextField(label: 'Name', showClear: true)),
      );
      await tester.enterText(find.byType(TextField), 'Ada');
      await tester.pump();
      expect(find.text('Ada'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('caller controller is never disposed by the field', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello');
      await tester.pumpWidget(host(FwTextField(label: 'A', controller: controller)));
      await tester.pumpWidget(host(const SizedBox()));
      // Still usable after the field is gone.
      controller.text = 'still alive';
      expect(controller.text, 'still alive');
      controller.dispose();
    });

    testWidgets('controller swap adopts the new controller', (tester) async {
      final a = TextEditingController(text: 'A');
      final b = TextEditingController(text: 'B');
      await tester.pumpWidget(host(FwTextField(label: 'X', controller: a)));
      expect(find.text('A'), findsOneWidget);
      await tester.pumpWidget(host(FwTextField(label: 'X', controller: b)));
      expect(find.text('B'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'C');
      await tester.pump();
      expect(b.text, 'C');
      expect(a.text, 'A');
      a.dispose();
      b.dispose();
    });

    testWidgets('autofill hints reach the editable', (tester) async {
      await tester.pumpWidget(
        host(
          const FwTextField(
            label: 'Email',
            autofillHints: [AutofillHints.email],
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, contains(AutofillHints.email));
    });

    testWidgets('shell container carries the label in semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(const FwTextField(label: 'Phone')),
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container == true &&
                w.properties.label == 'Phone',
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('integrates with Form validate/save/reset', (tester) async {
      final formKey = GlobalKey<FormState>();
      String? saved;
      await tester.pumpWidget(
        host(
          Form(
            key: formKey,
            child: FwTextField(
              label: 'Name',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
              onSaved: (v) => saved = v,
            ),
          ),
        ),
      );
      // Invalid before input.
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
      // Valid after input; save collects the value.
      await tester.enterText(find.byType(TextField), 'Ada');
      expect(formKey.currentState!.validate(), isTrue);
      formKey.currentState!.save();
      expect(saved, 'Ada');
      // Reset clears.
      formKey.currentState!.reset();
      await tester.pump();
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('outline variant renders an outline border', (tester) async {
      await tester.pumpWidget(
        host(
          const FwTextField(
            label: 'Name',
            variant: FwTextFieldVariant.outline,
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      final decoration = field.decoration!;
      expect(decoration.filled, isFalse);
      expect(decoration.border, isA<OutlineInputBorder>());
    });
  });

  group('FwTextArea', () {
    testWidgets('counter counts graphemes, not code units', (tester) async {
      await tester.pumpWidget(
        host(const FwTextArea(label: 'Bio', maxLength: 10)),
      );
      // Family emoji is one grapheme cluster (many code units).
      await tester.enterText(find.byType(TextField), 'a👨‍👩‍👧‍👦b');
      await tester.pump();
      expect(find.text('3 / 10'), findsOneWidget);
    });

    testWidgets('input is limited to maxLength graphemes', (tester) async {
      await tester.pumpWidget(
        host(const FwTextArea(label: 'Bio', maxLength: 2)),
      );
      await tester.enterText(find.byType(TextField), 'abcdef');
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'ab');
    });

    testWidgets('grows to maxLines then scrolls internally', (tester) async {
      await tester.pumpWidget(
        host(const FwTextArea(label: 'Bio', minLines: 2, maxLines: 3)),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 2);
      expect(field.maxLines, 3);
      expect(field.keyboardType, TextInputType.multiline);
    });

    testWidgets('counter hidden when showCounter is false', (tester) async {
      await tester.pumpWidget(
        host(
          const FwTextArea(label: 'Bio', maxLength: 10, showCounter: false),
        ),
      );
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.pump();
      expect(find.text('2 / 10'), findsNothing);
    });
  });

  group('FwSearchField', () {
    testWidgets('submit callback fires with the query', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        host(
          FwSearchField(
            label: 'Search',
            onSubmitted: (q) => submitted = q,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'query');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submitted, 'query');
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('loading shows a spinner affordance', (tester) async {
      await tester.pumpWidget(
        host(const FwSearchField(label: 'Search', loading: true)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('clear action works in search fields', (tester) async {
      await tester.pumpWidget(
        host(const FwSearchField(label: 'Search')),
      );
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.text('x'), findsNothing);
    });
  });
}
