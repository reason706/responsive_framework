import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw/fw.dart';

import '../lib/recipes.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: SingleChildScrollView(child: child)),
  ),
);

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('RegistrationFormRecipe', () {
    testWidgets('invalid submit shows field errors', (tester) async {
      await tester.pumpWidget(host(const RegistrationFormRecipe()));
      await scrollTo(tester, find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
    });

    testWidgets('valid submit shows loading then success', (tester) async {
      await tester.pumpWidget(host(const RegistrationFormRecipe()));
      await tester.enterText(find.byType(TextField).at(0), 'Ada Lovelace');
      await tester.enterText(find.byType(TextField).at(1), 'ada@example.com');
      await tester.enterText(find.byType(TextField).at(2), 's3cur3pwd');
      await scrollTo(tester, find.text('I agree to the terms'));
      await tester.tap(find.text('I agree to the terms'));
      await tester.pump();
      await scrollTo(tester, find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Creating your account…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Account created'), findsOneWidget);
    });

    testWidgets('email with "fail" shows error state', (tester) async {
      await tester.pumpWidget(host(const RegistrationFormRecipe()));
      await tester.enterText(find.byType(TextField).at(0), 'Ada');
      await tester.enterText(find.byType(TextField).at(1), 'fail@example.com');
      await tester.enterText(find.byType(TextField).at(2), 's3cur3pwd');
      await scrollTo(tester, find.text('I agree to the terms'));
      await tester.tap(find.text('I agree to the terms'));
      await tester.pump();
      await scrollTo(tester, find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Registration failed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('reset clears the form', (tester) async {
      await tester.pumpWidget(host(const RegistrationFormRecipe()));
      await tester.enterText(find.byType(TextField).at(0), 'Ada');
      await scrollTo(tester, find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(field.controller!.text, isEmpty);
    });
  });

  group('SettingsFormRecipe', () {
    testWidgets('save shows busy then success', (tester) async {
      await tester.pumpWidget(host(const SettingsFormRecipe()));
      await tester.tap(find.text('Save settings'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Settings saved'), findsOneWidget);
    });

    testWidgets('reset restores saved values', (tester) async {
      await tester.pumpWidget(host(const SettingsFormRecipe()));
      await tester.tap(find.byType(FwSwitch).first);
      await tester.pump();
      await tester.tap(find.text('Reset'));
      await tester.pump();
      final sw = tester.widget<FwSwitch>(find.byType(FwSwitch).first);
      expect(sw.value, isTrue);
    });
  });
}
