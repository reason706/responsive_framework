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
  testWidgets('enabled button is semantic, tappable and at least 48 high', (
    tester,
  ) async {
    var count = 0;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        host(FwButton(label: 'Save', onPressed: () => count++)),
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(count, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('disabled and loading buttons never invoke the action', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FwButton(label: 'Disabled', onPressed: null),
            FwButton(
              label: 'Save',
              loading: true,
              loadingLabel: 'Saving',
              onPressed: () => count++,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Disabled'));
    await tester.tap(find.text('Saving'));
    await tester.pump();
    expect(count, 0);
    expect(
      tester
          .widgetList<FilledButton>(find.byType(FilledButton))
          .every((button) => button.onPressed == null),
      isTrue,
    );
  });

  testWidgets(
    'focused button activates from the keyboard and has a focus border',
    (tester) async {
      var count = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FwButton(label: 'Save', focusNode: focus, onPressed: () => count++),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(count, 1);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style!.side!.resolve({WidgetState.focused})!.width, 2);
    },
  );

  testWidgets('theme tokens and large RTL text are respected', (tester) async {
    await tester.pumpWidget(
      host(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: FwCard(
              child: FwButton(label: 'A longer button label', onPressed: null),
            ),
          ),
        ),
        theme: FwTheme.dark().copyWith(minTapTarget: 56),
      ),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(56),
    );
    expect(tester.takeException(), isNull);
  });
}
