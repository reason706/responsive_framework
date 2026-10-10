import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('D01 FwCard', () {
    testWidgets('slots render in header/media/content/actions order', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwCard(
            header: Text('hdr', key: ValueKey('hdr')),
            media: SizedBox(
              key: ValueKey('media'),
              height: 60,
              width: double.infinity,
            ),
            content: Text('body', key: ValueKey('body')),
            actions: Text('acts', key: ValueKey('acts')),
          ),
        ),
      );
      final tops = [
        for (final key in ['media', 'hdr', 'body', 'acts'])
          tester.getTopLeft(find.byKey(ValueKey(key))).dy,
      ];
      expect(tops, orderedEquals(tops..sort()));
      expect(tops.toSet().length, 4);
    });

    testWidgets('variants differ in surface treatment', (tester) async {
      Future<Material> materialOf(FwCardVariant variant) async {
        await tester.pumpWidget(host(FwCard(variant: variant)));
        return tester.widget<Material>(
          find.descendant(
            of: find.byType(FwCard),
            matching: find.byType(Material),
          ),
        );
      }

      final elevated = await materialOf(FwCardVariant.elevated);
      final outlined = await materialOf(FwCardVariant.outlined);
      final filled = await materialOf(FwCardVariant.filled);
      expect(elevated.elevation, greaterThan(0));
      expect(outlined.elevation, 0);
      final outlineShape = outlined.shape! as RoundedRectangleBorder;
      expect(outlineShape.side.style, BorderStyle.solid);
      final filledShape = filled.shape! as RoundedRectangleBorder;
      expect(filledShape.side.style, BorderStyle.none);
      expect(filled.elevation, 0);
    });

    testWidgets('plain card is not implicitly tappable', (tester) async {
      await tester.pumpWidget(host(const FwCard(content: Text('info'))));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('D01 FwInteractiveCard', () {
    testWidgets('tap on the card invokes onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          FwInteractiveCard(
            onTap: () => tapped++,
            semanticLabel: 'Open article',
            child: const FwCard(content: Text('article')),
          ),
        ),
      );
      await tester.tap(find.text('article'));
      expect(tapped, 1);
      final node = tester.getSemantics(find.byType(FwInteractiveCard));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.label, 'Open article');
    });

    testWidgets('nested actions keep their own handlers', (tester) async {
      var cardTaps = 0;
      var buttonTaps = 0;
      await tester.pumpWidget(
        host(
          FwInteractiveCard(
            onTap: () => cardTaps++,
            child: FwCard(
              content: const Text('article'),
              actions: FwButton(
                label: 'Save',
                variant: FwButtonVariant.ghost,
                onPressed: () => buttonTaps++,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(buttonTaps, 1);
      expect(cardTaps, 0);
      await tester.tap(find.text('article'));
      expect(cardTaps, 1);
    });

    testWidgets('disabled suppresses invocation', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          FwInteractiveCard(
            onTap: () => tapped++,
            enabled: false,
            child: const FwCard(content: Text('article')),
          ),
        ),
      );
      await tester.tap(find.text('article'));
      expect(tapped, 0);
    });
  });

  group('D02 FwListTile', () {
    testWidgets('slots render and tap works', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          FwListTile(
            leading: const FwAvatar(name: 'Ada Lovelace'),
            title: const Text('Ada Lovelace'),
            subtitle: const Text('Analytical engines'),
            trailing: const FwIcon(Icons.chevron_right),
            onTap: () => tapped++,
          ),
        ),
      );
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Analytical engines'), findsOneWidget);
      await tester.tap(find.text('Ada Lovelace'));
      expect(tapped, 1);
    });

    testWidgets('selection is visible and announced', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwListTile(
              title: Text('Chosen'),
              selected: true,
              onTap: null,
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(FwListTile));
        expect(node.flagsCollection.isSelected, isTrue);
        final tile = tester.widget<ListTile>(find.byType(ListTile));
        expect(tile.selected, isTrue);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('disabled tile suppresses tap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          FwListTile(
            title: const Text('Nope'),
            enabled: false,
            onTap: () => tapped++,
          ),
        ),
      );
      await tester.tap(find.text('Nope'));
      expect(tapped, 0);
    });
  });

  group('D02 FwList', () {
    testWidgets('divided list inserts decorative separators', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwList(children: [Text('one'), Text('two'), Text('three')]),
          ),
        );
        expect(find.byType(FwDivider), findsNWidgets(2));
        // Decorative dividers are excluded from semantics.
        expect(find.bySemanticsLabel('one'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('D11 FwTreeView', () {
    const nodes = [
      FwTreeNode(
        id: 'a',
        label: 'Parent',
        children: [
          FwTreeNode(id: 'a1', label: 'Child 1'),
          FwTreeNode(id: 'a2', label: 'Child 2'),
        ],
      ),
      FwTreeNode(id: 'b', label: 'Leaf'),
    ];

    testWidgets('toggles expansion on parent tap', (tester) async {
      await tester.pumpWidget(host(const FwTreeView(nodes: nodes)));
      expect(find.text('Child 1'), findsNothing);
      await tester.tap(find.text('Parent'));
      await tester.pump();
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
      // Collapse again.
      await tester.tap(find.text('Parent'));
      await tester.pump();
      expect(find.text('Child 1'), findsNothing);
    });

    testWidgets('leaf tap selects', (tester) async {
      FwTreeNode? selected;
      await tester.pumpWidget(
        host(FwTreeView(nodes: nodes, onSelect: (n) => selected = n)),
      );
      await tester.tap(find.text('Leaf'));
      await tester.pump();
      expect(selected?.id, 'b');
    });

    testWidgets('controlled expandedIds', (tester) async {
      await tester.pumpWidget(
        host(const FwTreeView(nodes: nodes, expandedIds: {'a'})),
      );
      expect(find.text('Child 1'), findsOneWidget);
    });
  });
}
