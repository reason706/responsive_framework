import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

/// Runs validateAll/validateFields without awaiting a fake-async timer
/// directly: pumps until the returned future completes.
Future<bool> _pumpValidate(
  WidgetTester tester,
  Future<bool> Function() validate,
) async {
  bool? result;
  validate().then((ok) => result = ok);
  for (var i = 0; i < 20 && result == null; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return result!;
}

void main() {
  // -------------------------------------------------------------------------
  // Registration.
  // -------------------------------------------------------------------------
  group('registration', () {
    testWidgets('named fields register; unnamed fields do not', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: Column(
              children: [
                FwTextField(formName: 'email', label: 'Email'),
                FwTextField(label: 'No name'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(controller.fieldNames, contains('email'));
      expect(controller.fieldNames, hasLength(1));
    });

    testWidgets('fields unregister when the form unmounts', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: FwTextField(formName: 'email', label: 'Email'),
          ),
        ),
      );
      await tester.pump();
      expect(controller.fieldNames, contains('email'));
      await tester.pumpWidget(_wrap(const SizedBox()));
      await tester.pump();
      expect(controller.fieldNames, isEmpty);
    });

    testWidgets('fields outside FwForm are untouched', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      // A named field with no FwForm ancestor: no scope, no registration,
      // and no crash — it behaves like a plain field.
      await tester.pumpWidget(
        _wrap(FwTextField(formName: 'email', label: 'Email')),
      );
      await tester.pump();
      expect(controller.fieldNames, isEmpty);
      expect(find.text('Email'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // validateAll — sync phase.
  // -------------------------------------------------------------------------
  group('validateAll', () {
    testWidgets('fails on invalid fields and shows per-field errors', (
      tester,
    ) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: Column(
              children: [
                FwTextField(
                  formName: 'email',
                  label: 'Email',
                  validator: _required,
                ),
                FwTextField(
                  formName: 'name',
                  label: 'Name',
                  initialValue: 'Ada',
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final ok = await _pumpValidate(tester, controller.validateAll);
      await tester.pump();
      expect(ok, isFalse);
      expect(controller.isValid, isFalse);
      // The invalid field shows its error; the valid one does not.
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('passes when all fields valid', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: FwTextField(
              formName: 'email',
              label: 'Email',
              initialValue: 'a@b.c',
              validator: _required,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(await _pumpValidate(tester, controller.validateAll), isTrue);
      expect(controller.isValid, isTrue);
      expect(find.text('Required'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Async validation.
  // -------------------------------------------------------------------------
  group('async validation', () {
    testWidgets('runs after sync, surfaces isValidating and per-field error', (
      tester,
    ) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      final validations = <String>[];
      controller.setAsyncValidator<String>('email', (value) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        validations.add(value ?? '');
        return value == 'taken@x.com' ? 'Already registered' : null;
      });
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: FwTextField(
              formName: 'email',
              label: 'Email',
              initialValue: 'taken@x.com',
              validator: _required,
            ),
          ),
        ),
      );
      await tester.pump();

      bool? result;
      controller.validateAll().then((ok) => result = ok);
      // Let the sync phase complete and the async phase start.
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.isValidating, isTrue);
      for (var i = 0; i < 20 && result == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump();
      expect(result, isFalse);
      expect(controller.isValidating, isFalse);
      expect(validations, ['taken@x.com']);
      expect(find.text('Already registered'), findsOneWidget);

      // Fix the value: async error clears on revalidation.
      await tester.enterText(find.byType(EditableText), 'free@x.com');
      await tester.pump();
      expect(await _pumpValidate(tester, controller.validateAll), isTrue);
      await tester.pump();
      expect(find.text('Already registered'), findsNothing);
    });

    testWidgets('async skipped when sync fails', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      var asyncRan = false;
      controller.setAsyncValidator<String>('email', (value) async {
        asyncRan = true;
        return null;
      });
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: FwTextField(
              formName: 'email',
              label: 'Email',
              validator: _required, // empty -> sync fails
            ),
          ),
        ),
      );
      await tester.pump();
      expect(await _pumpValidate(tester, controller.validateAll), isFalse);
      expect(asyncRan, isFalse);
      expect(controller.isValidating, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Conditional visibility.
  // -------------------------------------------------------------------------
  group('conditional visibility', () {
    Widget buildForm(FwFormController controller) => _wrap(
      FwForm(
        controller: controller,
        child: Column(
          children: [
            FwTextField(
              formName: 'accountType',
              label: 'Account type',
              initialValue: 'personal',
            ),
            FwFormVisibility(
              name: 'company',
              child: FwTextField(
                formName: 'company',
                label: 'Company',
                validator: _required,
              ),
            ),
          ],
        ),
      ),
    );

    testWidgets('hidden fields excluded from values and validation', (
      tester,
    ) async {
      final controller = FwFormController()
        ..setVisibleWhen(
          'company',
          (values) => values['accountType'] == 'business',
        );
      addTearDown(controller.dispose);
      await tester.pumpWidget(buildForm(controller));
      await tester.pump();

      expect(controller.isVisible('company'), isFalse);
      // Hidden: not in values, does not fail validation despite required.
      expect(controller.values.containsKey('company'), isFalse);
      expect(await _pumpValidate(tester, controller.validateAll), isTrue);

      // Show it: now required and empty -> validation fails.
      final fields = find.byType(EditableText);
      await tester.enterText(fields.first, 'business');
      await tester.pump();
      expect(controller.isVisible('company'), isTrue);
      expect(await _pumpValidate(tester, controller.validateAll), isFalse);
      expect(find.text('Required'), findsOneWidget);
      expect(controller.values['company'], '');

      // Fill it: valid again.
      await tester.enterText(fields.at(1), 'Acme');
      await tester.pump();
      expect(await _pumpValidate(tester, controller.validateAll), isTrue);
      expect(controller.values['company'], 'Acme');
    });
  });

  // -------------------------------------------------------------------------
  // Aggregates: values, isDirty, isTouched, reset.
  // -------------------------------------------------------------------------
  group('aggregates', () {
    testWidgets('values map, isDirty, isTouched, reset', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: Column(
              children: [
                FwTextField(formName: 'name', label: 'Name'),
                FwTextField(
                  formName: 'city',
                  label: 'City',
                  initialValue: 'Paris',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(controller.isDirty, isFalse);
      expect(controller.isTouched, isFalse);
      expect(controller.values, {'name': '', 'city': 'Paris'});

      await tester.enterText(find.byType(EditableText).first, 'Ada');
      await tester.pump();
      expect(controller.isDirty, isTrue);
      expect(controller.isTouched, isTrue);
      expect(controller.values['name'], 'Ada');

      controller.reset();
      await tester.pump();
      expect(controller.isDirty, isFalse);
      expect(controller.isTouched, isFalse);
      expect(controller.values, {'name': '', 'city': 'Paris'});
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('validateAll marks the form touched', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: FwTextField(formName: 'name', label: 'Name'),
          ),
        ),
      );
      await tester.pump();
      expect(controller.isTouched, isFalse);
      await _pumpValidate(tester, controller.validateAll);
      expect(controller.isTouched, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Wizard step gating via validateFields.
  // -------------------------------------------------------------------------
  group('wizard', () {
    testWidgets('validateFields gates a step subset', (tester) async {
      final controller = FwFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: Column(
              children: [
                FwTextField(
                  formName: 'email',
                  label: 'Email',
                  validator: _required,
                ),
                FwTextField(
                  formName: 'street',
                  label: 'Street',
                  validator: _required,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Step 1 (email) blocks while empty, even though street is untouched.
      expect(
        await _pumpValidate(tester, () => controller.validateFields(['email'])),
        isFalse,
      );
      // Unknown names are skipped, never throw; result reflects the subset.
      expect(
        await _pumpValidate(
          tester,
          () => controller.validateFields(['nope', 'email']),
        ),
        isFalse,
      );

      await tester.enterText(find.byType(EditableText).first, 'a@b.c');
      await tester.pump();
      expect(
        await _pumpValidate(tester, () => controller.validateFields(['email'])),
        isTrue,
      );
      // Whole-form validation still sees the empty street field.
      expect(await _pumpValidate(tester, controller.validateAll), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // FwFormVisibility widget.
  // -------------------------------------------------------------------------
  group('FwFormVisibility', () {
    testWidgets('hides and restores field state', (tester) async {
      final controller = FwFormController()
        ..setVisibleWhen(
          'nick',
          (values) => (values['show'] as Set?)?.contains('y') == true,
        );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          FwForm(
            controller: controller,
            child: Column(
              children: [
                FwCheckboxGroup<String>(
                  formName: 'show',
                  label: 'Show nickname',
                  options: const [FwOption(value: 'y', label: 'Yes')],
                ),
                FwFormVisibility(
                  name: 'nick',
                  child: FwTextField(formName: 'nick', label: 'Nickname'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(controller.isVisible('nick'), isFalse);

      // Show: type while visible. Visibility UI follows the predicate on the
      // next frame (controller notifications are post-frame).
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.pump();
      expect(controller.isVisible('nick'), isTrue);
      await tester.enterText(find.byType(EditableText).first, 'Al');
      await tester.pump();
      expect(controller.values['nick'], 'Al');

      // Hide: excluded from values; state maintained while hidden.
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.pump();
      expect(controller.isVisible('nick'), isFalse);
      expect(controller.values.containsKey('nick'), isFalse);

      // Show again: the typed value restored.
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.pump();
      expect(controller.isVisible('nick'), isTrue);
      expect(controller.values['nick'], 'Al');
      expect(find.text('Al'), findsOneWidget);
    });
  });
}
