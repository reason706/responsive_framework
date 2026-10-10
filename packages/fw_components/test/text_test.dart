import 'package:flutter/gestures.dart';
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

  group('T02 FwRichText', () {
    // Text.rich wraps our span in a framework span; unwrap to our tree.
    TextSpan ourSpan(WidgetTester tester) {
      final rich = tester.widget<RichText>(find.byType(RichText));
      final wrapper = rich.text as TextSpan;
      return wrapper.children!.first as TextSpan;
    }

    TextSpan? findSpan(InlineSpan span, String text) {
      if (span is TextSpan) {
        if (span.text == text) return span;
        for (final child in span.children ?? const <InlineSpan>[]) {
          final hit = findSpan(child, text);
          if (hit != null) return hit;
        }
      }
      return null;
    }

    testWidgets('renders segments and fires link taps', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          FwRichText(
            segments: [
              const FwTextSegment('Hello '),
              FwLinkSegment('world', onTap: () => tapped++),
              const FwTextSegment(' ', emphasis: FwEmphasis.bold),
              const FwCodeSegment('x = 1'),
            ],
          ),
        ),
      );
      final root = ourSpan(tester);
      expect(root.toPlainText(), 'Hello world x = 1');
      final link = findSpan(root, 'world')!;
      expect(link.recognizer, isA<TapGestureRecognizer>());
      (link.recognizer! as TapGestureRecognizer).onTap!();
      expect(tapped, 1);
    });

    testWidgets('emphasis styles resolve bold and strikethrough', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwRichText(
            segments: [
              FwTextSegment('b', emphasis: FwEmphasis.bold),
              FwTextSegment('s', emphasis: FwEmphasis.strikethrough),
            ],
          ),
        ),
      );
      final root = ourSpan(tester);
      expect(findSpan(root, 'b')!.style!.fontWeight, FontWeight.w700);
      expect(
        findSpan(root, 's')!.style!.decoration,
        TextDecoration.lineThrough,
      );
    });

    testWidgets('selectable mode renders SelectableText', (tester) async {
      await tester.pumpWidget(
        host(
          const FwRichText(
            selectable: true,
            segments: [FwTextSegment('copy me')],
          ),
        ),
      );
      expect(find.byType(SelectableText), findsOneWidget);
    });
  });

  group('T07 FwQuote', () {
    testWidgets('renders text and citation', (tester) async {
      await tester.pumpWidget(
        host(const FwQuote(text: 'To be.', citation: 'Shakespeare')),
      );
      expect(find.text('To be.'), findsOneWidget);
      expect(find.textContaining('Shakespeare'), findsOneWidget);
    });
  });

  group('T07 lists', () {
    const items = [
      FwListItemData('one', children: [FwListItemData('nested')]),
      FwListItemData('two'),
    ];

    testWidgets('bullet list renders markers and nesting', (tester) async {
      await tester.pumpWidget(host(const FwBulletList(items: items)));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('nested'), findsOneWidget);
      expect(find.text('•'), findsNWidgets(2)); // depth-0 items
      expect(find.text('–'), findsOneWidget); // depth-1 marker
    });

    testWidgets('ordered list numbers and nests with alpha style', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FwOrderedList(items: items)));
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('a.'), findsOneWidget); // depth-1 style
    });
  });

  group('T08 code and kbd', () {
    testWidgets('FwKbd announces keys joined with plus', (tester) async {
      await tester.pumpWidget(host(const FwKbd(keys: ['⌘', 'K'])));
      expect(find.text('⌘'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(FwKbd));
      expect(semantics.label, '⌘ plus K');
    });

    testWidgets('FwInlineCode renders monospace text', (tester) async {
      await tester.pumpWidget(host(const FwInlineCode(code: 'fn()')));
      expect(find.text('fn()'), findsOneWidget);
    });

    testWidgets('FwCodeBlock copies code and fires onCopied', (tester) async {
      final copied = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text'] as String);
            }
            return null;
          });
      var onCopied = 0;
      await tester.pumpWidget(
        host(
          FwCodeBlock(
            code: 'print("hi")',
            language: 'dart',
            onCopied: () => onCopied++,
          ),
        ),
      );
      expect(find.text('dart'), findsOneWidget);
      await tester.tap(find.byTooltip('Copy code'));
      await tester.pump();
      expect(copied, ['print("hi")']);
      expect(onCopied, 1);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('FwCodeBlock wraps when requested', (tester) async {
      await tester.pumpWidget(
        host(
          const FwCodeBlock(
            code: 'a very long line of code that should wrap instead of scroll',
            wrap: true,
          ),
        ),
      );
      // Wrap mode: no horizontal SingleChildScrollView around the code.
      final scrollers = find.descendant(
        of: find.byType(FwCodeBlock),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollers, findsNothing);
    });
  });

  group('T09 FwReadMore', () {
    const longText =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do '
        'eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim '
        'ad minim veniam, quis nostrud exercitation ullamco laboris.';

    testWidgets('truncates and expands on toggle', (tester) async {
      await tester.pumpWidget(host(const FwReadMore(text: longText)));
      // Truncated: the Text has a maxLines limit.
      final collapsed = tester.widget<Text>(find.textContaining('Lorem'));
      expect(collapsed.maxLines, 3);
      expect(find.text('Read more'), findsOneWidget);

      await tester.tap(find.text('Read more'));
      await tester.pump();
      final expanded = tester.widget<Text>(find.textContaining('Lorem'));
      expect(expanded.maxLines, isNull);
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('controlled expanded reports changes', (tester) async {
      bool? reported;
      await tester.pumpWidget(
        host(
          FwReadMore(
            text: longText,
            expanded: false,
            onExpandedChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Read more'));
      await tester.pump();
      expect(reported, isTrue);
    });
  });

  group('P3.3 new roles', () {
    testWidgets('overline uppercases content and applies tracking', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FwText('Section label', role: FwTextRole.overline)),
      );
      expect(find.text('SECTION LABEL'), findsOneWidget);
      final text = tester.widget<Text>(find.text('SECTION LABEL'));
      expect(text.style!.fontSize, 11);
      expect(text.style!.fontWeight, FontWeight.w600);
      expect(text.style!.letterSpacing, closeTo(0.66, 0.001));
    });

    testWidgets('numeric renders tabular figures', (tester) async {
      await tester.pumpWidget(
        host(const FwText('2026-10-11', role: FwTextRole.numeric)),
      );
      final text = tester.widget<Text>(find.text('2026-10-11'));
      expect(
        text.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
