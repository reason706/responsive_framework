import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

void main() {
  group('E6 dotted border', () {
    testWidgets('wraps the child in a dotted border', (tester) async {
      await tester.pumpWidget(
        host(const FwDottedBorder(child: Text('Drop files here'))),
      );
      expect(find.text('Drop files here'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dashed style renders', (tester) async {
      await tester.pumpWidget(
        host(
          const FwDottedBorder(
            style: FwBorderStyle.dashed,
            child: Text('Dashed'),
          ),
        ),
      );
      expect(find.text('Dashed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('E6 badge placement', () {
    testWidgets('badge overlays the child corner', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBadgePlacement(
            badge: FwBadge(count: 3),
            child: Icon(Icons.mail, size: 48),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      // Badge sits at the top-right: right of and above the icon center.
      final badgeCenter = tester.getCenter(find.text('3'));
      final iconCenter = tester.getCenter(find.byIcon(Icons.mail));
      expect(badgeCenter.dx, greaterThan(iconCenter.dx));
      expect(badgeCenter.dy, lessThan(iconCenter.dy));
    });

    testWidgets('offset nudges the badge', (tester) async {
      await tester.pumpWidget(
        host(
          const FwBadgePlacement(
            badge: FwBadge(dot: true),
            offset: Offset(8, -8),
            child: Icon(Icons.mail, size: 48),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('E6 empty state', () {
    testWidgets('renders icon, title, description, and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(
          FwEmptyState(
            icon: Icons.inbox,
            title: 'No messages',
            description: 'You are all caught up.',
            action: FwButton(label: 'Compose', onPressed: () => tapped = true),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No messages'), findsOneWidget);
      expect(find.text('You are all caught up.'), findsOneWidget);
      await tester.tap(find.text('Compose'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('custom illustration slot', (tester) async {
      await tester.pumpWidget(
        host(
          const FwEmptyState(
            illustration: FlutterLogo(size: 72),
            title: 'Nothing here',
          ),
        ),
      );
      expect(find.byType(FlutterLogo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
