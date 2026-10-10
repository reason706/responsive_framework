import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import '../component_doc.dart';

/// Doc board for FwAutoSkeleton (stretch: skeletonizer-style auto bones).
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired in here so the catalog edit stays a separate reviewable step):
///
/// ```dart
/// import 'docs/auto_skeleton_doc.dart';
/// // inside the catalog children list, e.g. under Molecules:
/// autoSkeletonDoc(),
/// ```
Widget autoSkeletonDoc() => const ComponentDoc(
  id: 'B13',
  name: 'Auto skeleton',
  tier: 'Molecules',
  summary:
      'Skeletonizer-style loading placeholder: lays out the real child but '
      'paints bone rects for each leaf render box instead of the content. '
      'No hand-maintained shimmer duplicates — the bones always match the '
      'layout. Static bones in the token skeleton color; swap the subtree '
      'when data arrives.',
  notFor:
      'animated shimmer sweeps (use FwSkeleton), or content that must '
      'stay readable to assistive tech while loading',
  anatomy: const [
    AnatomyPart('Child', 'laid out for real, never painted.'),
    AnatomyPart('Bones', 'one rounded rect per leaf box, token color.'),
    AnatomyPart('Fallback', 'full-box bone when nothing measurable.'),
  ],
  properties: const _AutoSkeletonDemo(),
  layoutSpecs: const [
    LayoutSpec('Sizing', 'skeleton sizes exactly to the child subtree.'),
    LayoutSpec('Radius', '6px bone corners by default; configurable.'),
    LayoutSpec('Color', 'FwColorRole token; no raw colors in the API.'),
  ],
  dos: const [
    'Feed it the real content widget with placeholder data.',
    'Swap to real content with AnimatedSwitcher for a smooth handoff.',
  ],
  donts: const [
    'Don\u2019t nest auto skeletons — one per loading region.',
    'Don\u2019t rely on it for semantics; manage loading announcements '
        'at the swap site.',
  ],
  a11y: const [
    'Bones are decorative; announce loading state where you swap.',
    'Keep the skeleton visible long enough to avoid flashing.',
  ],
);

class _AutoSkeletonDemo extends StatefulWidget {
  const _AutoSkeletonDemo();

  @override
  State<_AutoSkeletonDemo> createState() => _AutoSkeletonDemoState();
}

class _AutoSkeletonDemoState extends State<_AutoSkeletonDemo> {
  var _loading = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Loading'),
            Switch(
              value: _loading,
              onChanged: (v) => setState(() => _loading = v),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _loading
              ? const FwAutoSkeleton(
                  key: ValueKey('skeleton'),
                  child: _ProfileTemplate(),
                )
              : const _ProfileTemplate(key: ValueKey('content')),
        ),
      ],
    );
  }
}

class _ProfileTemplate extends StatelessWidget {
  const _ProfileTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ada Lovelace', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('First programmer · Analytical Engine'),
        SizedBox(height: 4),
        Text('London, UK'),
      ],
    );
  }
}
