import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

/// All non-empty labels in the semantics subtree rooted at [node].
List<String> semanticsLabels(SemanticsNode node) {
  final labels = <String>[];
  void walk(SemanticsNode n) {
    if (n.label.isNotEmpty) labels.add(n.label);
    n.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(node);
  return labels;
}

/// Nodes in the subtree that carry an expanded/collapsed state.
List<SemanticsNode> expandedStateNodes(SemanticsNode node) {
  final out = <SemanticsNode>[];
  void walk(SemanticsNode n) {
    if (n.getSemanticsData().flagsCollection.hasExpandedState) out.add(n);
    n.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(node);
  return out;
}

void main() {
  group('B09 FwStatusDot', () {
    testWidgets('renders dot and caller-supplied label', (tester) async {
      await tester.pumpWidget(host(const FwStatusDot(label: 'Online')));
      expect(find.text('Online'), findsOneWidget);
      // The dot is a circle container.
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(FwStatusDot),
          matching: find.byType(Container),
        ),
      );
      expect((dot.decoration! as BoxDecoration).shape, BoxShape.circle);
    });

    testWidgets('dot uses the intent color', (tester) async {
      await tester.pumpWidget(
        host(const FwStatusDot(label: 'Degraded', intent: FwIntent.warning)),
      );
      final theme = FwTheme.light();
      final (role, _) = intentRoles(FwIntent.warning);
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(FwStatusDot),
          matching: find.byType(Container),
        ),
      );
      expect((dot.decoration! as BoxDecoration).color, theme.colors.of(role));
    });

    testWidgets('single semantic node announces the label', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwStatusDot(
              label: 'Away',
              intent: FwIntent.neutral,
              semanticLabel: 'Away — back in 5 minutes',
            ),
          ),
        );
        final labels = semanticsLabels(
          tester.getSemantics(find.byType(FwStatusDot)),
        );
        expect(labels, ['Away — back in 5 minutes']);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('D03 FwAccordion', () {
    List<FwAccordionItem> items({
      bool secondDisabled = false,
      bool keepAlive = true,
    }) => [
      FwAccordionItem(
        id: 'a',
        header: const Text('Panel A'),
        body: const Text('Body A content'),
        keepAlive: keepAlive,
      ),
      FwAccordionItem(
        id: 'b',
        header: const Text('Panel B'),
        body: const Text('Body B content'),
        enabled: !secondDisabled,
        keepAlive: keepAlive,
      ),
    ];

    testWidgets('tap toggles and reports the next open set', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(items: items(), onOpenChanged: (ids) => reported = ids),
        ),
      );
      await tester.tap(find.text('Panel A'));
      expect(reported, {'a'});
      // Controlled: parent applies the set.
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(),
            openIds: const {'a'},
            onOpenChanged: (ids) => reported = ids,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Body A content'), findsOneWidget);
      await tester.tap(find.text('Panel A'));
      expect(reported, isEmpty);
    });

    testWidgets('single-open policy closes the other panel', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(),
            openIds: const {'a'},
            onOpenChanged: (ids) => reported = ids,
          ),
        ),
      );
      await tester.tap(find.text('Panel B'));
      expect(reported, {'b'});
    });

    testWidgets('allowMultiple keeps other panels open', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(),
            openIds: const {'a'},
            allowMultiple: true,
            onOpenChanged: (ids) => reported = ids,
          ),
        ),
      );
      await tester.tap(find.text('Panel B'));
      expect(reported, {'a', 'b'});
    });

    testWidgets('disabled panel does not toggle', (tester) async {
      var called = false;
      await tester.pumpWidget(
        host(
          FwAccordion(
            items: items(secondDisabled: true),
            onOpenChanged: (_) => called = true,
          ),
        ),
      );
      await tester.tap(find.text('Panel B'));
      expect(called, isFalse);
    });

    testWidgets('headers report expanded semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(FwAccordion(items: items(), openIds: const {'a'})),
        );
        await tester.pumpAndSettle();
        final nodes = expandedStateNodes(
          tester.getSemantics(find.byType(FwAccordion)),
        );
        expect(
          nodes.map((n) => n.getSemanticsData().flagsCollection.isExpanded),
          [true, false],
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('closed body leaves the semantics tree', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(FwAccordion(items: items())));
        await tester.pumpAndSettle();
        var labels = semanticsLabels(
          tester.getSemantics(find.byType(FwAccordion)),
        );
        expect(labels.join(' '), isNot(contains('Body A content')));
        // Open it (uncontrolled shell for the test).
        await tester.pumpWidget(
          host(FwAccordion(items: items(), openIds: const {'a'})),
        );
        await tester.pumpAndSettle();
        labels = semanticsLabels(tester.getSemantics(find.byType(FwAccordion)));
        expect(labels.join(' '), contains('Body A content'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('keyboard Enter toggles the focused header', (tester) async {
      Set<String>? reported;
      await tester.pumpWidget(
        host(
          FwAccordion(items: items(), onOpenChanged: (ids) => reported = ids),
        ),
      );
      // Focus the first header button explicitly, then press Enter.
      final focus = tester.widget<Focus>(
        find
            .descendant(
              of: find.byType(FwAccordion),
              matching: find.byType(Focus),
            )
            .first,
      );
      focus.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(reported, {'a'});
    });

    testWidgets('keepAlive retains body state across close', (tester) async {
      await tester.pumpWidget(
        host(
          const FwAccordion(
            openIds: {'a'},
            items: [
              FwAccordionItem(
                id: 'a',
                header: Text('Panel A'),
                body: TextField(key: ValueKey('field')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('field')), 'hello');
      // Close (parent applies empty set), then reopen.
      await tester.pumpWidget(
        host(
          const FwAccordion(
            items: [
              FwAccordionItem(
                id: 'a',
                header: Text('Panel A'),
                body: TextField(key: ValueKey('field')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        host(
          const FwAccordion(
            openIds: {'a'},
            items: [
              FwAccordionItem(
                id: 'a',
                header: Text('Panel A'),
                body: TextField(key: ValueKey('field')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('field')))
            .controller,
        isNull,
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('focus leaves the body when its panel closes', (tester) async {
      final bodyFocus = FocusNode();
      Set<String> open = {'a'};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              return FwAccordion(
                openIds: open,
                onOpenChanged: (ids) => setState(() => open = ids),
                items: [
                  FwAccordionItem(
                    id: 'a',
                    header: const Text('Panel A'),
                    body: TextField(focusNode: bodyFocus),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(bodyFocus.hasFocus, isTrue);
      // Tap the header to close; the accordion moves focus to the header.
      await tester.tap(find.text('Panel A'));
      await tester.pumpAndSettle();
      expect(bodyFocus.hasFocus, isFalse);
      bodyFocus.dispose();
    });
  });
}
