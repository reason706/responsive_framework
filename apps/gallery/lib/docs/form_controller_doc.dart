import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import '../component_doc.dart';

/// Doc board for the form controller family.
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired in here so the catalog edit stays a separate reviewable step):
///
/// ```dart
/// import 'docs/form_controller_doc.dart';
/// // inside the catalog children list, e.g. under Organisms:
/// formControllerDoc(),
/// ```
Widget formControllerDoc() => const ComponentDoc(
  id: 'FRM',
  name: 'Form controller',
  tier: 'Organisms',
  summary:
      'A real form controller, not just fields: FwFormController owns '
      'registration, sync-then-async validation, conditional visibility, and '
      'the values map as listenable state. Fields opt in with a formName; '
      'the nearest FwForm scope auto-registers them. Hidden fields are '
      'excluded from validation and values. validateFields gates wizard '
      'steps via FwStepper.onStepContinue.',
  notFor:
      'replacing per-field validators (they stay the source of truth), or '
      'server-driven dynamic forms (predicates are local and synchronous)',
  anatomy: [
    AnatomyPart(
      'FwFormController',
      'ChangeNotifier. validateAll / validateFields, isValidating, '
          'isDirty / isTouched / isValid, values, reset, visibility.',
    ),
    AnatomyPart(
      'FwForm',
      'Scope widget. Provides the controller via FwFormScope; '
          'rebuilds on notify so async errors reach fields.',
    ),
    AnatomyPart(
      'formName',
      'Optional field param. Registers the field under this name; '
          'null opts out — the field behaves as before.',
    ),
    AnatomyPart(
      'FwFormFieldRegistration',
      'Mixin on FormFieldState. Registers in didChangeDependencies, '
          'unregisters in dispose, observes didChange.',
    ),
    AnatomyPart(
      'FwFormVisibility',
      'Gates a subtree on a visibility predicate. maintainState keeps '
          'field state while hidden.',
    ),
  ],
  properties: _FormControllerDemo(),
  layoutSpecs: [
    LayoutSpec(
      'Scope',
      'one FwForm wraps the fields; controller is app-owned.',
    ),
    LayoutSpec('Names', 'unique per form; duplicates replace registration.'),
    LayoutSpec('Hidden fields', 'keep state (maintainState), skip validation.'),
    LayoutSpec('Wizard', 'one name list per step; validateFields gates.'),
  ],
  dos: [
    'Create the controller in initState (or as a field) and dispose it — '
        'FwForm never disposes it.',
    'Run sync validators first; async only fires for fields that pass sync.',
    'Drive submit buttons off ListenableBuilder + controller.isValid.',
    'Use FwFormVisibility for conditional sections so hidden fields keep '
        'state and restore.',
  ],
  donts: [
    'Don\'t reuse one controller across two forms — names are per-form.',
    'Don\'t put raw colors in async error strings; errors are text only.',
    'Don\'t read values for hidden fields — they are excluded by design.',
    'Don\'t forget setVisibleWhen predicates are synchronous over values.',
  ],
  a11y: [
    'Validation errors surface through each field\'s error slot, so '
        'screen readers announce them with the field.',
    'isValidating can drive a progress indicator with a semantic label.',
    'Hidden fields are offstage: not focusable, not announced.',
    'Wizard gating keeps focus on the failing step\'s first error.',
  ],
);

/// Live demo: sync + async validation, conditional visibility, wizard.
class _FormControllerDemo extends StatefulWidget {
  const _FormControllerDemo();

  @override
  State<_FormControllerDemo> createState() => _FormControllerDemoState();
}

class _FormControllerDemoState extends State<_FormControllerDemo> {
  late final FwFormController _controller;
  int _step = 0;

  static const _stepFields = [
    ['email'],
    ['accountType', 'company'],
  ];

  @override
  void initState() {
    super.initState();
    _controller = FwFormController()
      ..setAsyncValidator<String>('email', (value) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return value == 'taken@example.com' ? 'Already registered' : null;
      })
      ..setVisibleWhen(
        'company',
        (values) => values['accountType'] == 'business',
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return FwForm(
      controller: _controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FwStepper(
            steps: const [
              FwStepData(label: 'Account', description: 'Email'),
              FwStepData(label: 'Profile', description: 'Type & company'),
            ],
            currentStep: _step,
            onStepChanged: (i) => setState(() => _step = i),
            onStepContinue: (step) =>
                _controller.validateFields(_stepFields[step]),
          ),
          const SizedBox(height: 12),
          if (_step == 0)
            FwTextField(
              formName: 'email',
              label: 'Email',
              hintText: 'try taken@example.com for the async error',
              validator: _required,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FwSelect<String>(
                  formName: 'accountType',
                  label: 'Account type',
                  initialValue: 'personal',
                  options: const [
                    FwOption(value: 'personal', label: 'Personal'),
                    FwOption(value: 'business', label: 'Business'),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FwButton(
                  label: _controller.isValidating
                      ? 'Validating…'
                      : 'Validate all',
                  onPressed: _controller.isValidating
                      ? null
                      : () => _controller.validateAll(),
                ),
                FwButton(
                  label: 'Reset',
                  variant: FwButtonVariant.ghost,
                  onPressed: _controller.isDirty ? _controller.reset : null,
                ),
                Text(
                  'dirty: ${_controller.isDirty} · '
                  'touched: ${_controller.isTouched} · '
                  'valid: ${_controller.isValid}',
                  style: context.fwTheme.typeScale.resolve(
                    FwTextRole.bodySm,
                    context,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
