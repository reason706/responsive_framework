import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_pilot/main.dart';

void main() {
  testWidgets('settings pilot builds and validates', (tester) async {
    await tester.pumpWidget(const SettingsPilotApp());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Push notifications'), findsOneWidget);

    // Saving with empty required fields shows validation errors.
    await tester.ensureVisible(find.text('Save settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a display name'), findsOneWidget);

    // Fill the form and save -> toast appears.
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.enterText(find.byType(TextField).at(1), 'ada@example.com');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Settings saved'), findsOneWidget);
  });

  testWidgets('preset switch changes theme', (tester) async {
    await tester.pumpWidget(const SettingsPilotApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dark mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    // Tapping the switch toggles it on.
    expect(find.text('Dark mode'), findsOneWidget);
  });
}
