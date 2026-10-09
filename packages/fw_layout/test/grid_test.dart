import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';
import 'package:fw_layout/fw_layout.dart';

Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: FwTheme.light().toThemeData(),
      home: Directionality(
        textDirection: direction,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    );

void main() {
  testWidgets('half spans include internal gutters and fit one row', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 600,
          child: FwRow(
            children: [
              FwCol(
                key: ValueKey('a'),
                span: Responsive.all(6),
                child: SizedBox(height: 30),
              ),
              FwCol(
                key: ValueKey('b'),
                span: Responsive.all(6),
                child: SizedBox(height: 30),
              ),
            ],
          ),
        ),
      ),
    );
    final first = tester.getRect(find.byKey(const ValueKey('a')));
    final second = tester.getRect(find.byKey(const ValueKey('b')));
    expect(first.width, closeTo(292, 0.001));
    expect(second.left - first.right, closeTo(16, 0.001));
    expect(first.top, second.top);
    expect(second.right, closeTo(600, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('row resolves from parent width and wraps full spans', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 400,
          child: FwRow(
            children: [
              FwCol(
                key: ValueKey('a'),
                span: Responsive(base: 12, md: 6),
                child: SizedBox(height: 30),
              ),
              FwCol(
                key: ValueKey('b'),
                span: Responsive(base: 12, md: 6),
                child: SizedBox(height: 30),
              ),
            ],
          ),
        ),
      ),
    );
    final first = tester.getRect(find.byKey(const ValueKey('a')));
    final second = tester.getRect(find.byKey(const ValueKey('b')));
    expect(first.width, 400);
    expect(second.top - first.bottom, 16);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL places the first source item at the right edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 600,
          child: FwRow(
            children: [
              FwCol(
                key: ValueKey('a'),
                span: Responsive.all(6),
                child: SizedBox(height: 20),
              ),
              FwCol(
                key: ValueKey('b'),
                span: Responsive.all(6),
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('a'))).dx,
      greaterThan(tester.getTopLeft(find.byKey(const ValueKey('b'))).dx),
    );
  });

  testWidgets('nested grid resolves using its allocated column width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 1000,
          child: FwRow(
            children: [
              FwCol(
                span: Responsive.all(6),
                child: FwRow(
                  children: [
                    FwCol(
                      key: ValueKey('nested'),
                      span: Responsive(base: 12, md: 6),
                      child: SizedBox(height: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('nested'))).width, 492);
  });

  testWidgets('invalid inactive spans fail instead of waiting for a resize', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          child: FwRow(
            children: [
              FwCol(
                span: Responsive(base: 12, xl: 13),
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });

  testWidgets('fixed container applies max width then inner token padding', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 1000,
          child: FwContainer(
            child: SizedBox(key: ValueKey('content'), height: 20),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byKey(const ValueKey('content')));
    expect(rect.width, 928);
    expect(rect.left, 36);
  });

  testWidgets('grid gutters are root-relative', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light()
            .copyWith(metrics: const FwMetrics(rootSize: 20))
            .toThemeData(),
        home: const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              child: FwRow(
                children: [
                  FwCol(
                    key: ValueKey('a'),
                    span: Responsive.all(6),
                    child: SizedBox(height: 30),
                  ),
                  FwCol(
                    key: ValueKey('b'),
                    span: Responsive.all(6),
                    child: SizedBox(height: 30),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final first = tester.getRect(find.byKey(const ValueKey('a')));
    final second = tester.getRect(find.byKey(const ValueKey('b')));
    // Gutter is 1rem = 20 at root 20 (was 16 at root 16).
    expect(second.left - first.right, closeTo(20, 0.001));
    expect(first.width, closeTo(290, 0.001));
    expect(tester.takeException(), isNull);
  });
}
