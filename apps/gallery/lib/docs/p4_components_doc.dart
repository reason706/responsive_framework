import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import '../component_doc.dart';

/// Doc boards for the P4 (improvement-plan-2) components: FwBanner,
/// FwShimmer, FwHoverCard, FwCommandPalette, FwDescriptionList,
/// FwSideSheet.
///
/// Registration (parent adds to main.dart — this file is deliberately
/// not wired in there so the catalog edit stays a separate reviewable
/// step):
///
/// ```dart
/// import 'docs/p4_components_doc.dart';
/// // inside the TierSection children lists in main.dart:
/// // Molecules tier:
/// bannerDoc(),
/// const SizedBox(height: 16),
/// shimmerDoc(),
/// const SizedBox(height: 16),
/// hoverCardDoc(),
/// const SizedBox(height: 16),
/// descriptionListDoc(),
/// // Organisms tier:
/// commandPaletteDoc(),
/// const SizedBox(height: 16),
/// sideSheetDoc(),
/// ```
///
/// (catalog.dart already imports this file, so the symbols resolve.)

// ---------------------------------------------------------------------------
// FwBanner.
// ---------------------------------------------------------------------------

Widget bannerDoc() => const ComponentDoc(
  id: 'BNR',
  name: 'Banner',
  tier: 'Molecules',
  summary:
      'Persistent page-level messaging: a full-width intent-tinted strip '
      'for maintenance windows, announcements, and quota warnings. Stays '
      'until dismissed or the condition clears — unlike toasts (transient) '
      'and FwAlert (inline card).',
  notFor:
      'transient confirmations (use a toast) or inline form errors '
      '(use FwAlert)',
  anatomy: [
    AnatomyPart('Intent icon', 'Severity glyph, token-colored.'),
    AnatomyPart('Title', 'Bold headline; keep under ~80 characters.'),
    AnatomyPart('Body', 'Optional supporting text.'),
    AnatomyPart('Action', 'Optional slot, typically a text button.'),
    AnatomyPart('Dismiss', 'Optional close button with tooltip.'),
  ],
  properties: const _BannerDemo(),
  layoutSpecs: [
    LayoutSpec('Width', 'Always full-bleed; never inset like a card.'),
    LayoutSpec('Padding', 's4 horizontal, s3 vertical (token).'),
    LayoutSpec('Elevation', 'Defaults to 0 — banners sit in page flow.'),
  ],
  dos: [
    'Use for page-level conditions the user should know about.',
    'Keep the title short; put detail in the body.',
    'Set announce when the banner appears dynamically.',
  ],
  donts: [
    'Don\'t stack multiple banners — one condition, one banner.',
    'Don\'t use for transient success (that\'s a toast).',
  ],
  a11y: [
    'Opt-in live region via announce for dynamic banners.',
    'Dismiss button carries a tooltip for screen readers.',
    'Intent is never color-only — the icon carries it too.',
  ],
);

class _BannerDemo extends StatefulWidget {
  const _BannerDemo();
  @override
  State<_BannerDemo> createState() => _BannerDemoState();
}

