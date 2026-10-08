import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  test('responsive values inherit the nearest lower override', () {
    const value = Responsive(base: 12, md: 6, xl: 4);
    expect(FwBreakpoint.values.map(value.resolve).toList(), [
      12,
      12,
      6,
      6,
      4,
      4,
    ]);
    expect(const Responsive.all('fixed').resolve(FwBreakpoint.xxl), 'fixed');
  });

  test('exact thresholds activate the new breakpoint', () {
    const breakpoints = FwBreakpoints.standard;
    final widths = [576.0, 768.0, 992.0, 1200.0, 1400.0];
    for (var index = 0; index < widths.length; index++) {
      expect(breakpoints.at(widths[index] - 0.01), FwBreakpoint.values[index]);
      expect(breakpoints.at(widths[index]), FwBreakpoint.values[index + 1]);
    }
    expect(breakpoints.at(0), FwBreakpoint.xs);
  });

  test('invalid thresholds and measurements are rejected', () {
    expect(() => FwBreakpoints(sm: 800, md: 768), throwsArgumentError);
    expect(() => FwBreakpoints(sm: double.nan), throwsArgumentError);
    expect(() => FwBreakpoints(sm: 0), throwsArgumentError);
    expect(() => FwBreakpoints.standard.at(-1), throwsArgumentError);
    expect(
      () => FwBreakpoints.standard.at(double.infinity),
      throwsArgumentError,
    );
  });

  testWidgets('container and viewport queries use distinct widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget label(String prefix) => Builder(
      builder: (context) => Text('$prefix:${context.fwBreakpoint.name}'),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light().toThemeData(),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: Column(
              children: [
                FwContainerQuery(child: label('container')),
                FwViewportQuery(child: label('viewport')),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('container:xs'), findsOneWidget);
    expect(find.text('viewport:xl'), findsOneWidget);
  });

  testWidgets('unbounded container queries fail clearly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light().toThemeData(),
        home: const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: FwContainerQuery(child: Text('content')),
        ),
      ),
    );
    expect(
      tester.takeException().toString(),
      contains('requires bounded width'),
    );
  });
}
