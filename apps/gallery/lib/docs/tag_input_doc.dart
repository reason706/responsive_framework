import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import '../component_doc.dart';

/// Doc board for FwTagInput (+F25).
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired in here so the catalog edit stays a separate reviewable step):
///
/// ```dart
/// import 'docs/tag_input_doc.dart';
/// // inside the catalog children list, e.g. under Molecules:
/// tagInputDoc(),
/// ```
Widget tagInputDoc() => const ComponentDoc(
  id: 'F25',
  name: 'Tag input',
  tier: 'Molecules',
  summary:
      'Inline chip editor for short token lists: skills, recipients, labels, '
      'filters. Typing a separator (comma/semicolon) or Enter commits the '
      'text as a tag; Backspace on empty input removes the last tag. '
      'Controlled via value/onChanged, integrates with Form, and supports '
      'maxTags, per-tag validation, and duplicate policy.',
  notFor: 'free-form long text (use FwTextArea), or @-mention overlays',
  anatomy: const [
    AnatomyPart('Chips', 'FwChip input kind; delete button per tag.'),
    AnatomyPart('Input', 'borderless text field; commits on Enter/separator.'),
    AnatomyPart('Shell', 'FwField label, description, error live region.'),
  ],
  properties: const _TagInputDemo(),
  layoutSpecs: const [
    LayoutSpec('Wrap', 'chips flow; input keeps a 96px minimum width.'),
    LayoutSpec('Gaps', 'token spacing between chips and rows.'),
    LayoutSpec('Box', 'filled container, md radius, 2px focus/error border.'),
  ],
  dos: const [
    'Trim and validate at commit time; show why a tag was rejected.',
    'Keep Backspace-delete; keyboard users expect it.',
    'Cap with maxTags for bounded lists.',
  ],
  donts: const [
    'Don\u2019t silently drop duplicates — say the tag is already added.',
    'Don\u2019t use for sentences; tags are tokens, not prose.',
  ],
  a11y: const [
    'Each chip remove button is focusable with a “Remove …” tooltip.',
    'Backspace removal keeps focus in the input.',
    'Rejections are announced via the error live region.',
  ],
);

class _TagInputDemo extends StatefulWidget {
  const _TagInputDemo();

  @override
  State<_TagInputDemo> createState() => _TagInputDemoState();
}

class _TagInputDemoState extends State<_TagInputDemo> {
  var _tags = <String>['dart', 'flutter'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwTagInput(
          label: 'Skills',
          hintText: 'Type and press Enter',
          description: 'Comma also commits. Backspace removes.',
          value: _tags,
          onChanged: (v) => setState(() => _tags = v),
          maxTags: 6,
        ),
        const SizedBox(height: 8),
        Text('Tags: ${_tags.join(', ')}'),
      ],
    );
  }
}
