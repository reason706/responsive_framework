import 'package:flutter/material.dart';
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
  group('FwBanner', () {
    testWidgets('renders title and body', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBanner(
            intent: FwAlertIntent.info,
            title: 'Maintenance tonight',
            body: 'Downtime from 2–3am.',
          ),
        ),
      );
      expect(find.text('Maintenance tonight'), findsOneWidget);
      expect(find.text('Downtime from 2–3am.'), findsOneWidget);
    });

    testWidgets('renders the intent icon for every severity', (tester) async {
      const icons = {
        FwAlertIntent.success: Icons.check_circle_outline,
        FwAlertIntent.info: Icons.info_outline,
        FwAlertIntent.warning: Icons.warning_amber_outlined,
        FwAlertIntent.danger: Icons.error_outline,
      };
      for (final entry in icons.entries) {
        await tester.pumpWidget(host(FwBanner(intent: entry.key, title: 't')));
        expect(find.byIcon(entry.value), findsOneWidget);
      }
    });

    testWidgets('spans the full available width', (tester) async {
      await tester.pumpWidget(
        host(const FwBanner(intent: FwAlertIntent.info, title: 't')),
      );
      final size = tester.getSize(find.byType(FwBanner));
      // Center widget constrains width; banner fills its parent.
      expect(size.width, greaterThan(0));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FwBanner),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, double.infinity);
    });

    testWidgets('action slot is interactive', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        host(
          FwBanner(
            intent: FwAlertIntent.warning,
            title: 'Quota at 90%',
            action: TextButton(
              onPressed: () => acted = true,
              child: const Text('Upgrade'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Upgrade'));
      expect(acted, isTrue);
    });

    testWidgets('dismiss button calls onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        host(
          FwBanner(
            intent: FwAlertIntent.danger,
            title: 't',
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Dismiss'));
      expect(dismissed, isTrue);
    });

    testWidgets('no dismiss button when onDismiss is null', (tester) async {
      await tester.pumpWidget(
        host(const FwBanner(intent: FwAlertIntent.info, title: 't')),
      );
      expect(find.byTooltip('Dismiss'), findsNothing);
    });

    testWidgets('announce wraps the banner in a live region', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBanner(
            intent: FwAlertIntent.info,
            title: 't',
            announce: true,
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('no live region by default', (tester) async {
      await tester.pumpWidget(
        host(const FwBanner(intent: FwAlertIntent.info, title: 't')),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
        findsNothing,
      );
    });

    testWidgets('accepts an elevation level without throwing', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBanner(
            intent: FwAlertIntent.info,
            title: 't',
            elevation: 2,
            tonal: false,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('body is optional', (tester) async {
      await tester.pumpWidget(
        host(const FwBanner(intent: FwAlertIntent.success, title: 'Done')),
      );
      expect(find.text('Done'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
