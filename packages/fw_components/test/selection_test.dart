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
  group('FwPasswordField', () {
    testWidgets('reveal toggle flips obscuring and keeps focus', (
      tester,
    ) async {
      final focusNode = FocusNode();
      await tester.pumpWidget(
        host(FwPasswordField(label: 'Password', focusNode: focusNode)),
      );
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
      expect(textField.autofillHints, contains(AutofillHints.password));

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);
      // Focus returns to the field after toggling.
      expect(focusNode.hasFocus, isTrue);
      focusNode.dispose();
    });

    testWidgets('typing updates the strength bar', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FwPasswordField(label: 'Password', controller: controller),
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) => FwPasswordStrengthBar(
                  password: value.text,
                  label: 'Strength',
                ),
              ),
            ],
          ),
        ),
      );
      // Empty password: no bar.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.enterText(find.byType(TextField), 'S3cure!Passw0rd');
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1.0);
      controller.dispose();
    });
  });

  group('FwCheckbox', () {
    testWidgets('tap cycles false -> true -> false', (tester) async {
      bool? value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwCheckbox(
              label: 'Accept',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Accept'));
      await tester.pump();
      expect(value, isTrue);
      await tester.tap(find.text('Accept'));
      await tester.pump();
      expect(value, isFalse);
    });

    testWidgets('tristate cycles null -> true -> false', (tester) async {
      bool? value;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwCheckbox(
              label: 'All',
              value: value,
              tristate: true,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(value, isTrue);
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(value, isFalse);
    });

    testWidgets('disabled checkbox does not toggle', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        host(
          FwCheckbox(
            label: 'Accept',
            value: false,
            enabled: false,
            onChanged: (_) => toggled = true,
          ),
        ),
      );
      await tester.tap(find.text('Accept'));
      await tester.pump();
      expect(toggled, isFalse);
    });

    testWidgets('merged semantics carry the checked state', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwCheckbox(label: 'Accept', value: true, onChanged: null),
          ),
        );
        final node = tester.getSemantics(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container == true &&
                w.properties.label == 'Accept',
          ),
        );
        expect(node.hasFlag(SemanticsFlag.hasCheckedState), isTrue);
        expect(node.hasFlag(SemanticsFlag.isChecked), isTrue);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('FwCheckboxGroup', () {
    const options = [
      FwOption(value: 'a', label: 'Alpha'),
      FwOption(value: 'b', label: 'Beta'),
      FwOption(value: 'c', label: 'Gamma', enabled: false),
    ];

    testWidgets('selects multiple values by typed id', (tester) async {
      Set<String>? selected;
      await tester.pumpWidget(
        host(
          FwCheckboxGroup<String>(
            label: 'Letters',
            options: options,
            onChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(selected, {'a', 'b'});
      // Disabled option never toggles.
      await tester.tap(find.text('Gamma'));
      await tester.pump();
      expect(selected, {'a', 'b'});
    });

    testWidgets('required validator errors on empty after submit', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        host(
          Form(
            key: formKey,
            child: FwCheckboxGroup<String>(
              label: 'Letters',
              options: options,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Pick at least one' : null,
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Pick at least one'), findsOneWidget);
    });
  });

  group('FwRadioGroup', () {
    const options = [
      FwOption(value: 1, label: 'One'),
      FwOption(value: 2, label: 'Two'),
      FwOption(value: 3, label: 'Three', enabled: false),
    ];

    testWidgets('tap selects a single value', (tester) async {
      int? selected;
      await tester.pumpWidget(
        host(
          FwRadioGroup<int>(
            label: 'Numbers',
            options: options,
            onChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(selected, 2);
    });

    testWidgets('arrow down moves focus and selects, skipping disabled', (
      tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        host(
          FwRadioGroup<int>(
            label: 'Numbers',
            options: options,
            onChanged: (v) => selected = v,
          ),
        ),
      );
      // Focus the first option's row.
      final first = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.container == true &&
            w.properties.label == 'One',
      );
      // Tap to focus via the InkWell, then use arrow keys.
      await tester.tap(find.text('One'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(selected, 2);
      // Next arrow skips disabled 'Three' and wraps to 'One'.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(selected, 1);
    });

    testWidgets('options expose mutually exclusive semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwRadioGroup<int>(
              label: 'Numbers',
              options: options,
              initialValue: 1,
              onChanged: (_) {},
            ),
          ),
        );
        final node = tester.getSemantics(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container == true &&
                w.properties.label == 'One',
          ),
        );
        expect(
          node.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup),
          isTrue,
        );
        expect(node.hasFlag(SemanticsFlag.isChecked), isTrue);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('FwSwitch', () {
    testWidgets('tap toggles the value', (tester) async {
      var value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwSwitch(
              label: 'Wi-Fi',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Wi-Fi'));
      await tester.pump();
      expect(value, isTrue);
    });

    testWidgets('busy blocks interaction and shows a spinner', (
      tester,
    ) async {
      var toggled = false;
      await tester.pumpWidget(
        host(
          FwSwitch(
            label: 'Wi-Fi',
            value: false,
            busy: true,
            onChanged: (_) => toggled = true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      await tester.tap(find.text('Wi-Fi'));
      await tester.pump();
      expect(toggled, isFalse);
    });

    testWidgets('checked state is in semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(const FwSwitch(label: 'Wi-Fi', value: true)),
        );
        final node = tester.getSemantics(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container == true &&
                w.properties.label == 'Wi-Fi',
          ),
        );
        expect(node.hasFlag(SemanticsFlag.isChecked), isTrue);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('FwSelect', () {
    const options = [
      FwOption(value: 's', label: 'Small'),
      FwOption(value: 'm', label: 'Medium'),
      FwOption(value: 'l', label: 'Large', enabled: false),
    ];

    testWidgets('choosing an item reports its typed value', (tester) async {
      String? selected;
      await tester.pumpWidget(
        host(
          FwSelect<String>(
            label: 'Size',
            options: options,
            placeholder: 'Pick a size',
            onChanged: (v) => selected = v,
          ),
        ),
      );
      expect(find.text('Pick a size'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medium').last);
      await tester.pumpAndSettle();
      expect(selected, 'm');
    });

    testWidgets('disabled option cannot be chosen', (tester) async {
      String? selected;
      await tester.pumpWidget(
        host(
          FwSelect<String>(
            label: 'Size',
            options: options,
            onChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Large').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, isNull);
    });

    testWidgets('error state shows the message', (tester) async {
      await tester.pumpWidget(
        host(
          const FwSelect<String>(
            label: 'Size',
            options: options,
            externalError: 'Select a size',
          ),
        ),
      );
      expect(find.text('Select a size'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
