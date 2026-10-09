import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  group('FwSlider', () {
    testWidgets('drag reports values; release commits once', (tester) async {
      final changes = <double>[];
      final commits = <double>[];
      await tester.pumpWidget(
        host(
          FwSlider(
            label: 'Volume',
            value: 0.2,
            onChanged: changes.add,
            onChangeEnd: commits.add,
          ),
        ),
      );
      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pump();
      expect(changes, isNotEmpty);
      expect(commits, hasLength(1));
      expect(commits.single, inInclusiveRange(0.0, 1.0));
    });

    testWidgets('disabled slider ignores drags', (tester) async {
      var changed = false;
      await tester.pumpWidget(
        host(
          FwSlider(
            label: 'Volume',
            value: 0.5,
            enabled: false,
            onChanged: (_) => changed = true,
          ),
        ),
      );
      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pump();
      expect(changed, isFalse);
    });

    testWidgets('discrete divisions snap the value', (tester) async {
      double? last;
      await tester.pumpWidget(
        host(
          FwSlider(
            label: 'Steps',
            value: 0,
            min: 0,
            max: 10,
            divisions: 10,
            showTicks: true,
            onChanged: (v) => last = v,
          ),
        ),
      );
      // Drag far right: snaps to the max division.
      await tester.drag(find.byType(Slider), const Offset(400, 0));
      await tester.pump();
      expect(last, 10);
    });

    testWidgets('invalid domains are rejected', (tester) async {
      expect(
        () => FwSlider(label: 'X', value: 0, min: 1, max: 1, onChanged: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => FwSlider(label: 'X', value: 0, divisions: 0, onChanged: (_) {}),
        throwsAssertionError,
      );
      expect(
        () => FwSlider(label: 'X', value: 2, onChanged: (_) {}),
        throwsAssertionError,
      );
    });

    testWidgets('semantics announce label and formatted value', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwSlider(label: 'Volume', value: 0.5, unit: '%', onChanged: (_) {}),
          ),
        );
        // The merge boundary carries the label; the Slider formats values.
        final merged = tester.getSemantics(find.byType(MergeSemantics));
        expect(merged.label, contains('Volume'));
        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.semanticFormatterCallback!(0.5), '0.5%');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('vertical slider rotates the track', (tester) async {
      await tester.pumpWidget(
        host(
          FwSlider(
            label: 'Level',
            value: 0.5,
            axis: Axis.vertical,
            onChanged: (_) {},
          ),
        ),
      );
      // The native slider is rotated a quarter turn for vertical layout.
      expect(
        find.byWidgetPredicate((w) => w is RotatedBox && w.quarterTurns == 3),
        findsOneWidget,
      );
    });
  });

  group('FwCircularSlider', () {
    testWidgets('drag around the ring updates the value', (tester) async {
      double? last;
      final commits = <double>[];
      await tester.pumpWidget(
        host(
          FwCircularSlider(
            label: 'Temperature',
            value: 0,
            min: 0,
            max: 100,
            onChanged: (v) => last = v,
            onChangeEnd: commits.add,
          ),
        ),
      );
      // Widget is 160x160 centered in the 800x600 surface.
      final gesture = await tester.startGesture(const Offset(400, 230));
      await gesture.moveTo(const Offset(470, 300));
      await tester.pump();
      expect(last, isNotNull);
      expect(last!, closeTo(25, 1.0));
      await gesture.up();
      await tester.pump();
      expect(commits, hasLength(1));
    });

    testWidgets('arrow keys step the value', (tester) async {
      double value = 50;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwCircularSlider(
              label: 'Temperature',
              value: value,
              min: 0,
              max: 100,
              autofocus: true,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(value, closeTo(55, 0.001));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(value, closeTo(50, 0.001));
    });

    testWidgets('slider semantics expose value and actions', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwCircularSlider(
              label: 'Temperature',
              value: 50,
              min: 0,
              max: 100,
              unit: '°',
              onChanged: (_) {},
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(FwCircularSlider));
        expect(node.flagsCollection.isSlider, isTrue);
        expect(node.label, 'Temperature');
        expect(node.value, '50.0°');
        final widget = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.slider == true,
          ),
        );
        expect(widget.properties.onIncrease, isNotNull);
        expect(widget.properties.onDecrease, isNotNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('disabled ring ignores gestures and keys', (tester) async {
      var changed = false;
      await tester.pumpWidget(
        host(
          FwCircularSlider(
            label: 'Temperature',
            value: 50,
            enabled: false,
            autofocus: true,
            onChanged: (_) => changed = true,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      final gesture = await tester.startGesture(const Offset(400, 230));
      await gesture.moveTo(const Offset(470, 300));
      await tester.pump();
      await gesture.up();
      expect(changed, isFalse);
    });
  });
}
