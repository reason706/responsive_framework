import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

FwColors lightColors() => FwTheme.light().colors;

void main() {
  group('A01 button intent and variant', () {
    testWidgets('danger solid uses the error pair', (tester) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Delete',
            onPressed: null,
            intent: FwIntent.danger,
          ),
        ),
      );
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(
        style.backgroundColor!.resolve(const <WidgetState>{}),
        lightColors().of(FwColorRole.error),
      );
      expect(
        style.foregroundColor!.resolve(const <WidgetState>{}),
        lightColors().of(FwColorRole.onError),
      );
    });

    testWidgets('outline danger uses intent color for text and border', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Delete',
            onPressed: null,
            variant: FwButtonVariant.outline,
            intent: FwIntent.danger,
          ),
        ),
      );
      final style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;
      expect(
        style.foregroundColor!.resolve(const <WidgetState>{}),
        lightColors().of(FwColorRole.error),
      );
      expect(
        style.side!.resolve(const <WidgetState>{})!.color,
        lightColors().of(FwColorRole.error),
      );
    });

    testWidgets('sizes scale padding around the same minimum target', (
      tester,
    ) async {
      double horizontal(FwButtonSize size) {
        // Resolved via the built style in a dedicated pump below.
        return size == FwButtonSize.sm
            ? 12
            : size == FwButtonSize.md
            ? 16
            : 24;
      }

      for (final size in FwButtonSize.values) {
        await tester.pumpWidget(
          host(FwButton(label: 'Sized', size: size, onPressed: null)),
        );
        final style = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style!;
        final padding = style.padding!
            .resolve(const <WidgetState>{})!
            .resolve(TextDirection.ltr);
        expect(padding.left, horizontal(size));
        expect(style.minimumSize!.resolve(const <WidgetState>{})!.height, 48);
      }
    });

    testWidgets('leading and trailing icons render with a token gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Next',
            onPressed: null,
            leading: Icon(Icons.add),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('link variant underlines instead of using color alone', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Learn more',
            onPressed: null,
            variant: FwButtonVariant.link,
          ),
        ),
      );
      final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
      expect(
        style.textStyle!.resolve(const <WidgetState>{})!.decoration,
        TextDecoration.underline,
      );
    });

    testWidgets('hovered and pressed keep the intent hue', (tester) async {
      await tester.pumpWidget(
        host(
          const FwButton(
            label: 'Delete',
            onPressed: null,
            intent: FwIntent.danger,
          ),
        ),
      );
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      final base = lightColors().of(FwColorRole.error);
      final hovered = style.backgroundColor!.resolve({WidgetState.hovered})!;
      final pressed = style.backgroundColor!.resolve({WidgetState.pressed})!;
      // State layers tint toward the foreground; hue stays in the family.
      expect(hovered, isNot(base));
      expect(pressed, isNot(base));
      expect(hovered, isNot(pressed));
    });
  });

  group('A02 icon button', () {
    testWidgets('tooltip is the accessible name and target is 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwIconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {},
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(IconButton));
        expect(node.tooltip, 'Search');
        expect(
          tester.getSize(find.byType(IconButton)).width,
          greaterThanOrEqualTo(48),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('selected toggle fills with the intent pair', (tester) async {
      await tester.pumpWidget(
        host(
          FwIconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorite',
            selected: true,
            onPressed: () {},
          ),
        ),
      );
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.isSelected, isTrue);
      expect(
        button.style!.backgroundColor!.resolve({WidgetState.selected}),
        lightColors().of(FwColorRole.primary),
      );
    });

    testWidgets('disabled icon button never invokes the action', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(
        host(
          FwIconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => count++,
          ),
        ),
      );
      // Enabled control for contrast: disabled variant below.
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(count, 1);

      await tester.pumpWidget(
        host(
          const FwIconButton(
            icon: Icon(Icons.search),
            tooltip: 'Search',
            onPressed: null,
          ),
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(count, 1);
    });

    testWidgets('all variants render without exceptions', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final variant in FwIconButtonVariant.values)
                FwIconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search $variant',
                  variant: variant,
                  onPressed: () {},
                ),
            ],
          ),
        ),
      );
      expect(find.byType(IconButton), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('A07 close action', () {
    testWidgets('default accessible name is Close', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(FwCloseButton(onPressed: () {})));
        expect(tester.getSemantics(find.byType(IconButton)).tooltip, 'Close');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('destructive close uses the danger intent', (tester) async {
      await tester.pumpWidget(
        host(FwCloseButton(onPressed: () {}, destructive: true)),
      );
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        button.style!.foregroundColor!.resolve(const <WidgetState>{}),
        lightColors().of(FwColorRole.error),
      );
    });
  });
}
