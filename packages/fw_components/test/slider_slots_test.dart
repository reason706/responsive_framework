import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('E3 slider icon slots', () {
    testWidgets('leading/trailing flank the track in LTR', (tester) async {
      await tester.pumpWidget(
        host(
          const FwSlider(
            label: 'Volume',
            value: 0.5,
            onChanged: null,
            leading: Icon(Icons.volume_down),
            trailing: Icon(Icons.volume_up),
          ),
        ),
      );
      final leadingDx = tester.getCenter(find.byIcon(Icons.volume_down)).dx;
      final sliderDx = tester.getCenter(find.byType(Slider)).dx;
      final trailingDx = tester.getCenter(find.byIcon(Icons.volume_up)).dx;
      expect(leadingDx, lessThan(sliderDx));
      expect(trailingDx, greaterThan(sliderDx));
    });

    testWidgets('leading/trailing flip sides in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FwSlider(
              label: 'Volume',
              value: 0.5,
              onChanged: null,
              leading: Icon(Icons.volume_down),
              trailing: Icon(Icons.volume_up),
            ),
          ),
        ),
      );
      final leadingDx = tester.getCenter(find.byIcon(Icons.volume_down)).dx;
      final sliderDx = tester.getCenter(find.byType(Slider)).dx;
      final trailingDx = tester.getCenter(find.byIcon(Icons.volume_up)).dx;
      // Logical start is on the right in RTL.
      expect(leadingDx, greaterThan(sliderDx));
      expect(trailingDx, lessThan(sliderDx));
    });

    testWidgets('thumbIcon installs the glyph thumb shape', (tester) async {
      await tester.pumpWidget(
        host(
          const FwSlider(
            label: 'Volume',
            value: 0.5,
            onChanged: null,
            thumbIcon: Icons.volume_up,
          ),
        ),
      );
      final theme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(theme.data.thumbShape, isA<FwIconThumbShape>());
    });

    testWidgets('no thumbIcon keeps the plain thumb', (tester) async {
      await tester.pumpWidget(
        host(const FwSlider(label: 'Volume', value: 0.5, onChanged: null)),
      );
      final theme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(theme.data.thumbShape, isA<RoundSliderThumbShape>());
    });
  });

  group('E3 track fill control', () {
    testWidgets('showFill false renders a uniform track', (tester) async {
      await tester.pumpWidget(
        host(
          const FwSlider(
            label: 'Volume',
            value: 0.5,
            onChanged: null,
            showFill: false,
          ),
        ),
      );
      final theme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(theme.data.activeTrackColor, theme.data.inactiveTrackColor);
    });

    testWidgets('showFill true tints the filled portion', (tester) async {
      await tester.pumpWidget(
        host(const FwSlider(label: 'Volume', value: 0.5, onChanged: null)),
      );
      final theme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(theme.data.activeTrackColor, isNot(theme.data.inactiveTrackColor));
    });
  });

  group('E3 labeled marks', () {
    testWidgets('marks render their labels under the track', (tester) async {
      await tester.pumpWidget(
        host(
          const FwSlider(
            label: 'Quality',
            value: 0.5,
            onChanged: null,
            min: 0,
            max: 100,
            marks: [
              FwSliderMark(0, label: 'Low'),
              FwSliderMark(50, label: 'Med'),
              FwSliderMark(100, label: 'High'),
            ],
          ),
        ),
      );
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      // Marks order left-to-right by value in LTR.
      final lowDx = tester.getCenter(find.text('Low')).dx;
      final medDx = tester.getCenter(find.text('Med')).dx;
      final highDx = tester.getCenter(find.text('High')).dx;
      expect(lowDx, lessThan(medDx));
      expect(medDx, lessThan(highDx));
    });

    testWidgets('mark without a label draws a tick dot', (tester) async {
      await tester.pumpWidget(
        host(
          const FwSlider(
            label: 'Quality',
            value: 0.5,
            onChanged: null,
            marks: [FwSliderMark(0.5)],
          ),
        ),
      );
      // A labeled mark would render text; the dot renders none.
      expect(find.text(''), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('E3 error state', () {
    testWidgets('error tints the track and shows the message', (tester) async {
      await tester.pumpWidget(
        host(
          FwSlider(
            label: 'Volume',
            value: 0.5,
            onChanged: (_) {},
            errorText: 'Too loud for quiet hours',
          ),
        ),
      );
      expect(find.text('Too loud for quiet hours'), findsOneWidget);
      final theme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      final error = FwTheme.light().colors.of(FwColorRole.error);
      expect(theme.data.activeTrackColor, error);
      expect(theme.data.thumbColor, error);
    });

    testWidgets('error slider stays interactive', (tester) async {
      var value = 0.5;
      await tester.pumpWidget(
        host(
          FwSlider(
            label: 'Volume',
            value: value,
            onChanged: (v) => value = v,
            errorText: 'Too loud for quiet hours',
          ),
        ),
      );
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();
      expect(value, isNot(0.5));
    });

    testWidgets('error is distinct from disabled', (tester) async {
      var errorValue = 0.5;
      var disabledValue = 0.5;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FwSlider(
                label: 'Error',
                value: errorValue,
                onChanged: (v) => errorValue = v,
                errorText: 'Fix me',
              ),
              FwSlider(
                label: 'Disabled',
                value: disabledValue,
                onChanged: (v) => disabledValue = v,
                enabled: false,
              ),
            ],
          ),
        ),
      );
      final sliders = find.byType(Slider);
      await tester.drag(sliders.at(0), const Offset(100, 0));
      await tester.pump();
      await tester.drag(sliders.at(1), const Offset(100, 0));
      await tester.pump();
      // Error: interactive. Disabled: ignores input.
      expect(errorValue, isNot(0.5));
      expect(disabledValue, 0.5);
    });
  });

  group('E3 vertical slots', () {
    testWidgets('vertical leading sits above, trailing below', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            height: 400,
            child: FwSlider(
              label: 'Volume',
              value: 0.5,
              onChanged: null,
              axis: Axis.vertical,
              leading: Icon(Icons.volume_down),
              trailing: Icon(Icons.volume_up),
            ),
          ),
        ),
      );
      final leadingDy = tester.getCenter(find.byIcon(Icons.volume_down)).dy;
      final sliderDy = tester.getCenter(find.byType(Slider)).dy;
      final trailingDy = tester.getCenter(find.byIcon(Icons.volume_up)).dy;
      expect(leadingDy, lessThan(sliderDy));
      expect(trailingDy, greaterThan(sliderDy));
    });
  });
}
