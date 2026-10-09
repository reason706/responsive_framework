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
  _eventSchedulingTests();
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

void _eventSchedulingTests() {
  group('EventSchedulingRecipe (Phase 4 exit gate)', () {
    Widget eventHost() => MaterialApp(
      theme: FwTheme.light().toThemeData(),
      home: const Scaffold(
        body: FwToastHost(
          child: FwViewportQuery(
            child: const SingleChildScrollView(child: EventSchedulingRecipe()),
          ),
        ),
      ),
    );

    testWidgets('full flow: details → confirm dialog → toast', (tester) async {
      await tester.pumpWidget(eventHost());

      // Title.
      await tester.enterText(find.byType(EditableText).first, 'Team retro');
      await tester.pump();

      // Date via the native picker.
      await tester.tap(find.byTooltip('Pick a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Time via the native picker (accept the default).
      await tester.tap(find.byTooltip('Pick a time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Attendees via the multi-select dialog.
      await tester.tap(find.text('Select…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada Lovelace'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Review → confirm dialog shows the summary.
      await scrollTo(tester, find.text('Review and schedule'));
      await tester.tap(find.text('Review and schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule event?'), findsOneWidget);
      // The summary repeats the attendee (also visible as a chip).
      expect(find.textContaining('Ada Lovelace'), findsWidgets);

      // Confirm → busy lock → toast.
      await tester.tap(find.text('Schedule').last);
      await tester.pump(const Duration(milliseconds: 100));
      // Dialog stays open while busy (dismiss locked).
      expect(find.text('Schedule event?'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Event scheduled'), findsOneWidget);
    });

    testWidgets('state survives theme and width changes', (tester) async {
      // Pump at one width, enter a title, then rebuild narrower with a
      // dark theme: the State object (and its values) must persist.
      await tester.pumpWidget(eventHost());
      await tester.enterText(find.byType(EditableText).first, 'Team retro');
      await tester.pump();

      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          darkTheme: FwTheme.dark().toThemeData(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: FwToastHost(
              child: FwViewportQuery(
                child: SingleChildScrollView(child: EventSchedulingRecipe()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The title typed before the rebuild is still there.
      expect(find.text('Team retro'), findsOneWidget);
    });
  });
}
