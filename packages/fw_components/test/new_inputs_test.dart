import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

void main() {
  group('FwOtpInput', () {
    testWidgets('typing fills boxes and completes at length', (tester) async {
      String? completed;
      final changes = <String>[];
      await tester.pumpWidget(
        host(
          FwOtpInput(
            label: 'Code',
            length: 4,
            onCompleted: (v) => completed = v,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(changes.last, '12');
      expect(completed, isNull);
      // Simulate paste of the full code.
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      expect(completed, '1234');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('obscured mode renders dots', (tester) async {
      await tester.pumpWidget(
        host(FwOtpInput(label: 'PIN', length: 4, obscureText: true)),
      );
      await tester.enterText(find.byType(TextField), '99');
      await tester.pump();
      expect(find.text('•'), findsNWidgets(2));
      expect(find.text('9'), findsNothing);
    });

    testWidgets('extra digits are truncated to length', (tester) async {
      await tester.pumpWidget(host(FwOtpInput(label: 'Code', length: 4)));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '1234');
    });

    testWidgets('oneTimeCode autofill hint is set', (tester) async {
      await tester.pumpWidget(host(FwOtpInput(label: 'Code')));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
      expect(field.keyboardType, TextInputType.number);
    });

    testWidgets('error state shows the message with icon', (tester) async {
      await tester.pumpWidget(
        host(FwOtpInput(label: 'Code', externalError: 'Wrong code')),
      );
      expect(find.text('Wrong code'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('validator integrates with Form', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        host(
          Form(
            key: formKey,
            child: FwOtpInput(
              label: 'Code',
              length: 4,
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Enter all 4 digits' : null,
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter all 4 digits'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '1234');
      expect(formKey.currentState!.validate(), isTrue);
    });
  });

  group('FwRatingDisplay', () {
    testWidgets('fractional value clips the last star', (tester) async {
      await tester.pumpWidget(host(const FwRatingDisplay(value: 3.5, max: 5)));
      expect(find.byType(FwRatingDisplay), findsOneWidget);
      // 4 filled star icons (3 full + 1 clipped) + 5 border icons.
      expect(find.byIcon(Icons.star), findsNWidgets(4));
    });

    testWidgets('single semantic node carries the value', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(const FwRatingDisplay(value: 4, max: 5)));
        final node = tester.getSemantics(find.byType(FwRatingDisplay));
        expect(node.label, '4.0 out of 5');
      } finally {
        semantics.dispose();
      }
    });
  });

  group('FwRatingInput', () {
    testWidgets('tap sets the rating', (tester) async {
      double? selected;
      await tester.pumpWidget(
        host(
          FwRatingInput(
            label: 'Rate us',
            value: 0,
            onChanged: (v) => selected = v,
          ),
        ),
      );
      // Tap the middle of the third star (stars are 32px; row is centered).
      final stars = find.byType(FwRatingDisplay);
      await tester.tapAt(tester.getCenter(stars));
      await tester.pump();
      expect(selected, 3);
    });

    testWidgets('arrow keys step by step', (tester) async {
      double value = 2;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwRatingInput(
              label: 'Rate us',
              value: value,
              step: 0.5,
              autofocus: true,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 2.5);
    });

    testWidgets('disabled input ignores gestures', (tester) async {
      var changed = false;
      await tester.pumpWidget(
        host(
          FwRatingInput(
            label: 'Rate us',
            value: 3,
            enabled: false,
            onChanged: (_) => changed = true,
          ),
        ),
      );
      final stars = find.byType(FwRatingDisplay);
      await tester.tapAt(tester.getCenter(stars));
      await tester.pump();
      expect(changed, isFalse);
    });
  });

  group('FwPhoneField', () {
    testWidgets('typing reports country + national number', (tester) async {
      FwPhoneNumber? number;
      await tester.pumpWidget(
        host(FwPhoneField(label: 'Phone', onChanged: (v) => number = v)),
      );
      expect(find.text('+61'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '412345678');
      await tester.pump();
      expect(number, isNotNull);
      expect(number!.country.code, 'AU');
      expect(number!.nationalNumber, '412345678');
      expect(number!.e164, '+61412345678');
    });

    testWidgets('non-digits are filtered', (tester) async {
      await tester.pumpWidget(host(const FwPhoneField(label: 'Phone')));
      await tester.enterText(find.byType(TextField), 'abc123');
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '123');
    });

    testWidgets('country picker changes the dial code', (tester) async {
      FwPhoneNumber? number;
      await tester.pumpWidget(
        host(FwPhoneField(label: 'Phone', onChanged: (v) => number = v)),
      );
      await tester.tap(find.text('+61'));
      await tester.pumpAndSettle();
      expect(find.text('Select country'), findsOneWidget);
      await tester.tap(find.text('United States'));
      await tester.pumpAndSettle();
      expect(find.text('+1'), findsOneWidget);
      expect(number!.country.code, 'US');
      expect(number!.e164, '+1');
    });

    testWidgets('search filters the country list', (tester) async {
      await tester.pumpWidget(host(const FwPhoneField(label: 'Phone')));
      await tester.tap(find.text('+61'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'japan');
      await tester.pump();
      expect(find.text('Japan'), findsOneWidget);
      expect(find.text('Australia'), findsNothing);
    });

    testWidgets('telephoneNumber autofill hint is set', (tester) async {
      await tester.pumpWidget(host(const FwPhoneField(label: 'Phone')));
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.autofillHints, contains(AutofillHints.telephoneNumber));
      expect(field.keyboardType, TextInputType.phone);
    });
  });
}
