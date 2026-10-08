import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw/fw.dart';
import 'package:fw_gallery/main.dart';

void main() {
  testWidgets('gallery action, theme, brand, and direction controls work', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FwGallery());
    expect(find.text('Actual width: 960 · breakpoint: md'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('action-primary')));
    await tester.pumpAndSettle();
    expect(find.text('Actions completed: 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dark-toggle')));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(FwRow));
    expect(Theme.of(context).brightness, Brightness.dark);
    final before = context.fwTheme.colors.scheme.primary;
    await tester.tap(find.byKey(const ValueKey('brand-toggle')));
    await tester.pumpAndSettle();
    expect(context.fwTheme.colors.scheme.primary, isNot(before));
    await tester.tap(find.byKey(const ValueKey('rtl-toggle')));
    await tester.pumpAndSettle();
    expect(Directionality.of(context), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('width slider changes the real grid constraints', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FwGallery());
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('width-slider')),
    );
    slider.onChanged!(400);
    await tester.pumpAndSettle();
    expect(find.text('Actual width: 400 · breakpoint: xs'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('column-primary'))).width,
      400,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('column-outline'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('column-primary'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screen with large RTL text has no layout exceptions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FwGallery());
    final textSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('text-slider')),
    );
    textSlider.onChanged!(2);
    await tester.pumpAndSettle();
    final direction = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('rtl-toggle')),
    );
    direction.onChanged!(true);
    await tester.pumpAndSettle();
    expect(find.text('Actual width: 288 · breakpoint: xs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
