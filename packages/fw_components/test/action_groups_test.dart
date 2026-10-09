import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

List<FwButtonGroupItem> groupItems({void Function(int)? onTap}) => [
  FwButtonGroupItem(label: 'One', onPressed: () => onTap?.call(0)),
  FwButtonGroupItem(label: 'Two', onPressed: () => onTap?.call(1)),
  const FwButtonGroupItem(label: 'Three', onPressed: null),
];

void main() {
  group('FwButtonGroup', () {
    testWidgets('attached group draws one shared border, no doubled seams', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FwButtonGroup(items: groupItems(), attached: true)),
      );
      await tester.pumpAndSettle();
      // One outer bordered container...
      final bordered = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border is Border,
      );
      expect(bordered, findsOneWidget);
      // ...with 1px dividers between the three items (n - 1 = 2).
      final dividers = find.byWidgetPredicate(
        (w) => w is Container && w.color != null && w.constraints != null,
      );
      // Items still work and disabled items stay inert.
      var tapped = -1;
      await tester.pumpWidget(
        host(
          FwButtonGroup(
            items: groupItems(onTap: (i) => tapped = i),
            attached: true,
          ),
        ),
      );
      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(tapped, 1);
      await tester.tap(find.text('Three'));
      await tester.pump();
      expect(tapped, 1, reason: 'disabled item must not fire');
      expect(dividers, findsWidgets);
    });

    testWidgets('spaced group uses a token gap', (tester) async {
      await tester.pumpWidget(host(FwButtonGroup(items: groupItems())));
      await tester.pumpAndSettle();
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, greaterThan(0));
    });

    testWidgets('horizontal group stacks vertically on narrow widths', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(host(FwButtonGroup(items: groupItems())));
      await tester.pumpAndSettle();
      // Narrow: vertical Column of buttons, no horizontal Wrap.
      expect(find.byType(Wrap), findsNothing);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('attached horizontal group stacks on narrow widths', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        host(FwButtonGroup(items: groupItems(), attached: true)),
      );
      await tester.pumpAndSettle();
      // No horizontal Row of attached buttons survives at 300px.
      final rows = find.byWidgetPredicate(
        (w) => w is Row && w.crossAxisAlignment == CrossAxisAlignment.stretch,
      );
      expect(rows, findsNothing);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('wide horizontal group stays in a row', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(host(FwButtonGroup(items: groupItems())));
      await tester.pumpAndSettle();
      expect(find.byType(Wrap), findsOneWidget);
    });
  });

  group('FwSegmentedGroup', () {
    List<FwSegmentedItem<String>> segItems() => const [
      FwSegmentedItem(value: 'a', label: 'A'),
      FwSegmentedItem(value: 'b', label: 'B'),
      FwSegmentedItem(value: 'c', label: 'C', enabled: false),
    ];

    testWidgets('single select toggles; required selection cannot empty', (
      tester,
    ) async {
      var selection = <String>{};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwSegmentedGroup<String>(
              items: segItems(),
              selection: selection,
              onSelectionChanged: (s) => setState(() => selection = s),
              emptySelectionAllowed: false,
            ),
          ),
        ),
      );
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(selection, {'a'});
      // Required: tapping the selected item again keeps it.
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(selection, {'a'});
      // Switching moves the single selection.
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(selection, {'b'});
    });

    testWidgets('optional selection can be cleared', (tester) async {
      var selection = <String>{'a'};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwSegmentedGroup<String>(
              items: segItems(),
              selection: selection,
              onSelectionChanged: (s) => setState(() => selection = s),
            ),
          ),
        ),
      );
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(selection, isEmpty);
    });

    testWidgets('multi-select accumulates values', (tester) async {
      var selection = <String>{};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwSegmentedGroup<String>(
              items: segItems(),
              selection: selection,
              onSelectionChanged: (s) => setState(() => selection = s),
              multiSelect: true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(selection, {'a', 'b'});
    });

    testWidgets('arrow keys move selection, skipping disabled items', (
      tester,
    ) async {
      var selection = <String>{'a'};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwSegmentedGroup<String>(
              items: segItems(),
              selection: selection,
              onSelectionChanged: (s) => setState(() => selection = s),
            ),
          ),
        ),
      );
      // Focus the selected item, then arrow right: B selects, C is skipped.
      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selection, {'b'});
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      // C is disabled: wrap lands back on A.
      expect(selection, {'a'});
    });

    testWidgets('selected item carries selected semantics', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwSegmentedGroup<String>(
              items: segItems(),
              selection: const {'b'},
              onSelectionChanged: (_) {},
            ),
          ),
        );
        final semantics = tester.getSemantics(find.text('B'));
        expect(semantics.flagsCollection.isSelected, isTrue);
        final semanticsA = tester.getSemantics(find.text('A'));
        expect(semanticsA.flagsCollection.isSelected, isFalse);
      } finally {
        handle.dispose();
      }
    });
  });

  group('FwSplitButton', () {
    testWidgets('primary tap invokes action; menu trigger opens menu only', (
      tester,
    ) async {
      var primary = 0;
      var menuSelected = '';
      await tester.pumpWidget(
        host(
          FwSplitButton<String>(
            label: 'Save',
            onPressed: () => primary++,
            entries: const [
              FwMenuAction(value: 'draft', label: 'Save draft'),
              FwMenuAction(value: 'template', label: 'Save as template'),
            ],
            onMenuSelected: (v) => menuSelected = v,
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(primary, 1);
      expect(menuSelected, isEmpty);

      // Opening the menu never invokes the primary action.
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(primary, 1, reason: 'menu open must not invoke primary');
      expect(find.text('Save draft'), findsOneWidget);

      await tester.tap(find.text('Save as template'));
      await tester.pumpAndSettle();
      expect(menuSelected, 'template');
      expect(primary, 1);
    });

    testWidgets('menu trigger has an accessible name distinct from primary', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FwSplitButton<String>(
            label: 'Save',
            onPressed: () {},
            entries: const [FwMenuAction(value: 'x', label: 'X')],
            onMenuSelected: (_) {},
            menuLabel: 'More save options',
          ),
        ),
      );
      // FwIconButton's contract: tooltip IS the accessible name.
      expect(find.byTooltip('More save options'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });
}
