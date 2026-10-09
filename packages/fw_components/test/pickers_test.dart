import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  // -------------------------------------------------------------------------
  // F10 — range slider.
  // -------------------------------------------------------------------------
  group('FwRangeSlider', () {
    testWidgets('dragging the start thumb reports ordered endpoints', (
      tester,
    ) async {
      RangeValues values = const RangeValues(20, 80);
      await tester.pumpWidget(
        _wrap(
          FwRangeSlider(
            label: 'Price',
            values: values,
            onChanged: (v) => values = v,
          ),
        ),
      );
      final slider = find.byType(RangeSlider);
      expect(slider, findsOneWidget);
      // Drag the start thumb right: endpoints stay ordered.
      final left = tester.getTopLeft(slider);
      await tester.dragFrom(left + const Offset(80, 20), const Offset(100, 0));
      await tester.pump();
      expect(values.start, lessThanOrEqualTo(values.end));
      expect(values.start, greaterThan(20));
    });

    testWidgets('disabled slider ignores drags', (tester) async {
      RangeValues values = const RangeValues(20, 80);
      await tester.pumpWidget(
        _wrap(
          FwRangeSlider(
            label: 'Price',
            values: values,
            enabled: false,
            onChanged: (v) => values = v,
          ),
        ),
      );
      final slider = find.byType(RangeSlider);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump();
      expect(values, const RangeValues(20, 80));
    });
  });

  // -------------------------------------------------------------------------
  // F11 — number field.
  // -------------------------------------------------------------------------
  group('FwNumberField', () {
    testWidgets('stepper increments, clamps at max, and rounds', (
      tester,
    ) async {
      double? value = 9;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwNumberField(
              label: 'Quantity',
              value: value,
              max: 10,
              step: 2,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();
      expect(value, 10); // 9 + 2 = 11 clamps to 10
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();
      expect(value, 10); // stays clamped
      await tester.tap(find.byTooltip('Decrement'));
      await tester.pump();
      expect(value, 8);
    });

    testWidgets('invalid typed text reverts instead of coercing', (
      tester,
    ) async {
      double? value = 5;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwNumberField(
              label: 'Quantity',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '12..34');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(value, 5);
      expect(find.text('5'), findsOneWidget); // reverted
    });

    testWidgets('empty text commits to null', (tester) async {
      double? value = 5;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwNumberField(
              label: 'Quantity',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(value, isNull);
    });

    testWidgets('decimal step rounds to decimalPlaces', (tester) async {
      double? value;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwNumberField(
              label: 'Price',
              value: value,
              step: 0.1,
              decimalPlaces: 2,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();
      expect(value, 0.1);
      await tester.tap(find.byTooltip('Increment'));
      await tester.pump();
      expect(value, 0.2);
    });
  });

  // -------------------------------------------------------------------------
  // F13 — combobox.
  // -------------------------------------------------------------------------
  group('FwCombobox', () {
    List<FwOption<String>> local(String q) {
      const all = [
        FwOption(value: 'apple', label: 'Apple'),
        FwOption(value: 'apricot', label: 'Apricot'),
        FwOption(value: 'banana', label: 'Banana'),
      ];
      return all.where((o) => o.label.toLowerCase().contains(q)).toList();
    }

    testWidgets('typing filters local suggestions and Enter selects', (
      tester,
    ) async {
      FwOption<String>? selected;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwCombobox<String>(
              label: 'Fruit',
              selectedOption: selected,
              onSelected: (o) => setState(() => selected = o),
              suggestionsBuilder: local,
              debounce: Duration.zero,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'ap');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Apricot'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
      // ArrowDown moves the active option; Enter selects it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected?.value, 'apricot');
    });

    testWidgets('stale async results never corrupt the selection', (
      tester,
    ) async {
      final completers = <Completer<List<FwOption<String>>>>[];
      Future<List<FwOption<String>>> slow(String q) {
        final c = Completer<List<FwOption<String>>>();
        completers.add(c);
        return c.future;
      }

      FwOption<String>? selected;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwCombobox<String>(
              label: 'Fruit',
              selectedOption: selected,
              onSelected: (o) => setState(() => selected = o),
              suggestionsBuilder: slow,
              debounce: Duration.zero,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.enterText(find.byType(EditableText), 'ap');
      await tester.pump(const Duration(milliseconds: 20));
      expect(completers.length, 2);
      // First query resolves late with a bogus option.
      completers[0].complete([const FwOption(value: 'x', label: 'X-ray')]);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('X-ray'), findsNothing); // stale: ignored
      // Second query resolves with the real options.
      completers[1].complete([const FwOption(value: 'ap', label: 'Apple')]);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('Escape closes the listbox', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FwCombobox<String>(
            label: 'Fruit',
            onSelected: (_) {},
            suggestionsBuilder: local,
            debounce: Duration.zero,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Apple'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('error state renders when the fetch throws', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FwCombobox<String>(
            label: 'Fruit',
            onSelected: (_) {},
            suggestionsBuilder: (_) => throw StateError('offline'),
            debounce: Duration.zero,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Could not load suggestions'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // F14 — multi-select.
  // -------------------------------------------------------------------------
  group('FwMultiSelect', () {
    const options = [
      FwOption(value: 'a', label: 'Alpha'),
      FwOption(value: 'b', label: 'Beta'),
      FwOption(value: 'c', label: 'Gamma'),
    ];

    testWidgets('dialog selection flows back through Done', (tester) async {
      Set<String> selected = {};
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwMultiSelect<String>(
              label: 'Letters',
              options: options,
              selected: selected,
              onChanged: (s) => setState(() => selected = s),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beta'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(selected, {'b'});
      expect(find.text('Beta'), findsOneWidget); // chip shown
    });

    testWidgets('chip delete removes the value', (tester) async {
      Set<String> selected = {'a', 'b'};
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwMultiSelect<String>(
              label: 'Letters',
              options: options,
              selected: selected,
              onChanged: (s) => setState(() => selected = s),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pump();
      expect(selected, {'b'});
    });

    testWidgets('maxSelection disables further options', (tester) async {
      Set<String> selected = {};
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwMultiSelect<String>(
              label: 'Letters',
              options: options,
              selected: selected,
              maxSelection: 1,
              onChanged: (s) => setState(() => selected = s),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(selected, {'a'});
      // Reopen: Beta's checkbox is disabled at the cap.
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      final betaTile = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text('Beta'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(betaTile.onChanged, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // F15/F16 — date and time fields render their values.
  // -------------------------------------------------------------------------
  group('FwDateField', () {
    testWidgets('renders the formatted civil date', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FwDateField(
            label: 'Start',
            value: DateTime(2026, 10, 10),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.textContaining('2026'), findsOneWidget);
    });

    testWidgets('clear reports null', (tester) async {
      DateTime? value = DateTime(2026, 10, 10);
      var cleared = false;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwDateField(
              label: 'Start',
              value: value,
              onChanged: (v) {
                cleared = v == null;
                setState(() => value = v);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Clear date'));
      await tester.pump();
      expect(cleared, isTrue);
      expect(value, isNull);
    });
  });

  group('FwTimeField', () {
    testWidgets('renders the formatted time', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FwTimeField(
            label: 'Start',
            value: const TimeOfDay(hour: 14, minute: 30),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(FwTimeField), findsOneWidget);
      // Locale-formatted; just assert something time-like is shown.
      expect(find.textContaining(RegExp(r'2:30|14:30')), findsOneWidget);
    });

    testWidgets('clear reports null', (tester) async {
      TimeOfDay? value = const TimeOfDay(hour: 9, minute: 0);
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwTimeField(
              label: 'Start',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Clear time'));
      await tester.pump();
      expect(value, isNull);
    });
  });
}
