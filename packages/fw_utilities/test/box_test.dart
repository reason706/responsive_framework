import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';
import 'package:fw_utilities/fw_utilities.dart';

void main() {
  testWidgets('directional padding flips while decoration uses theme roles', (
    tester,
  ) async {
    final theme = FwTheme.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.toThemeData(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topLeft,
            child: FwBox(
              style: FwStyle(
                background: FwColorRole.surface,
                radius: FwRadius.md,
                padding: EdgeInsetsDirectional.only(start: 20, end: 4),
              ),
              child: SizedBox(key: ValueKey('child'), width: 10, height: 10),
            ),
          ),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(const ValueKey('child'))).dx, 4);
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(FwBox),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (box.decoration as BoxDecoration).color,
      theme.colors.scheme.surface,
    );
  });

  testWidgets('spacing helper resolves customized token values', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light()
            .copyWith(spacing: const FwSpacing(unit: 6))
            .toThemeData(),
        home: Align(
          alignment: Alignment.topLeft,
          child: const SizedBox(
            key: ValueKey('child'),
            width: 10,
            height: 10,
          ).paddingToken(FwSpace.s4),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(const ValueKey('child'))).dx, 24);
  });
}
