import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(body: FwViewportQuery(child: child)),
);

void _noop() {}

void main() {
  group('FwSemanticsDebugger', () {
    testWidgets('wraps the child in the framework overlay', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FwSemanticsDebugger(
            child: Text('Hello'),
          ),
        ),
      );
      expect(find.byType(SemanticsDebugger), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('disabled renders the child unchanged', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FwSemanticsDebugger(
            enabled: false,
            child: Text('Hello'),
          ),
        ),
      );
      expect(find.byType(SemanticsDebugger), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('overlay exposes labeled semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FwSemanticsDebugger(
            child: FwButton(label: 'Pay now', onPressed: _noop),
          ),
        ),
      );
      // The framework overlay is present and the button keeps its label.
      expect(find.byType(SemanticsDebugger), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Pay now')),
        findsWidgets,
      );
    });
  });
}
