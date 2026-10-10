import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

void main() {
  group('FwShimmer', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        host(const FwShimmer(child: Text('placeholder'))),
      );
      expect(find.text('placeholder'), findsOneWidget);
    });

    testWidgets('applies a ShaderMask sweep when enabled', (tester) async {
      await tester.pumpWidget(host(const FwShimmer(child: Text('x'))));
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('no ShaderMask when enabled is false', (tester) async {
      await tester.pumpWidget(
        host(const FwShimmer(enabled: false, child: Text('x'))),
      );
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.text('x'), findsOneWidget);
    });

    testWidgets('suppresses animation under reduced motion', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const FwShimmer(child: Text('x'))),
        ),
      );
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.text('x'), findsOneWidget);
    });

    testWidgets('toggling enabled stops and restarts the sweep', (
      tester,
    ) async {
      var enabled = true;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                FwShimmer(enabled: enabled, child: const Text('x')),
                TextButton(
                  onPressed: () => setState(() => enabled = false),
                  child: const Text('toggle'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(ShaderMask), findsOneWidget);
      await tester.tap(find.text('toggle'));
      await tester.pump();
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('excludes semantics', (tester) async {
      await tester.pumpWidget(host(const FwShimmer(child: Text('x'))));
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });

    testWidgets('bones factory composes FwAutoSkeleton', (tester) async {
      await tester.pumpWidget(
        host(
          FwShimmer.bones(
            child: const Column(children: [Text('Ada'), Text('Lovelace')]),
          ),
        ),
      );
      expect(find.byType(FwAutoSkeleton), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('bones factory respects enabled=false', (tester) async {
      await tester.pumpWidget(
        host(FwShimmer.bones(enabled: false, child: const Text('x'))),
      );
      expect(find.byType(FwAutoSkeleton), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('accepts a custom duration without throwing', (tester) async {
      await tester.pumpWidget(
        host(
          const FwShimmer(
            duration: Duration(milliseconds: 800),
            child: Text('x'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes its ticker without leaking', (tester) async {
      await tester.pumpWidget(host(const FwShimmer(child: Text('x'))));
      await tester.pumpWidget(host(const Text('gone')));
      expect(tester.takeException(), isNull);
    });
  });
}
