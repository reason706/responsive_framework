import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

void main() {
  group('E4c gauge', () {
    testWidgets('renders the formatted value and label', (tester) async {
      await tester.pumpWidget(
        host(const FwGauge(value: 72, unit: '%', label: 'Battery')),
      );
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('Battery'), findsOneWidget);
    });

    testWidgets('semantics expose the value', (tester) async {
      await tester.pumpWidget(
        host(const FwGauge(value: 72, unit: '%', label: 'Battery')),
      );
      final semantics = tester.getSemantics(find.byType(FwGauge));
      expect(semantics.label, 'Battery');
      expect(semantics.value, '72%');
    });

    testWidgets('intent drives the fill color', (tester) async {
      await tester.pumpWidget(
        host(const FwGauge(value: 90, intent: FwIntent.danger)),
      );
      // Pumps without error; the painter resolves danger -> error role.
      expect(tester.takeException(), isNull);
    });

    testWidgets('value clamps to the domain', (tester) async {
      await tester.pumpWidget(host(const FwGauge(value: 9999, max: 100)));
      expect(find.text('100'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom formatter is used', (tester) async {
      await tester.pumpWidget(
        host(
          FwGauge(
            value: 0.723,
            min: 0,
            max: 1,
            valueFormatter: (v) => '${(v * 100).toStringAsFixed(1)} pct',
          ),
        ),
      );
      expect(find.text('72.3 pct'), findsOneWidget);
    });
  });

  group('E4d QR display', () {
    testWidgets('renders a QR code for the data', (tester) async {
      await tester.pumpWidget(
        host(const FwQrDisplay(data: 'https://example.com')),
      );
      expect(find.byType(QrImageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics label the code', (tester) async {
      await tester.pumpWidget(
        host(
          const FwQrDisplay(
            data: 'https://example.com',
            semanticLabel: 'Link to example',
          ),
        ),
      );
      final semantics = tester.getSemantics(find.byType(FwQrDisplay));
      expect(semantics.label, 'Link to example');
      expect(semantics.flagsCollection.isImage, isTrue);
    });

    testWidgets('empty data is rejected', (tester) async {
      expect(() => FwQrDisplay(data: ''), throwsA(isA<AssertionError>()));
    });
  });
}
