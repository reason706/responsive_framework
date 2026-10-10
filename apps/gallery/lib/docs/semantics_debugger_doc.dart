import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import '../component_doc.dart';

/// Doc board for FwSemanticsDebugger (utils backlog, dev-only).
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired in here so the catalog edit stays a separate reviewable step):
///
/// ```dart
/// import 'docs/semantics_debugger_doc.dart';
/// // inside the catalog children list, e.g. under Patterns:
/// semanticsDebuggerDoc(),
/// ```
Widget semanticsDebuggerDoc() => const ComponentDoc(
  id: 'U03',
  name: 'Semantics debugger',
  tier: 'Patterns',
  summary:
      'Dev-only overlay that visualizes the semantics tree: every node\u2019s '
      'bounds are painted with its label and flags. Wraps the framework '
      'overlay with an Fw*-named, toggleable API. Never ship in production '
      'UI — it is a gallery and widget-test aid.',
  notFor: 'production builds, or as a substitute for screen-reader testing',
  anatomy: const [
    AnatomyPart('Overlay', 'framework SemanticsDebugger painting.'),
    AnatomyPart('Toggle', 'enabled flag; off renders the child unchanged.'),
  ],
  properties: const _SemanticsDebuggerDemo(),
  layoutSpecs: const [
    LayoutSpec('Scope', 'paints from the view pipeline owner (whole view).'),
    LayoutSpec('Labels', '10px overlay text; pass labelStyle to theme it.'),
  ],
  dos: const [
    'Wrap one demo section at a time to keep the overlay readable.',
    'Use it to verify every interactive element has a label.',
  ],
  donts: const [
    'Don\u2019t leave it enabled in release builds.',
    'Don\u2019t treat the overlay as proof of screen-reader UX — test '
        'with a real reader.',
  ],
  a11y: const [
    'The tool itself exists to audit accessibility.',
    'Overlay labels are visual only and excluded from semantics.',
  ],
);

class _SemanticsDebuggerDemo extends StatefulWidget {
  const _SemanticsDebuggerDemo();

  @override
  State<_SemanticsDebuggerDemo> createState() => _SemanticsDebuggerDemoState();
}

class _SemanticsDebuggerDemoState extends State<_SemanticsDebuggerDemo> {
  var _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Overlay'),
            Switch(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
        FwSemanticsDebugger(
          enabled: _enabled,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Checkout'),
                  const SizedBox(height: 8),
                  FwButton(label: 'Pay now', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