class _BannerDemoState extends State<_BannerDemo> {
  var _showWarning = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FwBanner(
          intent: FwAlertIntent.info,
          title: 'New dashboard available',
          body: 'Try the redesigned analytics view.',
          announce: true,
        ),
        const SizedBox(height: 8),
        if (_showWarning)
          FwBanner(
            intent: FwAlertIntent.warning,
            title: 'Quota at 90%',
            action: TextButton(onPressed: () {}, child: const Text('Upgrade')),
            onDismiss: () => setState(() => _showWarning = false),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FwShimmer.
// ---------------------------------------------------------------------------

Widget shimmerDoc() => const ComponentDoc(
  id: 'SHM',
  name: 'Shimmer',
  tier: 'Molecules',
  summary:
      'Animated shimmer sweep for skeleton loading states. Wraps any '
      'placeholder — or composes with FwAutoSkeleton via FwShimmer.bones '
      'for auto-derived bones with motion. Honors reduced motion.',
  notFor:
      'static placeholders (use FwSkeleton) or progress (use FwLinearProgress)',
  anatomy: [
    AnatomyPart('Child', 'The placeholder the sweep travels across.'),
    AnatomyPart('Sweep', 'Gradient band, 1500ms per pass by default.'),
  ],
  properties: const _ShimmerDemo(),
  layoutSpecs: [
    LayoutSpec('Sizing', 'Sizes to its child; bones hug content shape.'),
  ],
  dos: [
    'Compose with FwAutoSkeleton for bones from a real tree.',
    'Disable (enabled: false) when content is ready, not by removing.',
  ],
  donts: [
    'Don\'t shimmer real content — only placeholders.',
    'Don\'t rely on motion to convey state; it\'s decorative.',
  ],
  a11y: [
    'Suppressed automatically under reduced motion.',
    'Semantics excluded — screen readers skip the shimmer.',
  ],
);

class _ShimmerDemo extends StatefulWidget {
  const _ShimmerDemo();
  @override
  State<_ShimmerDemo> createState() => _ShimmerDemoState();
}

class _ShimmerDemoState extends State<_ShimmerDemo> {
  var _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Shimmer'),
            Switch(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
        FwShimmer.bones(
          enabled: _enabled,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ada Lovelace',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('First programmer · Analytical Engine'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FwHoverCard.
// ---------------------------------------------------------------------------

Widget hoverCardDoc() => const ComponentDoc(
  id: 'HVC',
  name: 'Hover card',
  tier: 'Molecules',
  summary:
      'Supplementary info revealed on hover or keyboard focus. Richer '
      'than a tooltip, lighter than a popover — no tap or controller '
      'needed. Follows WCAG 1.4.13: dismissible, hoverable, persistent.',
  notFor:
      'critical actions (never hover-only content) or plain text hints '
      '(use FwTooltip)',
  anatomy: [
    AnatomyPart('Anchor', 'The hovered/focused widget.'),
    AnatomyPart('Card', 'Rich content in an elevated card.'),
  ],
  properties: const _HoverCardDemo(),
  layoutSpecs: [
    LayoutSpec('Placement', 'Logical bottom/top/start/end; RTL-aware.'),
    LayoutSpec('Max width', '320dp default.'),
    LayoutSpec('Elevation', 'Defaults to 3 with tonal surface.'),
  ],
  dos: [
    'Keep card content supplementary — keyboard users get it via focus.',
    'Provide focusNode when driving focus programmatically.',
  ],
  donts: [
    'Don\'t put the only path to an action inside a hover card.',
    'Don\'t use for touch-primary flows (no hover on touch).',
  ],
  a11y: [
    'Keyboard focus shows the card — no hover required.',
    'Moving onto the card keeps it open (WCAG 1.4.13 hoverable).',
    'No hover-only content: everything must be reachable by focus.',
  ],
);

class _HoverCardDemo extends StatelessWidget {
  const _HoverCardDemo();
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      children: [
        FwHoverCard(
          anchor: Chip(label: Text('Ada Lovelace')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ada Lovelace',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Mathematician · First programmer'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FwCommandPalette.
// ---------------------------------------------------------------------------

Widget commandPaletteDoc() => const ComponentDoc(
  id: 'CPL',
  name: 'Command palette',
  tier: 'Organisms',
  summary:
      'Keyboard-first command launcher. Fuzzy-filters commands as you '
      'type; ArrowUp/Down moves, Enter selects, Escape dismisses. Static '
      'lists filter locally; pass onQuery for an async source.',
  notFor: 'small fixed option sets (use FwSelect) or navigation (use search)',
  anatomy: [
    AnatomyPart('Query field', 'Autofocused search input.'),
    AnatomyPart('Results', 'Fuzzy-ranked command rows.'),
    AnatomyPart('Command', 'Icon, title, subtitle, keywords, trailing hint.'),
  ],
  properties: const _CommandPaletteDemo(),
  layoutSpecs: [
    LayoutSpec('Dialog', 'Max 640dp wide, top-anchored modal.'),
    LayoutSpec('Results', 'Scrollable list; maxResults caps length.'),
  ],
  dos: [
    'Add keywords for synonyms users will type.',
    'Return stable ids so selections survive reordering.',
    'Debounce onQuery in the caller for remote sources.',
  ],
  donts: [
    'Don\'t use for fewer than ~5 commands — a menu is simpler.',
    'Don\'t block on slow sources without the loading state.',
  ],
  a11y: [
    'Full keyboard operation: arrows, Enter, Escape.',
    'Active command is highlighted, not color-only.',
    'Dialog traps focus and announces as a dialog.',
  ],
);

class _CommandPaletteDemo extends StatelessWidget {
  const _CommandPaletteDemo();
  static const _commands = [
    FwCommand(
      id: 'new',
      title: 'Create new file',
      keywords: ['add', 'plus'],
      icon: Icons.add,
    ),
    FwCommand(
      id: 'open',
      title: 'Open file',
      subtitle: 'Browse workspace',
      icon: Icons.folder_open,
    ),
    FwCommand(id: 'close', title: 'Close editor', icon: Icons.close),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FwCommandPalette(commands: _commands, maxResults: 5),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () =>
              FwCommandPalette.show(context: context, commands: _commands),
          child: const Text('Open as modal'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FwDescriptionList.
// ---------------------------------------------------------------------------

Widget descriptionListDoc() => const ComponentDoc(
  id: 'DSL',
  name: 'Description list',
  tier: 'Molecules',
  summary:
      'Dense key-value list for metadata, settings summaries, and detail '
      'panels. Horizontal (table-like) or stacked rows; dividers optional. '
      'Row gaps use the density-scaled fieldGap alias.',
  notFor: 'tabular data with sorting (use FwDataTable) or forms (use fields)',
  anatomy: [
    AnatomyPart('Term', 'Label-role key, muted. Optional icon.'),
    AnatomyPart('Description', 'Any widget: text, link, badge.'),
  ],
  properties: const _DescriptionListDemo(),
  layoutSpecs: [
    LayoutSpec('Columns', 'termFlex/descriptionFlex, default 2:3.'),
    LayoutSpec('Row gap', 'Density-scaled fieldGap; override with rowGap.'),
  ],
  dos: [
    'Use stacked layout on narrow screens.',
    'Keep terms short — they\'re labels, not sentences.',
  ],
  donts: [
    'Don\'t use for more than ~12 pairs — consider a table.',
    'Don\'t put interactive controls as terms.',
  ],
  a11y: [
    'Terms and descriptions read in order for screen readers.',
    'Compacts under FwDensityScope without shrinking touch targets.',
  ],
);

class _DescriptionListDemo extends StatefulWidget {
  const _DescriptionListDemo();
  @override
  State<_DescriptionListDemo> createState() => _DescriptionListDemoState();
}

class _DescriptionListDemoState extends State<_DescriptionListDemo> {
  var _layout = FwDescriptionListLayout.horizontal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<FwDescriptionListLayout>(
          segments: const [
            ButtonSegment(
              value: FwDescriptionListLayout.horizontal,
              label: Text('Horizontal'),
            ),
            ButtonSegment(
              value: FwDescriptionListLayout.stacked,
              label: Text('Stacked'),
            ),
          ],
          selected: {_layout},
          onSelectionChanged: (s) => setState(() => _layout = s.first),
        ),
        const SizedBox(height: 8),
        FwDescriptionList(
          layout: _layout,
          divided: true,
          items: const [
            FwDescriptionItem(term: 'Name', description: Text('Ada Lovelace')),
            FwDescriptionItem(term: 'Role', description: Text('Mathematician')),
            FwDescriptionItem(
              term: 'Known for',
              description: Text('First computer program'),
              icon: Icons.star_outline,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FwSideSheet.
// ---------------------------------------------------------------------------

Widget sideSheetDoc() => const ComponentDoc(
  id: 'SHS',
  name: 'Side sheet',
  tier: 'Organisms',
  summary:
      'Modal sheet anchored to the leading or trailing edge — the '
      'complement to the bottom sheet for wide layouts, detail panels, '
      'and filters. Slides in RTL-aware; completes with a typed result.',
  notFor: 'phone-primary flows (use the bottom sheet) or non-modal panels',
  anatomy: [
    AnatomyPart('Header', 'Title plus close button.'),
    AnatomyPart('Content', 'Scrollable body with overlay inset.'),
    AnatomyPart('Scrim', 'Dismissible barrier.'),
  ],
  properties: const _SideSheetDemo(),
  layoutSpecs: [
    LayoutSpec('Width', 'Fixed 360dp default; set per content.'),
    LayoutSpec('Side', 'Logical start/end — flips in RTL.'),
    LayoutSpec('Elevation', 'Defaults to 1 with tonal surface.'),
  ],
  dos: [
    'Use for filters and detail panels on wide screens.',
    'Prefer side: end (trailing) unless leading fits the flow.',
  ],
  donts: [
    'Don\'t use on narrow phones — the bottom sheet adapts better.',
    'Don\'t nest sheets; one modal at a time.',
  ],
  a11y: [
    'Barrier labeled "Dismiss" for screen readers.',
    'Focus is trapped in the modal while open.',
    'Close button has a tooltip.',
  ],
);

class _SideSheetDemo extends StatelessWidget {
  const _SideSheetDemo();
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        TextButton(
          onPressed: () => FwSideSheet.showModal(
            context: context,
            title: const Text('Filters'),
            content: const Text('Filter controls go here.'),
          ),
          child: const Text('Open trailing sheet'),
        ),
        TextButton(
          onPressed: () => FwSideSheet.showModal(
            context: context,
            title: const Text('Details'),
            content: const Text('Detail content goes here.'),
            side: FwSideSheetSide.start,
          ),
          child: const Text('Open leading sheet'),
        ),
      ],
    );
  }
}
