import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('T01 FwText', () {
    testWidgets('resolves the role size and honors explicit truncation', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 780,
            child: FwContainerQuery(
              child: FwText(
                'Heading',
                role: FwTextRole.h1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      // h1 is fluid 1.75-2.5rem over 360-1200: exactly 34 at width 780.
      expect(text.style!.fontSize, 34);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('heading semantics are independent of visual size', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwText(
              'Small heading',
              role: FwTextRole.label,
              heading: true,
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(FwText));
        expect(node.flagsCollection.isHeader, isTrue);
        // Visual role stayed small.
        expect(tester.widget<Text>(find.byType(Text)).style!.fontSize, 14);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('selectable renders SelectableText', (tester) async {
      await tester.pumpWidget(host(const FwText('Copy me', selectable: true)));
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('semantic color roles apply', (tester) async {
      await tester.pumpWidget(
        host(
          const FwText(
            'Muted',
            role: FwTextRole.body,
            color: FwColorRole.textMuted,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.byType(Text)).style!.color,
        FwTheme.light().colors.of(FwColorRole.textMuted),
      );
    });
  });

  group('A03/T03 FwLink', () {
    testWidgets('tap invokes onTap; disabled never does', (tester) async {
      var count = 0;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FwLink(label: 'Active', onTap: () => count++),
              FwLink(label: 'Disabled', onTap: () => count++, enabled: false),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Active'));
      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('link semantics expose link role and uri', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwLink(
              label: 'Docs',
              uri: Uri.parse('https://example.com'),
              onTap: () {},
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(FwLink));
        expect(node.flagsCollection.isLink, isTrue);
        expect(node.value, 'https://example.com');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('external shows the destination cue', (tester) async {
      await tester.pumpWidget(
        host(FwLink(label: 'External', external: true, onTap: () {})),
      );
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('keyboard Enter activates the link', (tester) async {
      var count = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(FwLink(label: 'Keyboard', focusNode: focus, onTap: () => count++)),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('underline is the non-color cue', (tester) async {
      await tester.pumpWidget(host(FwLink(label: 'Link', onTap: () {})));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.decoration, TextDecoration.underline);
    });
  });

  group('T04 FwBadge', () {
    testWidgets('count abbreviates visually but announces fully', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [FwBadge(count: 128), FwBadge(count: 5)],
            ),
          ),
        );
        expect(find.text('99+'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        // The first badge announces the full count, not the abbreviation.
        final node = tester.getSemantics(find.byType(FwBadge).first);
        expect(node.label, '128');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('dot and label variants render', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FwBadge(dot: true),
              FwBadge(label: 'New'),
              FwBadge(
                label: 'Beta',
                variant: FwBadgeVariant.outline,
                intent: FwIntent.info,
              ),
            ],
          ),
        ),
      );
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('T05 FwChip', () {
    testWidgets('filter chip toggles selection', (tester) async {
      var selected = false;
      await tester.pumpWidget(
        host(
          FwChip(
            label: 'Filter',
            kind: FwChipKind.filter,
            selected: selected,
            onSelected: (value) => selected = value,
          ),
        ),
      );
      await tester.tap(find.byType(FilterChip));
      await tester.pump();
      expect(selected, isTrue);
    });

    testWidgets('input chip exposes separate delete action', (tester) async {
      var deleted = false;
      var pressed = false;
      await tester.pumpWidget(
        host(
          FwChip(
            label: 'Tag',
            kind: FwChipKind.input,
            onPressed: () => pressed = true,
            onDeleted: () => deleted = true,
          ),
        ),
      );
      // The delete affordance is a separate semantic action from the chip.
      // (Targeted by tooltip: the glyph varies by Flutter version.)
      await tester.tap(find.byTooltip('Remove'));
      await tester.pump();
      expect(deleted, isTrue);
      expect(pressed, isFalse);
    });

    testWidgets('disabled chip never invokes callbacks', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        host(
          FwChip(label: 'Off', onPressed: () => pressed = true, enabled: false),
        ),
      );
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(pressed, isFalse);
    });
  });

  group('T06 FwDivider', () {
    testWidgets('horizontal divider uses the hairline border role', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const SizedBox(width: 200, child: FwDivider())),
      );
      final container = tester.widget<Container>(find.byType(Container));
      final box = container.color;
      expect(box, FwTheme.light().colors.of(FwColorRole.border));
      expect(tester.getSize(find.byType(FwDivider)).height, 1);
    });

    testWidgets('labeled divider is not decorative', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(const SizedBox(width: 200, child: FwDivider(label: Text('or')))),
        );
        expect(find.text('or'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('vertical divider fills bounded height', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            height: 100,
            child: Row(
              children: [Text('a'), FwDivider(vertical: true), Text('b')],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(FwDivider)).height, 100);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long labels wrap instead of overflowing narrow widths', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(288, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(
              width: 288,
              child: FwDivider(label: Text('a much longer divider label')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
