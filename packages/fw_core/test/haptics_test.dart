import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

class _RecordingSignals extends FwHapticSignals {
  final calls = <String>[];

  @override
  void tap() => calls.add('tap');

  @override
  void confirm() => calls.add('confirm');

  @override
  void error() => calls.add('error');

  @override
  void selection() => calls.add('selection');
}

/// Wave 0, M0.2: haptic signals are mockable, disabled per theme, and
/// skipped under accessible navigation.
void main() {
  Future<List<String>> fireAll(
    WidgetTester tester, {
    FwHaptics? haptics,
    MediaQueryData media = const MediaQueryData(),
  }) async {
    final signals = _RecordingSignals();
    late List<String> calls;
    await tester.pumpWidget(
      MaterialApp(
        theme: FwTheme.light()
            .copyWith(haptics: haptics ?? FwHaptics(signals: signals))
            .toThemeData(),
        home: MediaQuery(
          data: media,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final h = context.fwTheme.haptics;
                h.tap(context);
                h.confirm(context);
                h.error(context);
                h.selection(context);
                calls = signals.calls;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('signals fire through the injected implementation', (
    tester,
  ) async {
    expect(await fireAll(tester), ['tap', 'confirm', 'error', 'selection']);
  });

  testWidgets('disabled haptics fire nothing', (tester) async {
    expect(
      await fireAll(tester, haptics: const FwHaptics(enabled: false)),
      isEmpty,
    );
  });

  testWidgets('accessible navigation skips haptics', (tester) async {
    expect(
      await fireAll(
        tester,
        media: const MediaQueryData(accessibleNavigation: true),
      ),
      isEmpty,
    );
  });

  test('noop signals never throw and the theme defaults to enabled', () {
    const noop = FwNoopHaptics();
    expect(() => noop.tap(), returnsNormally);
    expect(const FwHaptics().enabled, isTrue);
    expect(const FwHaptics().signals, isA<FwSystemHaptics>());
  });

  test('copyWith replaces only the given fields', () {
    const haptics = FwHaptics();
    final disabled = haptics.copyWith(enabled: false);
    expect(disabled.enabled, isFalse);
    expect(disabled.signals, same(haptics.signals));
  });
}
