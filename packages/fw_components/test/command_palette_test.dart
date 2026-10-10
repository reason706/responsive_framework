import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

const testCommands = [
  FwCommand(id: 'new', title: 'Create new file', keywords: ['add', 'plus']),
  FwCommand(id: 'open', title: 'Open file', subtitle: 'Browse workspace'),
  FwCommand(id: 'close', title: 'Close editor'),
];

void main() {
  group('FwCommandPalette', () {
    testWidgets('renders placeholder and all commands initially', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FwCommandPalette(commands: testCommands)),
      );
      expect(find.text('Type a command or search...'), findsOneWidget);
      expect(find.text('Create new file'), findsOneWidget);
      expect(find.text('Open file'), findsOneWidget);
      expect(find.text('Close editor'), findsOneWidget);
    });

    testWidgets('typing filters the list', (tester) async {
      await tester.pumpWidget(
        host(const FwCommandPalette(commands: testCommands)),
      );
      await tester.enterText(find.byType(TextField), 'open');
      await tester.pump();
      expect(find.text('Open file'), findsOneWidget);
      expect(find.text('Create new file'), findsNothing);
      expect(find.text('Close editor'), findsNothing);
    });

    testWidgets('fuzzy filter matches non-contiguous characters', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FwCommandPalette(commands: testCommands)),
      );
      // "cf" is a subsequence of "Create new file" but not of the others.
      await tester.enterText(find.byType(TextField), 'cf');
      await tester.pump();
      expect(find.text('Create new file'), findsOneWidget);
      expect(find.text('Open file'), findsNothing);
    });

    testWidgets('keywords participate in matching', (tester) async {
      await tester.pumpWidget(
        host(const FwCommandPalette(commands: testCommands)),
      );
      await tester.enterText(find.byType(TextField), 'plus');
      await tester.pump();
      expect(find.text('Create new file'), findsOneWidget);
      expect(find.text('Open file'), findsNothing);
    });

    testWidgets('subtitle participates in matching', (tester) async {
      await tester.pumpWidget(
        host(const FwCommandPalette(commands: testCommands)),
      );
      await tester.enterText(find.byType(TextField), 'workspace');
      await tester.pump();
      expect(find.text('Open file'), findsOneWidget);
    });

    testWidgets('no match shows the empty text', (tester) async {
      await tester.pumpWidget(
        host(const FwCommandPalette(commands: testCommands)),
      );
      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      await tester.pump();
      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('enter selects the active command', (tester) async {
      FwCommand? selected;
      await tester.pumpWidget(
        host(
          FwCommandPalette(
            commands: testCommands,
            onSelected: (c) => selected = c,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected?.id, 'new');
    });

    testWidgets('arrow keys move the active command before enter', (
      tester,
    ) async {
      FwCommand? selected;
      await tester.pumpWidget(
        host(
          FwCommandPalette(
            commands: testCommands,
            onSelected: (c) => selected = c,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected?.id, 'close');
    });

    testWidgets('arrow up wraps to the last command', (tester) async {
      FwCommand? selected;
      await tester.pumpWidget(
        host(
          FwCommandPalette(
            commands: testCommands,
            onSelected: (c) => selected = c,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected?.id, 'close');
    });

    testWidgets('tapping a command selects it', (tester) async {
      FwCommand? selected;
      await tester.pumpWidget(
        host(
          FwCommandPalette(
            commands: testCommands,
            onSelected: (c) => selected = c,
          ),
        ),
      );
      await tester.tap(find.text('Open file'));
      await tester.pump();
      expect(selected?.id, 'open');
    });

    testWidgets('async onQuery shows loading then results', (tester) async {
      await tester.pumpWidget(
        host(
          FwCommandPalette(
            onQuery: (query) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return testCommands
                  .where((c) => c.title.contains(query))
                  .toList();
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Open');
      await tester.pump();
      expect(find.text('Loading...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Loading...'), findsNothing);
      expect(find.text('Open file'), findsOneWidget);
    });

    testWidgets('show() completes with the selected command', (tester) async {
      FwCommand? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await FwCommandPalette.show(
                  context: context,
                  commands: testCommands,
                );
              },
              child: const Text('open palette'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open palette'));
      await tester.pumpAndSettle();
      expect(find.byType(FwCommandPalette), findsOneWidget);
      await tester.tap(find.text('Close editor'));
      await tester.pumpAndSettle();
      expect(result?.id, 'close');
    });

    testWidgets('dismissing show() completes with null', (tester) async {
      FwCommand? result = const FwCommand(id: 'sentinel', title: 'x');
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await FwCommandPalette.show(
                  context: context,
                  commands: testCommands,
                );
              },
              child: const Text('open palette'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open palette'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('maxResults caps the visible list', (tester) async {
      await tester.pumpWidget(
        host(const FwCommandPalette(commands: testCommands, maxResults: 2)),
      );
      expect(find.text('Create new file'), findsOneWidget);
      expect(find.text('Open file'), findsOneWidget);
      expect(find.text('Close editor'), findsNothing);
    });
  });
}
