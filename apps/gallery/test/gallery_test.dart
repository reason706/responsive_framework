import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw/fw.dart';
import 'package:fw_gallery/main.dart';

/// Advances a bounded number of frames instead of [WidgetTester.pumpAndSettle].
///
/// The gallery home screen hosts an always-on [FwShimmer] demo whose sweep
/// animation repeats forever, so pumpAndSettle would never return.
Future<void> pumpFrames(WidgetTester tester, [int frames = 3]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
    await tester.tap(find.byKey(const ValueKey('action-solid')));
    await pumpFrames(tester);
    expect(find.text('Actions completed: 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dark-toggle')));
    await pumpFrames(tester);
    final context = tester.element(find.byType(FwRow));
    expect(Theme.of(context).brightness, Brightness.dark);
    final before = context.fwTheme.colors.scheme.primary;
    await tester.tap(find.byKey(const ValueKey('brand-toggle')));
    await pumpFrames(tester);
    expect(context.fwTheme.colors.scheme.primary, isNot(before));
    await tester.tap(find.byKey(const ValueKey('rtl-toggle')));
    await pumpFrames(tester);
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
    await pumpFrames(tester);
    expect(find.text('Actual width: 400 · breakpoint: xs'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('column-solid'))).width,
      400,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('column-outline'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('column-solid'))).dy,
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
    // The media board deliberately demos an offline image failure; its
    // image-stream error is expected and rendered by the board's
    // errorBuilder, but it surfaces to the test because the failing future
    // resolves before the scroll-aware listener attaches. Filter exactly
    // that known error so the final assertion only sees unexpected ones.
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final Object exception = details.exception;
      if (details.library == 'image resource service' &&
          exception is StateError &&
          exception.message == 'load failed') {
        return;
      }
      oldOnError?.call(details);
    };
    try {
      await tester.pumpWidget(const FwGallery());
      final textSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('text-slider')),
      );
      textSlider.onChanged!(2);
      await pumpFrames(tester);
      final direction = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('rtl-toggle')),
      );
      direction.onChanged!(true);
      await pumpFrames(tester);
      expect(find.text('Actual width: 288 · breakpoint: xs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      FlutterError.onError = oldOnError;
    }
  });
}
