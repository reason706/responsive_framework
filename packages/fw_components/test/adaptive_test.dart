import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget _wrap(Widget child, FwPlatform platform) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwPlatformOverride(
      platform: platform,
      child: FwViewportQuery(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

void main() {
  // -------------------------------------------------------------------------
  // FwPlatformOverride.
  // -------------------------------------------------------------------------
  group('FwPlatformOverride', () {
    testWidgets('defaults to system (not iOS in tests)', (tester) async {
      var isIOS = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isIOS = FwPlatformOverride.isIOS(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        FwPlatformOverride.of(tester.element(find.byType(SizedBox))),
        FwPlatform.system,
      );
      expect(isIOS, isFalse);
    });

    testWidgets('forces iOS and android', (tester) async {
      for (final platform in FwPlatform.values) {
        var resolved = FwPlatform.system;
        await tester.pumpWidget(
          MaterialApp(
            home: FwPlatformOverride(
              platform: platform,
              child: Builder(
                builder: (context) {
                  resolved = FwPlatformOverride.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        expect(resolved, platform);
        expect(
          FwPlatformOverride.isIOS(tester.element(find.byType(SizedBox))),
          platform == FwPlatform.iOS,
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // FwAdaptiveButton.
  // -------------------------------------------------------------------------
  group('FwAdaptiveButton', () {
    testWidgets(
      'iOS renders CupertinoButton.filled; android renders FwButton',
      (tester) async {
        var pressed = false;
        await tester.pumpWidget(
          _wrap(
            FwAdaptiveButton(label: 'Save', onPressed: () => pressed = true),
            FwPlatform.iOS,
          ),
        );
        expect(find.byType(CupertinoButton), findsOneWidget);
        expect(find.byType(FwButton), findsNothing);
        await tester.tap(find.byType(CupertinoButton));
        await tester.pump();
        expect(pressed, isTrue);

        pressed = false;
        await tester.pumpWidget(
          _wrap(
            FwAdaptiveButton(label: 'Save', onPressed: () => pressed = true),
            FwPlatform.android,
          ),
        );
        expect(find.byType(FwButton), findsOneWidget);
        expect(find.byType(CupertinoButton), findsNothing);
        await tester.tap(find.byType(FwButton));
        await tester.pump();
        expect(pressed, isTrue);
      },
    );

    testWidgets('unfilled renders plain variants and supports icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FwAdaptiveButton(
            label: 'Cancel',
            onPressed: null,
            icon: Icons.close,
            filled: false,
          ),
          FwPlatform.iOS,
        ),
      );
      final button = tester.widget<CupertinoButton>(
        find.byType(CupertinoButton),
      );
      // Plain constructor (not .filled): no fill color configured.
      expect(button.color, isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          const FwAdaptiveButton(
            label: 'Cancel',
            onPressed: null,
            icon: Icons.close,
            filled: false,
          ),
          FwPlatform.android,
        ),
      );
      final fwButton = tester.widget<FwButton>(find.byType(FwButton));
      expect(fwButton.variant, FwButtonVariant.ghost);
    });
  });

  // -------------------------------------------------------------------------
  // FwAdaptiveSwitch.
  // -------------------------------------------------------------------------
  group('FwAdaptiveSwitch', () {
    testWidgets('iOS renders CupertinoSwitch; android renders FwSwitch', (
      tester,
    ) async {
      var value = false;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwAdaptiveSwitch(
              label: 'Notifications',
              description: 'Push alerts',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          FwPlatform.iOS,
        ),
      );
      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(find.byType(FwSwitch), findsNothing);
      expect(find.text('Notifications'), findsOneWidget);
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pump();
      expect(value, isTrue);

      value = false;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwAdaptiveSwitch(
              label: 'Notifications',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          FwPlatform.android,
        ),
      );
      expect(find.byType(FwSwitch), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsNothing);
    });

    testWidgets('disabled switch does not toggle', (tester) async {
      var value = false;
      await tester.pumpWidget(
        _wrap(
          FwAdaptiveSwitch(
            label: 'Notifications',
            value: value,
            onChanged: (v) => value = v,
            enabled: false,
          ),
          FwPlatform.iOS,
        ),
      );
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pump();
      expect(value, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // FwAdaptiveIndicator.
  // -------------------------------------------------------------------------
  group('FwAdaptiveIndicator', () {
    testWidgets(
      'iOS renders CupertinoActivityIndicator; android FwCircularProgress',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const FwAdaptiveIndicator(semanticLabel: 'Loading'),
            FwPlatform.iOS,
          ),
        );
        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byType(FwCircularProgress), findsNothing);

        await tester.pumpWidget(
          _wrap(const FwAdaptiveIndicator(value: 0.5), FwPlatform.android),
        );
        expect(find.byType(FwCircularProgress), findsOneWidget);
        expect(find.byType(CupertinoActivityIndicator), findsNothing);
      },
    );
  });

  // -------------------------------------------------------------------------
  // FwAdaptiveSlider.
  // -------------------------------------------------------------------------
  group('FwAdaptiveSlider', () {
    testWidgets('iOS renders CupertinoSlider; android renders FwSlider', (
      tester,
    ) async {
      var value = 0.5;
      await tester.pumpWidget(
        _wrap(
          FwAdaptiveSlider(
            label: 'Volume',
            value: value,
            onChanged: (v) => value = v,
          ),
          FwPlatform.iOS,
        ),
      );
      expect(find.byType(CupertinoSlider), findsOneWidget);
      expect(find.byType(FwSlider), findsNothing);
      expect(find.text('Volume'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          FwAdaptiveSlider(
            label: 'Volume',
            value: value,
            onChanged: (v) => value = v,
          ),
          FwPlatform.android,
        ),
      );
      expect(find.byType(FwSlider), findsOneWidget);
      expect(find.byType(CupertinoSlider), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // FwAdaptiveDatePicker.
  // -------------------------------------------------------------------------
  group('FwAdaptiveDatePicker', () {
    testWidgets('iOS renders CupertinoDatePicker; android renders FwCalendar', (
      tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        _wrap(
          FwAdaptiveDatePicker(
            selectedDate: DateTime(2026, 10, 10),
            onDateSelected: (d) => picked = d,
          ),
          FwPlatform.iOS,
        ),
      );
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.byType(FwCalendar), findsNothing);

      await tester.pumpWidget(
        _wrap(
          FwAdaptiveDatePicker(
            selectedDate: DateTime(2026, 10, 10),
            onDateSelected: (d) => picked = d,
          ),
          FwPlatform.android,
        ),
      );
      expect(find.byType(FwCalendar), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsNothing);
      expect(picked, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // FwAdaptiveDialog.
  // -------------------------------------------------------------------------
  group('FwAdaptiveDialog', () {
    testWidgets('iOS alert returns the tapped action value', (tester) async {
      String? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => FwAdaptiveButton(
              label: 'Open',
              onPressed: () => FwAdaptiveDialog.show<String>(
                context: context,
                title: 'Delete?',
                content: const Text('This cannot be undone.'),
                actions: const [
                  FwAdaptiveDialogAction(label: 'Cancel', value: 'cancel'),
                  FwAdaptiveDialogAction(
                    label: 'Delete',
                    value: 'delete',
                    isDestructive: true,
                  ),
                ],
              ).then((v) => result = v),
            ),
          ),
          FwPlatform.iOS,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, 'delete');
    });

    testWidgets('android alert returns the tapped action value', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => FwAdaptiveButton(
              label: 'Open',
              onPressed: () => FwAdaptiveDialog.show<String>(
                context: context,
                title: 'Delete?',
                content: const Text('This cannot be undone.'),
                actions: const [
                  FwAdaptiveDialogAction(label: 'Cancel', value: 'cancel'),
                  FwAdaptiveDialogAction(
                    label: 'Delete',
                    value: 'delete',
                    isDestructive: true,
                  ),
                ],
              ).then((v) => result = v),
            ),
          ),
          FwPlatform.android,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.text('Delete?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, 'delete');
    });

    testWidgets('iOS action sheet returns the tapped action value', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => FwAdaptiveButton(
              label: 'Open',
              onPressed: () => FwAdaptiveDialog.showActionSheet<String>(
                context: context,
                title: 'Share',
                actions: const [
                  FwAdaptiveDialogAction(label: 'Copy', value: 'copy'),
                ],
                cancelLabel: 'Cancel',
              ).then((v) => result = v),
            ),
          ),
          FwPlatform.iOS,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(result, 'copy');
    });

    testWidgets('android action sheet falls back to a dialog', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => FwAdaptiveButton(
              label: 'Open',
              onPressed: () => FwAdaptiveDialog.showActionSheet<String>(
                context: context,
                title: 'Share',
                message: 'Pick an option',
                actions: const [
                  FwAdaptiveDialogAction(label: 'Copy', value: 'copy'),
                ],
              ),
            ),
          ),
          FwPlatform.android,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Pick an option'), findsOneWidget);
    });
  });
}
