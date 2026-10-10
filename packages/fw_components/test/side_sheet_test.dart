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

/// Opens the sheet and returns its completion future. The future is only
/// awaited by the test after dismissal.
Future<Future<FwOverlayResult<void>>> openSheet(
  WidgetTester tester, {
  FwSideSheetSide side = FwSideSheetSide.end,
  double width = 360,
  int elevation = 1,
  bool tonal = true,
}) {
  late final Future<FwOverlayResult<void>> future;
  return tester
      .pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                future = FwSideSheet.showModal<void>(
                  context: context,
                  title: const Text('Filters'),
                  content: const Text('sheet content'),
                  side: side,
                  width: width,
                  elevation: elevation,
                  tonal: tonal,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      )
      .then((_) => tester.tap(find.text('open')))
      .then((_) => tester.pumpAndSettle())
      // NOTE: this function is intentionally NOT async — `return future`
      // inside an async function would await the dialog's completion.
      .then((_) => future);
}

void main() {
  group('FwSideSheet', () {
    testWidgets('showModal renders title and content', (tester) async {
      final future = await openSheet(tester);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('sheet content'), findsOneWidget);
      // Dismiss to clean up.
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('close button completes with action reason', (tester) async {
      final future = await openSheet(tester);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      final result = await future;
      expect(result.reason, FwDismissReason.action);
    });

    testWidgets('barrier tap dismisses with barrier reason', (tester) async {
      final future = await openSheet(tester);
      await tester.tapAt(const Offset(10, 400));
      await tester.pumpAndSettle();
      final result = await future;
      expect(result.reason, FwDismissReason.barrier);
    });

    testWidgets('sheet has the requested width', (tester) async {
      final future = await openSheet(tester, width: 300);
      // The sheet is the Container ancestor of the scroll view.
      final sheetBox = find.ancestor(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Container),
      );
      expect(tester.getSize(sheetBox.first).width, 300);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('start side anchors to the leading edge', (tester) async {
      final future = await openSheet(tester, side: FwSideSheetSide.start);
      final align = tester.widget<Align>(
        find
            .ancestor(
              of: find.text('sheet content'),
              matching: find.byType(Align),
            )
            .first,
      );
      expect(align.alignment, Alignment.centerLeft);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('end side anchors to the trailing edge in LTR', (tester) async {
      final future = await openSheet(tester, side: FwSideSheetSide.end);
      final align = tester.widget<Align>(
        find
            .ancestor(
              of: find.text('sheet content'),
              matching: find.byType(Align),
            )
            .first,
      );
      expect(align.alignment, Alignment.centerRight);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('accepts elevation and tonal options', (tester) async {
      final future = await openSheet(tester, elevation: 3, tonal: false);
      expect(find.text('sheet content'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('content scrolls when overflowing', (tester) async {
      final future = await openSheet(tester);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('renders without a title', (tester) async {
      late final Future<FwOverlayResult<void>> future;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                future = FwSideSheet.showModal<void>(
                  context: context,
                  content: const Text('no title content'),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('no title content'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await future;
    });
  });
}
