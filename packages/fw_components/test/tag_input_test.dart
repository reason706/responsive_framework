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

/// Pumps a tag input bound to [tags] via setState.
Future<void> _pumpTagInput(
  WidgetTester tester, {
  required List<String> Function() read,
  required void Function(List<String>) write,
  int? maxTags,
  bool allowDuplicates = false,
  FormFieldValidator<String>? tagValidator,
  FormFieldValidator<List<String>>? validator,
}) {
  return tester.pumpWidget(
    _wrap(
      StatefulBuilder(
        builder: (context, setState) => FwTagInput(
          label: 'Skills',
          hintText: 'Add a skill',
          value: read(),
          onChanged: (v) => setState(() => write(v)),
          maxTags: maxTags,
          allowDuplicates: allowDuplicates,
          tagValidator: tagValidator,
          validator: validator,
        ),
      ),
    ),
  );
}

Finder _inputField() => find.byType(EditableText);

void main() {
  group('FwTagInput', () {
    testWidgets('Enter commits the typed text as a tag', (tester) async {
      var tags = <String>[];
      await _pumpTagInput(tester, read: () => tags, write: (v) => tags = v);
      await tester.enterText(_inputField(), 'dart');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tags, ['dart']);
      expect(find.text('dart'), findsOneWidget);
    });

    testWidgets('typing a separator commits immediately', (tester) async {
      var tags = <String>[];
      await _pumpTagInput(tester, read: () => tags, write: (v) => tags = v);
      await tester.tap(_inputField());
      await tester.pump();
      await tester.enterText(_inputField(), 'flutter,');
      await tester.pump();
      expect(tags, ['flutter']);
      // Input cleared after commit.
      expect(find.text('flutter,'), findsNothing);
    });

    testWidgets('pasting multiple separators commits several tags', (
      tester,
    ) async {
      var tags = <String>[];
      await _pumpTagInput(tester, read: () => tags, write: (v) => tags = v);
      await tester.enterText(_inputField(), 'a, b; c');
      await tester.pump();
      expect(tags, ['a', 'b', 'c']);
    });

    testWidgets('chip delete button removes the tag', (tester) async {
      var tags = <String>['dart', 'flutter'];
      await _pumpTagInput(tester, read: () => tags, write: (v) => tags = v);
      await tester.tap(find.byTooltip('Remove “dart”'));
      await tester.pump();
      expect(tags, ['flutter']);
    });

    testWidgets('backspace on empty input removes the last tag', (
      tester,
    ) async {
      var tags = <String>['dart', 'flutter'];
      await _pumpTagInput(tester, read: () => tags, write: (v) => tags = v);
      await tester.tap(_inputField());
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(tags, ['dart']);
    });

    testWidgets('backspace with text does not remove tags', (tester) async {
      var tags = <String>['dart'];
      await _pumpTagInput(tester, read: () => tags, write: (v) => tags = v);
      await tester.tap(_inputField());
      await tester.enterText(_inputField(), 'flut');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(tags, ['dart']);
      expect(find.text('flu'), findsOneWidget);
    });

    testWidgets('duplicates are rejected with a message', (tester) async {
      var tags = <String>['dart'];
      await _pumpTagInput(tester, read: () => tags, write: (v) => tags = v);
      await tester.enterText(_inputField(), 'dart');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tags, ['dart']);
      expect(find.text('“dart” is already added.'), findsOneWidget);
    });

    testWidgets('allowDuplicates permits repeats', (tester) async {
      var tags = <String>['dart'];
      await _pumpTagInput(
        tester,
        read: () => tags,
        write: (v) => tags = v,
        allowDuplicates: true,
      );
      await tester.enterText(_inputField(), 'dart');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tags, ['dart', 'dart']);
    });

    testWidgets('maxTags caps the list', (tester) async {
      var tags = <String>['a'];
      await _pumpTagInput(
        tester,
        read: () => tags,
        write: (v) => tags = v,
        maxTags: 2,
      );
      await tester.enterText(_inputField(), 'b, c');
      await tester.pump();
      expect(tags, ['a', 'b']);
      expect(find.text('Maximum 2 tags.'), findsOneWidget);
    });

    testWidgets('tagValidator rejects invalid tags', (tester) async {
      var tags = <String>[];
      await _pumpTagInput(
        tester,
        read: () => tags,
        write: (v) => tags = v,
        tagValidator: (tag) => (tag == null || tag.length < 3)
            ? 'Tags need at least 3 characters.'
            : null,
      );
      await tester.enterText(_inputField(), 'ab, abc');
      await tester.pump();
      expect(tags, ['abc']);
      expect(find.text('Tags need at least 3 characters.'), findsOneWidget);
    });

    testWidgets('whole-list validator integrates with Form', (tester) async {
      var tags = <String>[];
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _wrap(
          Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (context, setState) => FwTagInput(
                label: 'Skills',
                value: tags,
                onChanged: (v) => setState(() => tags = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Add at least one.' : null,
              ),
            ),
          ),
        ),
      );
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Add at least one.'), findsOneWidget);
      await tester.enterText(_inputField(), 'dart');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('label, hint, and description render', (tester) async {
      var tags = <String>[];
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwTagInput(
              label: 'Skills',
              hintText: 'Add a skill',
              description: 'Press Enter after each.',
              value: tags,
              onChanged: (v) => setState(() => tags = v),
            ),
          ),
        ),
      );
      expect(find.text('Skills'), findsOneWidget);
      expect(find.text('Add a skill'), findsOneWidget);
      expect(find.text('Press Enter after each.'), findsOneWidget);
    });

    testWidgets('disabled field blocks edits', (tester) async {
      var tags = <String>['dart'];
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => FwTagInput(
              label: 'Skills',
              value: tags,
              enabled: false,
              onChanged: (v) => setState(() => tags = v),
            ),
          ),
        ),
      );
      await tester.enterText(_inputField(), 'flutter');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tags, ['dart']);
      // Delete buttons are disabled: no delete affordance rendered.
      expect(find.byTooltip('Remove “dart”'), findsNothing);
    });
  });
}
