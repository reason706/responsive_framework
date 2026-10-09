import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(
      child: Center(child: SizedBox(width: 360, child: child)),
    ),
  ),
);

void main() {
  group('E4b inline calendar', () {
    testWidgets('tapping a day selects it', (tester) async {
      DateTime? selected;
      await tester.pumpWidget(
        host(
          FwCalendar(
            visibleMonth: DateTime(2026, 10),
            onDateSelected: (d) => selected = d,
          ),
        ),
      );
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(selected, DateTime(2026, 10, 15));
    });

    testWidgets('selected date renders the highlight', (tester) async {
      await tester.pumpWidget(
        host(
          FwCalendar(
            visibleMonth: DateTime(2026, 10),
            selectedDate: DateTime(2026, 10, 15),
            onDateSelected: (_) {},
          ),
        ),
      );
      expect(find.text('15'), findsOneWidget);
      // The selected day is announced as selected.
      final semantics = tester.getSemantics(find.text('15'));
      expect(semantics.flagsCollection.isSelected, isTrue);
    });

    testWidgets('month navigation changes the visible month', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(
        host(
          FwCalendar(
            visibleMonth: DateTime(2026, 10),
            onDateSelected: (_) {},
            onMonthChanged: (m) => changed = m,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Next month'));
      await tester.pump();
      expect(changed, DateTime(2026, 11));
      // November has 30 days; the 31st is gone.
      expect(find.text('31'), findsNothing);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('days outside min/max are disabled', (tester) async {
      DateTime? selected;
      await tester.pumpWidget(
        host(
          FwCalendar(
            visibleMonth: DateTime(2026, 10),
            minDate: DateTime(2026, 10, 10),
            maxDate: DateTime(2026, 10, 20),
            onDateSelected: (d) => selected = d,
          ),
        ),
      );
      await tester.tap(find.text('5'));
      await tester.pump();
      expect(selected, isNull);
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(selected, DateTime(2026, 10, 15));
    });

    testWidgets('firstDayOfWeek reorders the weekday headers', (tester) async {
      await tester.pumpWidget(
        host(
          FwCalendar(
            visibleMonth: DateTime(2026, 10),
            firstDayOfWeek: DateTime.sunday,
            onDateSelected: (_) {},
          ),
        ),
      );
      // Sunday-first headers: the first header cell is Sunday's narrow name.
      final headers = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'S' ||
                w.data == 'M' ||
                w.data == 'T' ||
                w.data == 'W' ||
                w.data == 'F'),
      );
      expect(headers, findsNWidgets(7));
      expect(
        (tester.widget<Text>(headers.first)).data,
        MaterialLocalizations.of(
          tester.element(find.byType(FwCalendar)),
        ).narrowWeekdays[0],
      );
    });
  });

  group('E4b date range picker', () {
    testWidgets('two taps complete a range', (tester) async {
      DateTime? start;
      DateTime? end;
      await tester.pumpWidget(
        host(
          _RangeHarness(
            onRange: (s, e) {
              start = s;
              end = e;
            },
          ),
        ),
      );
      await tester.tap(find.text('10'));
      await tester.pump();
      expect(start, DateTime(2026, 10, 10));
      expect(end, isNull);

      await tester.tap(find.text('15'));
      await tester.pump();
      expect(start, DateTime(2026, 10, 10));
      expect(end, DateTime(2026, 10, 15));
    });

    testWidgets('tapping before the start swaps the range', (tester) async {
      DateTime? start;
      DateTime? end;
      await tester.pumpWidget(
        host(
          _RangeHarness(
            onRange: (s, e) {
              start = s;
              end = e;
            },
          ),
        ),
      );
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.tap(find.text('10'));
      await tester.pump();
      expect(start, DateTime(2026, 10, 10));
      expect(end, DateTime(2026, 10, 15));
    });

    testWidgets('a third tap starts a new range', (tester) async {
      DateTime? start;
      DateTime? end;
      await tester.pumpWidget(
        host(
          _RangeHarness(
            initialStart: DateTime(2026, 10, 10),
            initialEnd: DateTime(2026, 10, 15),
            onRange: (s, e) {
              start = s;
              end = e;
            },
          ),
        ),
      );
      await tester.tap(find.text('20'));
      await tester.pump();
      expect(start, DateTime(2026, 10, 20));
      expect(end, isNull);
    });
  });
}

/// Controlled-component harness: feeds the picker's output back in.
class _RangeHarness extends StatefulWidget {
  const _RangeHarness({this.initialStart, this.initialEnd, this.onRange});

  final DateTime? initialStart;
  final DateTime? initialEnd;
  final void Function(DateTime? start, DateTime? end)? onRange;

  @override
  State<_RangeHarness> createState() => _RangeHarnessState();
}

class _RangeHarnessState extends State<_RangeHarness> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    return FwDateRangePicker(
      visibleMonth: DateTime(2026, 10),
      start: _start,
      end: _end,
      onRangeSelected: (s, e) {
        setState(() {
          _start = s;
          _end = e;
        });
        widget.onRange?.call(s, e);
      },
    );
  }
}
