import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import 'component_doc.dart';

/// ImageProvider that always fails, for the offline/error demo.
class _FailingProvider extends ImageProvider<_FailingProvider> {
  @override
  Future<_FailingProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FailingProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('load failed')),
    );
  }
}

// Minimal 1x1 transparent PNG (same bytes as the media tests).
Uint8List get _png => Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

/// Shared wrap for property matrices: keeps source/focus order and never
/// overflows narrow screens.
Widget _matrix(List<Widget> children) => Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

// ---------------------------------------------------------------------------
// Foundations tier: Wave 0 token boards.
// ---------------------------------------------------------------------------

/// Wave 0 token specimens: motion, elevation, grid, haptics.
Widget tokenBoards() {
  return Builder(
    builder: (context) {
      final theme = context.fwTheme;
      final typeScale = theme.typeScale;
      Widget board(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: typeScale.resolve(FwTextRole.h4, context)),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 16),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          board(
            'Motion durations',
            _matrix([
              for (final speed in FwMotionSpeed.values)
                Chip(
                  label: Text(
                    '${speed.name}: ${theme.motion.durationFor(context, speed).inMilliseconds}ms',
                  ),
                ),
            ]),
          ),
          board(
            'Elevation levels 0–5',
            _matrix([
              for (var level = 0; level <= 5; level++)
                Container(
                  width: 72,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const FwElevation().decoration(context, level),
                  child: Text(
                    '$level',
                    style: typeScale.resolve(FwTextRole.label, context),
                  ),
                ),
            ]),
          ),
          board(
            'Grid tokens',
            Builder(
              builder: (context) {
                final spec = const FwGrid().of(context);
                return Text(
                  'Viewport class ${FwGrid.classOf(MediaQuery.sizeOf(context).width).name}: '
                  '${spec.columns} columns · '
                  'gutter ${spec.gutter.resolve(context).toStringAsFixed(0)}px · '
                  'margin ${spec.margin.resolve(context).toStringAsFixed(0)}px',
                  style: typeScale.resolve(FwTextRole.bodySm, context),
                );
              },
            ),
          ),
          board(
            'Haptics',
            Text(
              'Tap/confirm/error/selection signals route through FwHaptics. '
              'They are skipped under accessible navigation or when the '
              'theme disables them — no gesture in this gallery vibrates.',
              style: typeScale.resolve(FwTextRole.bodySm, context),
            ),
          ),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Atoms.
// ---------------------------------------------------------------------------

Widget buttonDoc() => ComponentDoc(
  id: 'A01',
  name: 'Button',
  tier: 'Atoms',
  summary:
      'The primary action control. Visual variant (solid, tonal, outline, '
      'ghost, link) is separate from semantic intent (primary, neutral, '
      'success, warning, danger, info): a destructive action is a solid '
      'danger button, not a red-styled primary. Icons use logical '
      'start/end/top/bottom/only placement with an 8px token gap.',
  notFor: 'navigation (use FwLink)',
  anatomy: const [
    AnatomyPart('Label', 'label role; wraps instead of truncating.'),
    AnatomyPart(
      'Container',
      'intent colors from FwButtonColors (layer-3 tokens); state-layer '
          'overlays for hover/pressed/focus.',
    ),
    AnatomyPart(
      'Icon',
      'icon + iconPosition (start/end flip in RTL; top/bottom stack; '
          'only = square, needs semanticLabel).',
    ),
    AnatomyPart('Focus ring', 'focusRing token, visible on all intents.'),
  ],
  properties: _matrix([
    for (final intent in FwIntent.values)
      FwButton(label: intent.name, intent: intent, onPressed: () {}),
    for (final variant in FwButtonVariant.values)
      FwButton(label: variant.name, variant: variant, onPressed: () {}),
    for (final size in FwSize.values)
      FwButton(label: size.name, size: size, onPressed: () {}),
    for (final position in FwIconPosition.values)
      if (position == FwIconPosition.only)
        const FwButton.icon(
          icon: Icon(Icons.add),
          semanticLabel: 'Add',
          onPressed: null,
        )
      else
        FwButton(
          label: position.name,
          icon: const Icon(Icons.star),
          iconPosition: position,
          onPressed: () {},
        ),
    const FwButton(label: 'Disabled', onPressed: null),
    // The loading state is demonstrated live: tap to run the async action.
    FwAsyncButton(
      label: 'Save',
      onPressed: () => Future.delayed(const Duration(seconds: 2)),
    ),
    const FwFab(icon: Icon(Icons.add), tooltip: 'Create', onPressed: null),
    const FwFab(
      icon: Icon(Icons.add),
      label: 'Create',
      tooltip: 'Create',
      onPressed: null,
    ),
  ]),
  layoutSpecs: const [
    LayoutSpec('Minimum target', '48 × 48 logical pixels, every size.'),
    LayoutSpec(
      'Padding',
      'controlInline × size factor horizontally, controlBlock × size '
          'factor vertically.',
    ),
    LayoutSpec(
      'Radius',
      'shape token: stadium → pill, rounded → md, sharp → none.',
    ),
    LayoutSpec('Label', 'grows and wraps; never clipped.'),
    LayoutSpec(
      'Loading width',
      'keepWidthWhileLoading holds the idle width via an invisibly '
          'maintained layer; no layout jump.',
    ),
  ],
  dos: const [
    'Separate variant from intent; let the intent carry the meaning.',
    'Own busy state in the caller; label the busy state ("Saving…").',
  ],
  donts: const [
    "Don't convey meaning by color alone — pair intent with label or icon.",
    "Don't invoke actions from disabled or busy buttons.",
  ],
  a11y: const [
    'Native button semantics; Enter/Space activate exactly once.',
    'Busy buttons expose a live region with the loading label.',
    'Enlarged text wraps inside the 48px-minimum target.',
  ],
);

Widget iconButtonDoc() => ComponentDoc(
  id: 'A02',
  name: 'Icon button',
  tier: 'Atoms',
  summary:
      'Icon-only action with a guaranteed minimum touch target, even when '
      'the glyph is small. Variants: filled, tonal, outline, ghost; '
      'optional selected toggle state.',
  notFor: 'labeled actions (use FwButton), non-interactive icons (use FwIcon)',
  anatomy: const [
    AnatomyPart('Glyph', '1.25rem icon; decorative inside the button.'),
    AnatomyPart('Container', 'variant fill from semantic roles.'),
    AnatomyPart('Target', '48px hit area regardless of glyph size.'),
    AnatomyPart('Name', 'tooltip doubles as the accessible name.'),
  ],
  properties: _matrix([
    for (final variant in FwIconButtonVariant.values)
      FwIconButton(
        icon: const Icon(Icons.favorite),
        tooltip: 'Favorite (${variant.name})',
        variant: variant,
        onPressed: () {},
      ),
    FwIconButton(
      icon: const Icon(Icons.favorite),
      tooltip: 'Selected',
      selected: true,
      onPressed: () {},
    ),
    const FwIconButton(
      icon: Icon(Icons.favorite),
      tooltip: 'Disabled',
      onPressed: null,
    ),
  ]),
  layoutSpecs: const [
    LayoutSpec('Minimum target', '48 × 48 logical pixels.'),
    LayoutSpec('Glyph', '1.25rem; optical size independent of target.'),
    LayoutSpec('Selected', 'tonal fill + selected semantics.'),
  ],
  dos: const [
    'Always provide a tooltip — it is the accessible name.',
    'Use the selected toggle for on/off toolbar actions.',
  ],
  donts: const [
    "Don't shrink the target to the glyph size.",
    "Don't use for actions that need a visible label.",
  ],
  a11y: const [
    'Tooltip is exposed as the semantic label.',
    'Selected state uses selected semantics, not color alone.',
  ],
);

/// A08 FAB + speed dial doc board.
Widget fabDoc() => ComponentDoc(
  id: 'A08',
  name: 'FAB & speed dial',
  tier: 'Molecules',
  summary:
      'Floating action button for the primary screen action, with an '
      'optional speed-dial expansion for 2–5 related actions. The dial '
      'opens with a staggered scale/fade and closes on scrim tap or '
      'Escape.',
  notFor: 'toolbars (use FwButton), more than 5 dial actions (use a menu)',
  anatomy: const [
    AnatomyPart('FAB', 'circular or extended; intent-tinted container.'),
    AnatomyPart('Dial', 'child actions fan out above the FAB.'),
    AnatomyPart('Scrim', 'dismisses the dial; not a modal barrier.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 16,
        children: [
          FwFab(icon: const Icon(Icons.add), tooltip: 'Create', onPressed: () {}),
          FwFab(
            icon: const Icon(Icons.edit),
            label: 'Compose',
            tooltip: 'Compose',
            onPressed: () {},
          ),
          const FwFab(
            icon: Icon(Icons.add),
            tooltip: 'Disabled',
            onPressed: null,
          ),
        ],
      ),
      const SizedBox(height: 16),
      FwSpeedDial(
        icon: const Icon(Icons.add),
        tooltip: 'Actions',
        children: [
          FwSpeedDialChild(
            icon: const Icon(Icons.edit),
            label: 'Edit',
            onTap: () {},
          ),
          FwSpeedDialChild(
            icon: const Icon(Icons.share),
            label: 'Share',
            onTap: () {},
          ),
        ],
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Placement', 'app positions; 16px from screen edges.'),
    LayoutSpec('Dial', 'children stack above with 12px gaps.'),
  ],
  dos: const [
    'Use one FAB per screen for the primary action.',
    'Label every dial child; the FAB needs a tooltip.',
  ],
  donts: const ["Don't use a FAB for destructive or navigation actions."],
  a11y: const [
    'Dial children are buttons in a menu-like group.',
    'Escape and scrim tap close the dial and return focus.',
  ],
);

Widget closeButtonDoc() => ComponentDoc(
  id: 'A07',
  name: 'Close button',
  tier: 'Atoms',
  summary:
      'Thin FwIconButton specialization for dismiss actions: standard close '
      'glyph, localized name, optional destructive context. The parent owns '
      'dismissal.',
  notFor: 'back navigation (use a back affordance), canceling forms',
  anatomy: const [
    AnatomyPart('Glyph', 'standard close icon.'),
    AnatomyPart('Name', 'localized "Close" accessible name.'),
    AnatomyPart('Context', 'destructive tints the glyph for danger zones.'),
  ],
  properties: _matrix([
    FwCloseButton(onPressed: () {}),
    FwCloseButton(onPressed: () {}, destructive: true),
    const FwCloseButton(onPressed: null),
  ]),
  layoutSpecs: const [
    LayoutSpec('Minimum target', '48 × 48 logical pixels.'),
    LayoutSpec('Destructive', 'error-role glyph, same target.'),
  ],
  dos: const [
    'Let the parent own dismissal; the button only signals intent.',
    'Use destructive inside destructive contexts (delete dialogs).',
  ],
  donts: const ["Don't repurpose as a generic icon button."],
  a11y: const [
    'Localized close label announced to screen readers.',
    'Clear hover/focus indication like every icon button.',
  ],
);

Widget textDoc() => const ComponentDoc(
  id: 'T01',
  name: 'Text',
  tier: 'Atoms',
  summary:
      'Body, lead, caption, display, and h1–h6 roles resolved from '
      'FwTypography. Heading semantics are separate from visual size: a '
      'visual h3 can carry heading level 2 when the outline demands it.',
  notFor: 'interactive text (use FwLink), rich inline styles (T02)',
  anatomy: [
    AnatomyPart('Run', 'typography role: size, weight, line height.'),
    AnatomyPart('Heading flag', 'semantic heading level, independent.'),
    AnatomyPart('Truncation', 'explicit maxLines/overflow only.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwText('Display', role: FwTextRole.displaySm, heading: true),
      FwText('Heading 2', role: FwTextRole.h2, heading: true),
      FwText('Lead paragraph for introductions.', role: FwTextRole.lead),
      FwText('Body text at 1rem with 1.5 line height.'),
      FwText('Caption for secondary annotations.', role: FwTextRole.caption),
      FwText('Selectable body — long-press to select.', selectable: true),
      FwText(
        'Truncated after one line with an explicit ellipsis…',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
  layoutSpecs: [
    LayoutSpec('Sizes', 'declared in rem; scaler applies once at render.'),
    LayoutSpec('Line height', 'multiplier per role, never clipped.'),
    LayoutSpec('Truncation', 'opt-in only; essential text wraps.'),
  ],
  dos: [
    'Pick the role for meaning; set heading: true for outline levels.',
    'Let essential text wrap and grow its container.',
  ],
  donts: [
    "Don't fix label heights or cap the text scale.",
    "Don't use caption for critical instructions.",
  ],
  a11y: [
    'Heading semantics announced independently of visual size.',
    'System TextScaler applies exactly once — no double scaling.',
    'No forced truncation for form labels or instructions.',
  ],
);

Widget linkDoc() => ComponentDoc(
  id: 'A03 / T03',
  name: 'Link',
  tier: 'Atoms',
  summary:
      'Text action for navigation. One implementation for inline and '
      'standalone links: underline is the non-color cue, an external icon '
      'marks off-site destinations, and URI handling stays with the app.',
  notFor: 'form submission or in-place actions (use FwButton)',
  anatomy: const [
    AnatomyPart('Label', 'body role, underlined.'),
    AnatomyPart('Cue', 'external icon for off-site destinations.'),
    AnatomyPart('Target', 'InkWell with focus/hover state layers.'),
  ],
  properties: _matrix([
    FwLink(label: 'Standalone link', onTap: () {}),
    FwLink(
      label: 'External docs',
      uri: Uri.parse('https://example.com'),
      external: true,
      onTap: () {},
    ),
    const FwLink(label: 'Disabled link', enabled: false),
  ]),
  layoutSpecs: const [
    LayoutSpec('Gap', 's1 between label, leading, and external cue.'),
    LayoutSpec('Padding', 's1/2 vertical for a comfortable tap row.'),
    LayoutSpec('Radius', 'sm focus/hover layer.'),
  ],
  dos: const [
    'Keep the underline — it is the tested non-color cue.',
    'Expose the destination URI to semantics.',
  ],
  donts: const [
    "Don't navigate and submit from the same control.",
    "Don't disable a link without explicit disabled semantics.",
  ],
  a11y: const [
    'Link role with enabled state; keyboard focusable.',
    'External cue is decorative; the URI is in the semantics value.',
  ],
);

Widget badgeDoc() => ComponentDoc(
  id: 'T04',
  name: 'Badge',
  tier: 'Atoms',
  summary:
      'Noninteractive status marker: count, dot, or short label. Variants '
      'solid, subtle, outline; any intent. Screen readers hear the full '
      'count even when the visual text is abbreviated ("99+").',
  notFor: 'anything tappable (use FwChip), long text',
  anatomy: const [
    AnatomyPart('Content', 'count, dot, or label.'),
    AnatomyPart('Container', 'variant fill from intent roles.'),
    AnatomyPart('Label', 'semanticLabel overrides the announced text.'),
  ],
  properties: _matrix(const [
    FwBadge(count: 128),
    FwBadge(count: 5, variant: FwBadgeVariant.subtle, intent: FwIntent.success),
    FwBadge(
      label: 'New',
      variant: FwBadgeVariant.outline,
      intent: FwIntent.info,
    ),
    FwBadge(dot: true, intent: FwIntent.danger),
  ]),
  layoutSpecs: const [
    LayoutSpec('Shape', 'pill; radius scales with content.'),
    LayoutSpec('Dot', '8px indicator with semantic label.'),
    LayoutSpec('Overflow', 'counts abbreviate at 99+.'),
  ],
  dos: const [
    'Give dots and abbreviated counts an accessible label.',
    'Keep badge text to a word or a count.',
  ],
  donts: const [
    "Don't make badges interactive — they carry no button semantics.",
    "Don't use color as the only status signal.",
  ],
  a11y: const [
    'Full count announced; "99+" never read literally.',
    'Noninteractive: excluded from the focus order.',
  ],
);

Widget chipDoc() => ComponentDoc(
  id: 'T05',
  name: 'Chip',
  tier: 'Atoms',
  summary:
      'Compact interactive tag: assist, filter, or input kinds. Supports '
      'leading icon/avatar, selected state, and removal. Selection and '
      'removal are separate callbacks and separate semantic actions.',
  notFor: 'static status (use FwBadge), long-form choices (use selects)',
  anatomy: const [
    AnatomyPart('Label', 'label role, single line.'),
    AnatomyPart('Leading', 'optional icon or avatar slot.'),
    AnatomyPart('Remove', 'input kind: delete action with tooltip.'),
    AnatomyPart('State', 'selected fill + selected semantics.'),
  ],
  properties: _matrix(const [
    FwChip(label: 'Assist', leading: Icon(Icons.add, size: 16)),
    FwChip(label: 'Filter', kind: FwChipKind.filter, selected: true),
    FwChip(label: 'Removable', kind: FwChipKind.input),
  ]),
  layoutSpecs: const [
    LayoutSpec('Height', 'grows with label; 48px target when interactive.'),
    LayoutSpec('Radius', 'pill.'),
    LayoutSpec('Remove', 'dedicated hit area, "Remove" tooltip.'),
  ],
  dos: const [
    'Use filter kind for multi-select facets; input kind for entered values.',
    'Keep removal and selection as distinct actions.',
  ],
  donts: const ["Don't overload one tap with select-then-remove."],
  a11y: const [
    'Removal works from keyboard and semantics actions.',
    'Selected state announced, not just shown.',
  ],
);

Widget dividerDoc() => const ComponentDoc(
  id: 'T06',
  name: 'Divider',
  tier: 'Atoms',
  summary:
      'Token-ruled separator: horizontal or vertical, with optional inset '
      'and label. Decorative dividers (no label) are excluded from '
      'semantics.',
  notFor: 'spacing alone (use gaps), interactive separators',
  anatomy: [
    AnatomyPart('Rule', '1px hairline from border tokens.'),
    AnatomyPart('Label', 'optional centered text with gaps.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwDivider(),
      SizedBox(height: 8),
      FwDivider(label: Text('labeled')),
      SizedBox(height: 8),
      SizedBox(
        height: 48,
        child: Row(children: [Text('a'), FwDivider(vertical: true), Text('b')]),
      ),
    ],
  ),
  layoutSpecs: [
    LayoutSpec('Thickness', '1px hairline; never scales with root.'),
    LayoutSpec('Label gap', 's2 on each side.'),
    LayoutSpec('Vertical', 'needs a bounded height from the parent.'),
  ],
  dos: [
    'Label the divider when it carries meaning.',
    'Bound the height of vertical dividers explicitly.',
  ],
  donts: ["Don't announce decorative dividers to screen readers."],
  a11y: [
    'Decorative dividers are excluded from semantics.',
    'Labeled dividers expose their text as a separator label.',
  ],
);

Widget iconDoc() => ComponentDoc(
  id: 'M05',
  name: 'Icon',
  tier: 'Atoms',
  summary:
      'Glyph with size and role color. Decorative by default; pass a '
      'semanticLabel to make it meaningful. No vendor icon pack is forced — '
      'any IconData works.',
  notFor: 'interactive icons (use FwIconButton)',
  anatomy: const [
    AnatomyPart('Glyph', 'IconData, 24px default.'),
    AnatomyPart('Color', 'semantic role, not a raw color.'),
  ],
  properties: _matrix(const [
    FwIcon(Icons.favorite, color: FwColorRole.error),
    FwIcon(Icons.star, color: FwColorRole.warning),
    FwIcon(Icons.info, semanticLabel: 'Information'),
  ]),
  layoutSpecs: const [
    LayoutSpec('Size', 'logical pixels; 16/20/24 are the documented steps.'),
    LayoutSpec('Color', 'FwColorRole; decorative icons inherit.'),
  ],
  dos: const [
    'Label meaningful icons; leave decorative ones unlabeled.',
    'Size icons in logical pixels, independent of text scale.',
  ],
  donts: const ["Don't attach tap handlers — wrap in FwIconButton instead."],
  a11y: const [
    'Unlabeled icons are excluded from semantics.',
    'Labeled icons announce their semanticLabel.',
  ],
);

Widget avatarDoc() => ComponentDoc(
  id: 'M03',
  name: 'Avatar',
  tier: 'Atoms',
  summary:
      'Identity marker with a fallback chain: image provider, then '
      'initials, then icon. Fixed token diameters; optional status badge '
      'with a text meaning.',
  notFor: 'large imagery (use FwImage)',
  anatomy: const [
    AnatomyPart('Visual', 'image, initials, or icon fallback.'),
    AnatomyPart('Frame', 'circle or rounded; token diameter.'),
    AnatomyPart('Status', 'badge with statusLabel text.'),
  ],
  properties: _matrix(const [
    FwAvatar(
      name: 'Ada Lovelace',
      semanticLabel: 'Ada Lovelace',
      status: FwAvatarStatus.online,
      statusLabel: 'Online',
    ),
    FwAvatar(initials: 'XY', size: FwAvatarSize.lg),
    FwAvatar(size: FwAvatarSize.sm, shape: FwAvatarShape.rounded),
  ]),
  layoutSpecs: const [
    LayoutSpec('Diameters', 'xs 24 · sm 32 · md 40 · lg 56 · xl 72.'),
    LayoutSpec('Initials', 'caller-provided or grapheme clusters.'),
  ],
  dos: const [
    'Provide a semantic label for meaningful avatars.',
    'Give status badges a text meaning, not just a color.',
  ],
  donts: const ["Don't derive initials by naive string indexing."],
  a11y: const [
    'Status announced via statusLabel.',
    'Interactive avatars need an explicit interactive wrapper.',
  ],
);

Widget tooltipDoc() => const ComponentDoc(
  id: 'O05',
  name: 'Tooltip',
  tier: 'Atoms',
  summary:
      'Supplementary detail on hover, focus, or long-press. Never carries '
      'essential information — if it matters, put it in the layout.',
  notFor: 'essential instructions, rich content, touch-only discovery',
  anatomy: [
    AnatomyPart('Message', 'plain text; richMessage for formatting.'),
    AnatomyPart('Trigger', 'any child; hover/focus/long-press shows.'),
    AnatomyPart(
      'Container',
      'inverse surface at elevation; never essential content.',
    ),
  ],
  properties: FwTooltip(
    message: 'Supplementary detail, never essential',
    child: FwText('Hover, focus, or long-press me', role: FwTextRole.bodySm),
  ),
  layoutSpecs: [
    LayoutSpec('Wait', 'configurable waitDuration before showing.'),
    LayoutSpec('Position', 'preferBelow flips when space is short.'),
  ],
  dos: [
    'Use for supplementary detail on icon buttons.',
    'Keep messages short and plain.',
  ],
  donts: [
    "Don't hide essential information in a tooltip.",
    "Don't rely on hover for touch users.",
  ],
  a11y: [
    'Triggerable from keyboard focus, not just hover.',
    'Screen readers announce the message with the trigger.',
  ],
);

// ---------------------------------------------------------------------------
// Molecules.
// ---------------------------------------------------------------------------

Widget cardDoc() => ComponentDoc(
  id: 'D01',
  name: 'Card',
  tier: 'Molecules',
  summary:
      'Slot-based surface: header, media, content, actions compose freely. '
      'Variants elevated, outlined, filled. FwInteractiveCard is the '
      'explicit interactive wrapper — a card is never accidentally tappable.',
  notFor: 'page-level layout (use FwResponsiveLayout), list rows (use tiles)',
  anatomy: const [
    AnatomyPart('Header', 'optional title row slot.'),
    AnatomyPart('Media', 'optional image slot.'),
    AnatomyPart('Content', 'main body slot.'),
    AnatomyPart('Actions', 'button row slot; nested actions documented.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwInteractiveCard(
        onTap: () {},
        semanticLabel: 'Open article: responsive layouts',
        child: FwCard(
          header: const FwText('Featured', role: FwTextRole.label),
          content: const FwText(
            'Slots compose: header, media, content, actions. '
            'This card is explicitly interactive.',
            role: FwTextRole.body,
          ),
          actions: FwButton(
            label: 'Read more',
            variant: FwButtonVariant.link,
            onPressed: () {},
          ),
        ),
      ),
      const SizedBox(height: 8),
      const FwCard(
        variant: FwCardVariant.outlined,
        content: FwText('Outlined variant', role: FwTextRole.body),
      ),
      const SizedBox(height: 8),
      const FwCard(
        variant: FwCardVariant.filled,
        content: FwText('Filled variant', role: FwTextRole.body),
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Padding', 'cardInset alias (1rem default).'),
    LayoutSpec('Radius', 'lg token.'),
    LayoutSpec('Elevation', 'elevated variant uses elevation tokens.'),
  ],
  dos: const [
    'Use FwInteractiveCard when the whole card is one action.',
    'Keep nested actions keyboard-reachable and distinct.',
  ],
  donts: const [
    "Don't nest interactive cards inside interactive cards.",
    "Don't make a card tappable by wrapping it in a bare GestureDetector.",
  ],
  a11y: const [
    'Interactive cards expose button semantics with a label.',
    'Slot order matches the reading order.',
  ],
);

Widget listTileDoc() => const ComponentDoc(
  id: 'D02',
  name: 'List tile',
  tier: 'Molecules',
  summary:
      'One list row: leading, title, subtitle, trailing. Selected state is '
      'a first-class visual and semantic state.',
  notFor: 'grids of cards, single standalone rows',
  anatomy: [
    AnatomyPart('Leading', 'avatar or icon slot.'),
    AnatomyPart('Title', 'body role; subtitle in bodySm.'),
    AnatomyPart('Trailing', 'chevron, badge, or action slot.'),
    AnatomyPart('State', 'selected fill + selected semantics.'),
  ],
  properties: Column(
    children: [
      FwListTile(
        leading: FwAvatar(name: 'Ada Lovelace'),
        title: FwText('Ada Lovelace', role: FwTextRole.body),
        subtitle: FwText('Analytical engines', role: FwTextRole.bodySm),
        trailing: FwIcon(Icons.chevron_right),
      ),
      FwListTile(
        title: FwText('Grace Hopper', role: FwTextRole.body),
        subtitle: FwText('Compilers', role: FwTextRole.bodySm),
        selected: true,
      ),
    ],
  ),
  layoutSpecs: [
    LayoutSpec('Height', 'content-driven; 48px minimum target when tappable.'),
    LayoutSpec('Gaps', 's2 between slots; s1 title/subtitle.'),
  ],
  dos: [
    'Keep title to one line; let subtitle carry detail.',
    'Announce selection, not just highlight it.',
  ],
  donts: ["Don't truncate the title without a tooltip or wrap."],
  a11y: [
    'Selected tiles expose selected semantics.',
    'Tappable tiles meet the 48px target.',
  ],
);

Widget stackDoc() => ComponentDoc(
  id: 'L03',
  name: 'Stacks',
  tier: 'Molecules',
  summary:
      'FwHStack and FwVStack lay children out with a token gap; '
      'FwAdaptiveStack switches direction at a breakpoint. No Expanded is '
      'inserted under an invalid parent.',
  notFor: 'wrapping flows (use FwWrap), grids (use FwRow)',
  anatomy: const [
    AnatomyPart('Children', 'source order preserved in LTR and RTL.'),
    AnatomyPart('Gap', 'token gap; responsive gaps allowed.'),
    AnatomyPart('Breakpoint', 'adaptive stack flips at md by default.'),
  ],
  properties: Builder(
    builder: (context) {
      Widget tile(String label, Color color) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FwText(label, role: FwTextRole.label),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FwHStack(
            gap: FwSpace.s2,
            children: [
              tile('one', const Color(0xFFD9E7CB)),
              tile('two', const Color(0xFFCBDCE7)),
            ],
          ),
          const SizedBox(height: 8),
          FwVStack(
            gap: FwSpace.s2,
            children: [
              tile('three', const Color(0xFFE7E0CB)),
              tile('four', const Color(0xFFD9CBE7)),
            ],
          ),
          const SizedBox(height: 8),
          FwAdaptiveStack(
            gap: FwSpace.s3,
            children: [
              tile('adapts', const Color(0xFFD9E7CB)),
              tile('at md', const Color(0xFFCBDCE7)),
            ],
          ),
        ],
      );
    },
  ),
  layoutSpecs: const [
    LayoutSpec('Gap', 'FwSpace token; responsive via FwResponsiveLength.'),
    LayoutSpec('Adaptive', 'horizontal below md, vertical at/above.'),
    LayoutSpec('Alignment', 'cross-axis alignment explicit.'),
  ],
  dos: const [
    'Use the adaptive stack for control rows that stack on phones.',
    'Keep gaps on the 8px rhythm.',
  ],
  donts: const ["Don't insert Expanded where the parent forbids it."],
  a11y: const [
    'Source and focus order preserved across direction changes.',
    'RTL flips horizontal stacks automatically.',
  ],
);

Widget wrapDoc() => ComponentDoc(
  id: 'L04',
  name: 'Wrap',
  tier: 'Molecules',
  summary:
      'Theme-aware Wrap facade: flows children with gap and run gap, '
      'preserving source and focus order. The fix for narrow/large-text '
      'overflow in action rows.',
  notFor: 'single-row layouts that must not wrap',
  anatomy: const [
    AnatomyPart('Children', 'flow in source order.'),
    AnatomyPart('Gap', 'inline gap between items.'),
    AnatomyPart('Run gap', 'gap between lines.'),
  ],
  properties: FwWrap(
    gap: FwSpace.s2,
    runGap: FwSpace.s2,
    children: [
      for (var i = 0; i < 8; i++)
        FwChip(label: 'Tag $i', kind: FwChipKind.assist),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Gap', 'token; runGap independent.'),
    LayoutSpec('Alignment', 'directional alignment supported.'),
  ],
  dos: const [
    'Use for action rows and tag clouds that must survive 320px/2× text.',
    'Keep focus order identical to visual order.',
  ],
  donts: const ["Don't use Row where content can overflow narrow screens."],
  a11y: const [
    'Focus order follows the visual flow.',
    'Enlarged text wraps instead of clipping.',
  ],
);

Widget imageDoc() => ComponentDoc(
  id: 'M01',
  name: 'Image',
  tier: 'Molecules',
  summary:
      'Responsive image over any ImageProvider (asset, network, memory). '
      'Reserves its aspect ratio before load to avoid layout shift; '
      'placeholder while loading, error builder on failure, accessible '
      'label — or null for decorative images.',
  notFor: 'avatars (use FwAvatar), icons (use FwIcon)',
  anatomy: const [
    AnatomyPart('Provider', 'caller-supplied; no dart:io in core.'),
    AnatomyPart('Reservation', 'aspectRatio box prevents layout shift.'),
    AnatomyPart('States', 'placeholder, loaded, errorBuilder.'),
    AnatomyPart('Label', 'semanticLabel; null means decorative.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBDCE7)),
        ),
        child: FwImage(
          provider: MemoryImage(_png),
          aspectRatio: 16 / 9,
          borderRadius: FwRadius.md,
          semanticLabel: 'Demo photo (1×1 transparent)',
        ),
      ),
      const SizedBox(height: 8),
      FwImage(
        provider: _FailingProvider(),
        aspectRatio: 16 / 9,
        semanticLabel: 'Offline photo',
        errorBuilder: (context, error) => Container(
          alignment: Alignment.center,
          color: const Color(0xFFF5E0B8),
          padding: const EdgeInsets.all(16),
          child: const FwText(
            'Could not load — offline or failed. The label is kept.',
            role: FwTextRole.bodySm,
          ),
        ),
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Aspect', 'reserved up-front; 16/9 shown.'),
    LayoutSpec('Radius', 'FwRadius token clips the image.'),
    LayoutSpec('Fit', 'cover default; contain available.'),
  ],
  dos: const [
    'Always reserve the aspect ratio for remote images.',
    'Label meaningful images; mark decorative ones null.',
  ],
  donts: const [
    "Don't let layout shift when the image arrives.",
    "Don't depend on network in widget tests — use fakes.",
  ],
  a11y: const [
    'Decorative images are excluded from semantics.',
    'Error state keeps the accessible label.',
  ],
);

/// M02 figure doc board.
Widget figureDoc() => ComponentDoc(
  id: 'M02',
  name: 'Figure',
  tier: 'Molecules',
  summary:
      'Image with caption, credit, and optional action — the <figure> '
      'pattern. One semantic node announces the whole figure; the inner '
      'image label is suppressed to avoid duplication.',
  notFor: 'bare images (use FwImage), galleries (see Carousel)',
  anatomy: const [
    AnatomyPart('Image', 'typically FwImage; any widget.'),
    AnatomyPart('Caption', 'wraps independently of the image.'),
    AnatomyPart('Credit', 'photographer/source line.'),
    AnatomyPart('Action', 'e.g. view-fullscreen button, logical end.'),
  ],
  properties: FwFigure(
    image: FwImage(
      provider: MemoryImage(_png),
      aspectRatio: 16 / 9,
      semanticLabel: 'Demo photo (1×1 transparent)',
    ),
    caption: 'A single pixel, enlarged for your viewing pleasure.',
    credit: 'Photo: Demo Suite',
  ),
  layoutSpecs: const [
    LayoutSpec('Gap', 'FwSpace token between image and caption.'),
    LayoutSpec('Caption', 'caption text role; wraps to image width.'),
    LayoutSpec('Action', 'sits at the logical end of the caption row.'),
  ],
  dos: const [
    'Caption every figure that carries meaning.',
    'Credit the source when one exists.',
  ],
  donts: const [
    "Don't repeat the caption verbatim as the image label — the figure "
        'announces once.',
  ],
  a11y: const [
    'Figure label defaults to the caption; explicit semanticLabel wins.',
    'Inner image is excluded from semantics when the figure is labeled.',
    'A caption identical to the label is not announced twice.',
  ],
);

/// M04 avatar group doc board.
Widget avatarGroupDoc() => ComponentDoc(
  id: 'M04',
  name: 'Avatar group',
  tier: 'Molecules',
  summary:
      'Overlapping avatar stack with a capped visible count. Later avatars '
      'tuck behind earlier ones; overflow collapses into a +N chip that can '
      'be a button. Every avatar keeps its own semantics.',
  notFor: 'single identity (use FwAvatar)',
  anatomy: const [
    AnatomyPart('Stack', 'first avatar paints on top.'),
    AnatomyPart('Overlap', 'logical-inline offset; RTL-aware.'),
    AnatomyPart('Overflow', '+N chip; button when onOverflowTap is set.'),
  ],
  properties: _matrix(const [
    FwAvatarGroup(
      children: [
        FwAvatar(name: 'Ada Lovelace', semanticLabel: 'Ada Lovelace'),
        FwAvatar(name: 'Grace Hopper', semanticLabel: 'Grace Hopper'),
        FwAvatar(name: 'Katherine Johnson', semanticLabel: 'Katherine Johnson'),
        FwAvatar(name: 'Radia Perlman', semanticLabel: 'Radia Perlman'),
        FwAvatar(name: 'Margaret Hamilton', semanticLabel: 'Margaret Hamilton'),
      ],
    ),
    FwAvatarGroup(
      maxVisible: 2,
      children: [
        FwAvatar(name: 'Ada Lovelace', semanticLabel: 'Ada Lovelace'),
        FwAvatar(name: 'Grace Hopper', semanticLabel: 'Grace Hopper'),
        FwAvatar(name: 'Katherine Johnson', semanticLabel: 'Katherine Johnson'),
      ],
    ),
  ]),
  layoutSpecs: const [
    LayoutSpec('Overlap', 'fraction of the avatar diameter.'),
    LayoutSpec('Cap', 'maxVisible; overflow chip shows +N.'),
  ],
  dos: const [
    'Cap the visible count; never clip the overflow silently.',
    'Make the overflow chip a button when tapping shows the full list.',
  ],
  donts: const ["Don't hide interactive avatars behind overlap."],
  a11y: const [
    'Each avatar keeps its own semantic label.',
    'Overflow chip announces "+N more" via its label.',
  ],
);

/// M09 carousel doc board.
Widget carouselDoc() => ComponentDoc(
  id: 'M09',
  name: 'Carousel',
  tier: 'Molecules',
  summary:
      'Swipeable pages with dot indicators. Tapping a dot jumps to that '
      'page; pages announce "Page X of N". For onboarding flows with '
      'skip/next actions use FwOnboardingFlow.',
  notFor: 'onboarding flows (use FwOnboardingFlow)',
  anatomy: const [
    AnatomyPart('Viewport', 'PageView; aspect ratio configurable.'),
    AnatomyPart('Indicators', 'dots; active dot widens. Tappable.'),
  ],
  properties: FwCarousel(
    itemCount: 3,
    aspectRatio: 16 / 9,
    itemBuilder: (context, i) => Container(
      alignment: Alignment.center,
      color: [
        const Color(0xFFE3F2FD),
        const Color(0xFFF3E5F5),
        const Color(0xFFE8F5E9),
      ][i],
      child: FwText('Slide ${i + 1}', role: FwTextRole.h4),
    ),
  ),
  layoutSpecs: const [
    LayoutSpec('Aspect', '16/9 default; configurable.'),
    LayoutSpec('Indicators', 'centered below; s2 gap.'),
  ],
  dos: const [
    'Label pages for screen readers via the built-in announcements.',
    'Keep page count small (under ~7).',
  ],
  donts: const ["Don't auto-advance without a pause control."],
  a11y: const [
    'Pages announce "Page X of N"; current page is a live region.',
    'Indicator dots are buttons ("Go to page X").',
  ],
);

/// M07+ photo viewer doc board.
Widget photoViewerDoc() => ComponentDoc(
  id: 'M07+',
  name: 'Photo viewer',
  tier: 'Molecules',
  summary:
      'Pinch-zoom and double-tap-to-zoom image viewer on InteractiveViewer. '
      'Pure Flutter gestures — zero platform risk.',
  notFor: 'thumbnails (use FwImage)',
  anatomy: const [
    AnatomyPart('Viewer', 'InteractiveViewer with min/max scale.'),
    AnatomyPart('Gestures', 'pinch; double-tap toggles zoom.'),
  ],
  properties: SizedBox(
    height: 200,
    child: FwPhotoViewer(
      child: FwImage(
        provider: MemoryImage(_png),
        semanticLabel: 'Demo photo (1×1 transparent)',
      ),
    ),
  ),
  layoutSpecs: const [LayoutSpec('Scale', '1.0–4.0; double-tap toggles 2.0.')],
  dos: const ['Use for fullscreen image inspection.'],
  donts: const ["Don't nest inside another gesture-driven scroller."],
  a11y: const [
    'Viewer announces the zoom hint.',
    'The image keeps its own accessible label.',
  ],
);

/// D06 stat doc board.
Widget statDoc() => const ComponentDoc(
  id: 'D06',
  name: 'Stat',
  tier: 'Molecules',
  summary:
      'Metric with value, label, trend, and comparison period. Formats '
      'are caller-supplied; the trend icon/color follows the good/bad '
      'policy (revenue up is good, churn up is bad).',
  notFor: 'charts (compose separately)',
  anatomy: [
    AnatomyPart('Value', 'app-formatted; h4.'),
    AnatomyPart('Label', 'caption; muted.'),
    AnatomyPart('Trend', 'icon + delta + comparison period.'),
  ],
  properties: const Wrap(
    spacing: 24,
    runSpacing: 16,
    children: [
      FwStat(
        value: '\$12.4k',
        label: 'Revenue',
        trend: FwTrendDirection.up,
        trendLabel: '+12%',
        trendGoodness: FwTrendGoodness.goodUp,
        comparisonLabel: 'vs last month',
      ),
      FwStat(
        value: '3.1%',
        label: 'Churn',
        trend: FwTrendDirection.up,
        trendLabel: '+0.4%',
        trendGoodness: FwTrendGoodness.goodDown,
        comparisonLabel: 'vs last month',
      ),
      FwStat(value: '1,248', label: 'Active users', isLoading: true),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Value', 'h4 role; caller formats.'),
    LayoutSpec('Trend', '16px icon; policy-driven color.'),
  ],
  dos: const [
    'Format numbers/dates in the app, localized.',
    'Set trendGoodness so color matches meaning.',
  ],
  donts: const ["Don't invent the comparison period — pass it."],
  a11y: const [
    'One node announces "value, label, trend".',
    'Loading announces "Loading label".',
  ],
);

/// B10 refreshable list doc board.
Widget refreshableDoc() => const ComponentDoc(
  id: 'B10',
  name: 'Refreshable list',
  tier: 'Molecules',
  summary:
      'Pull-to-refresh plus infinite scroll. The app owns paging: '
      'onLoadMore fires near the end; hasMore/isLoadingMore guard '
      'duplicates and show the appended indicator.',
  notFor: 'non-list content (wrap separately)',
  anatomy: const [
    AnatomyPart('Refresh', 'RefreshIndicator; onRefresh future.'),
    AnatomyPart('List', 'ListView.builder; app itemBuilder.'),
    AnatomyPart('More', 'end indicator while isLoadingMore.'),
  ],
  properties: const _RefreshableDemo(),
  layoutSpecs: const [
    LayoutSpec('Trigger', '200px from the end fires onLoadMore.'),
  ],
  dos: const [
    'Set isLoadingMore synchronously in onLoadMore.',
    'Keep hasMore accurate to avoid dead-end spinners.',
  ],
  donts: const ["Don't fire onLoadMore without the isLoadingMore guard."],
  a11y: const [
    'Loading-more indicator is announced.',
    'Refresh uses the platform indicator semantics.',
  ],
);

/// Interactive refreshable demo for the doc board.
class _RefreshableDemo extends StatefulWidget {
  const _RefreshableDemo();

  @override
  State<_RefreshableDemo> createState() => _RefreshableDemoState();
}

class _RefreshableDemoState extends State<_RefreshableDemo> {
  final List<int> _items = List.generate(20, (i) => i);
  bool _loadingMore = false;
  bool _hasMore = true;

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(List.generate(20, (i) => i));
      _hasMore = true;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      final next = _items.length;
      _items.addAll(List.generate(10, (i) => next + i));
      _loadingMore = false;
      _hasMore = _items.length < 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: FwRefreshableList(
        onRefresh: _refresh,
        onLoadMore: _loadMore,
        hasMore: _hasMore,
        isLoadingMore: _loadingMore,
        itemCount: _items.length,
        itemBuilder: (context, i) => ListTile(title: Text('Item ${_items[i]}')),
      ),
    );
  }
}

/// D10 swipeable doc board.
Widget swipeableDoc() => const ComponentDoc(
  id: 'D10',
  name: 'Swipeable',
  tier: 'Organisms',
  summary:
      'Swipe-to-reveal list actions. Drag toward the logical start for '
      'trailing actions, toward the end for leading actions. Actions are '
      'real buttons while revealed and offstage while hidden.',
  notFor: 'full-swipe dismiss (use Dismissible)',
  anatomy: const [
    AnatomyPart('Child', 'the row content; translates on drag.'),
    AnatomyPart('Panes', 'action buttons behind; snap open/closed.'),
  ],
  properties: const _SwipeableDemo(),
  layoutSpecs: const [
    LayoutSpec('Actions', '72px each; threshold 40% or fling.'),
  ],
  dos: const [
    'Keep actions to 1–3 per side.',
    'Also expose critical actions without the gesture.',
  ],
  donts: const ["Don't hide the only path to a destructive action."],
  a11y: const [
    'Revealed actions are buttons; hidden actions are offstage.',
    'No switch-access open affordance yet — provide alternatives.',
  ],
);

/// Interactive swipeable demo for the doc board.
class _SwipeableDemo extends StatefulWidget {
  const _SwipeableDemo();

  @override
  State<_SwipeableDemo> createState() => _SwipeableDemoState();
}

class _SwipeableDemoState extends State<_SwipeableDemo> {
  final List<String> _items = ['Alpha', 'Beta', 'Gamma'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in _items)
          FwSwipeable(
            key: ValueKey(item),
            trailingActions: [
              FwSwipeAction(
                label: 'Delete',
                icon: Icons.delete,
                intent: FwIntent.danger,
                onTap: () => setState(() => _items.remove(item)),
              ),
            ],
            leadingActions: [
              FwSwipeAction(
                label: 'Archive',
                icon: Icons.archive,
                intent: FwIntent.info,
                onTap: () {},
              ),
            ],
            child: ListTile(title: Text(item)),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Organisms.
// ---------------------------------------------------------------------------

/// F01 field shell doc board.
Widget fieldDoc() => const ComponentDoc(
  id: 'F01',
  name: 'Field shell',
  tier: 'Molecules',
  summary:
      'The shared wrapper for every form input: persistent visible label, '
      'required hint, description, helper/error line, and prefix/suffix '
      'slots. The shell owns the label (it never floats away); decoration '
      'stays with the editor. Errors combine text and an icon, never a red '
      'border alone.',
  notFor: 'standalone labels (use FwText), inputs without a label',
  anatomy: const [
    AnatomyPart('Label', 'label role, always visible; required marker.'),
    AnatomyPart('Editor', 'the value editor; reads FwFieldScope.'),
    AnatomyPart('Adornments', 'prefix/suffix slots flanking the editor.'),
    AnatomyPart('Message', 'description, or error with icon (live region).'),
    AnatomyPart('State', 'FwFieldState: external error wins over local.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwField(
        label: 'Email',
        required: true,
        description: 'We never share your email.',
        child: TextField(decoration: InputDecoration(hintText: 'you@x.com')),
      ),
      SizedBox(height: 12),
      FwField(
        label: 'Email',
        errorText: 'Enter a valid email address.',
        child: TextField(decoration: InputDecoration(hintText: 'you@x.com')),
      ),
      SizedBox(height: 12),
      FwField(
        label: 'Amount',
        prefix: Icon(Icons.attach_money, size: 18),
        suffix: Text('USD'),
        enabled: false,
        child: TextField(decoration: InputDecoration(hintText: '0.00')),
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Label gap', 's1 between label and editor.'),
    LayoutSpec('Message gap', 's1 between editor and message line.'),
    LayoutSpec('Adornment gap', 's2 between adornments and editor.'),
    LayoutSpec('Error', 'icon + text; live region for announcements.'),
  ],
  dos: const [
    'Wrap every input in FwField — labels are never optional.',
    'Withhold errors until touched/dirty or submit (see FwFieldState.showError).',
  ],
  donts: const [
    "Don't signal errors with color alone; keep the icon and text.",
    "Don't flash validation errors on first paint.",
  ],
  a11y: const [
    'The field container carries the label in semantics.',
    'Error appearance is announced via a live region.',
    'Label, message, and marker scale with text; layout never clips.',
  ],
);

/// F02 text input doc board.
Widget textFieldDoc() => ComponentDoc(
  id: 'F02',
  name: 'Text input',
  tier: 'Molecules',
  summary:
      'Single-line text entry with the F01 shell built in: filled or outline '
      'treatment, keyboard types, autofill hints, formatters, prefix/suffix '
      'slots, and an optional clear action. Integrates with Flutter Form '
      '(validate/save/reset); external errors win over validator output.',
  notFor: 'multi-line content (use FwTextArea), search (use FwSearchField)',
  anatomy: const [
    AnatomyPart('Shell', 'FwField label, message, adornments.'),
    AnatomyPart('Box', 'filled or outline decoration from tokens.'),
    AnatomyPart('Clear', 'optional clear action when text is present.'),
    AnatomyPart('State', 'validator vs external error precedence.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwTextField(
        label: 'Email',
        hintText: 'you@x.com',
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        showClear: true,
      ),
      const SizedBox(height: 12),
      FwTextField(
        label: 'Username',
        variant: FwTextFieldVariant.outline,
        description: 'Shown on your public profile.',
      ),
      const SizedBox(height: 12),
      FwTextField(
        label: 'Promo code',
        externalError: 'This code expired yesterday.',
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Padding', 'controlInline/controlBlock aliases.'),
    LayoutSpec('Radius', 'md from radii tokens.'),
    LayoutSpec('Focus', '2px focusRing border; error keeps its own.'),
  ],
  dos: const [
    'Set keyboardType and autofillHints for the data asked.',
    'Own the controller when you need the text; otherwise let the field.',
  ],
  donts: const [
    "Don't dispose a caller-owned controller inside the field.",
    "Don't hide the label inside the box as a placeholder.",
  ],
  a11y: const [
    'Label announced via the field container; errors via live region.',
    'Clear action has a tooltip and keyboard focus.',
  ],
);

/// F03 textarea doc board.
Widget textAreaDoc() => ComponentDoc(
  id: 'F03',
  name: 'Textarea',
  tier: 'Molecules',
  summary:
      'Multi-line entry: grows to maxLines then scrolls internally, never '
      'unbounded. Optional grapheme-aware maxLength with a used/max counter '
      'that counts what the user perceives (emoji count as one).',
  notFor: 'single-line values (use FwTextField), rich text editing',
  anatomy: const [
    AnatomyPart('Shell', 'FwField label and message.'),
    AnatomyPart('Area', 'minLines tall, grows to maxLines.'),
    AnatomyPart('Counter', 'grapheme used/max; turns error-red when over.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwTextArea(
        label: 'Bio',
        hintText: 'Tell us about yourself',
        minLines: 2,
        maxLines: 4,
        maxLength: 140,
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Height', 'minLines..maxLines, then internal scroll.'),
    LayoutSpec('Counter', 'caption role, suffix slot of the shell.'),
  ],
  dos: const [
    'Cap maxLines so the area never pushes the form off screen.',
    'Use maxLength for grapheme budgets, not UTF-16 units.',
  ],
  donts: const ["Don't expand unbounded inside a scrollable form."],
  a11y: const [
    'Counter is decorative-adjacent; the limit is in the field semantics.',
    'Multiline announced as a multi-line text field.',
  ],
);

/// F12 search field doc board.
Widget searchFieldDoc() => const ComponentDoc(
  id: 'F12',
  name: 'Search field',
  tier: 'Molecules',
  summary:
      'FwTextField specialization for search: search icon, clear action, '
      'loading affordance, and a submit callback. Debounce stays a caller '
      'service — the field never hides network behavior.',
  notFor: 'filter-as-you-type without a submit affordance',
  anatomy: const [
    AnatomyPart('Icon', 'search prefix icon.'),
    AnatomyPart('Clear', 'clears the query.'),
    AnatomyPart('Loading', 'spinner suffix while results load.'),
  ],
  properties: const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [FwSearchField(label: 'Search products')],
  ),
  layoutSpecs: const [
    LayoutSpec('Action', 'search keyboard action by default.'),
  ],
  dos: const [
    'Drive loading from your real query state.',
    'Debounce in a service, not in the widget.',
  ],
  donts: const ["Don't fire network calls from onChanged directly."],
  a11y: ['Announced as a search field; loading state is exposed.'],
);

/// F04 password field doc board.
Widget passwordDoc() => ComponentDoc(
  id: 'F04',
  name: 'Password field',
  tier: 'Molecules',
  summary:
      'Text input with password defaults: obscured text, password autofill, '
      'and a reveal toggle that preserves focus and selection. Optional '
      'strength presentation is a UX hint, never a security guarantee.',
  notFor: 'usernames, one-time codes (use FwOtpInput)',
  anatomy: const [
    AnatomyPart('Shell', 'FwField label and message.'),
    AnatomyPart('Reveal', 'toggle with tooltip; keeps focus.'),
    AnatomyPart('Strength', 'optional bar composed below the field.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwPasswordField(
        label: 'Password',
        controller: TextEditingController(text: 's3cret'),
      ),
      const SizedBox(height: 12),
      const FwPasswordField(
        label: 'Current password',
        autofillHints: [AutofillHints.password],
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Reveal', 'icon button inside the box, 20px icon.'),
    LayoutSpec('Strength', '4px bar, intent-colored, decorative.'),
  ],
  dos: const [
    'Keep password autofill hints so managers can fill.',
    'Return focus to the field after toggling reveal.',
  ],
  donts: const [
    "Don't claim strength meters as security guarantees.",
    "Don't move focus away on reveal toggle.",
  ],
  a11y: const [
    'Reveal toggle has a tooltip and keyboard focus.',
    'Strength bar is excluded from semantics; label it when shown.',
  ],
);

/// F05 checkbox doc board with the state matrix.
Widget checkboxDoc() => ComponentDoc(
  id: 'F05',
  name: 'Checkbox',
  tier: 'Molecules',
  summary:
      'Tri-state selection: checked, unchecked, and indeterminate. The whole '
      'row (box + label) is one semantic node carrying the checked state. '
      'FwCheckboxGroup composes typed options with Form validation.',
  notFor: 'single on/off settings (use FwSwitch), exclusive choice (radio)',
  anatomy: const [
    AnatomyPart('Box', 'native checkbox; null = indeterminate dash.'),
    AnatomyPart('Label', 'merged into the row semantics.'),
    AnatomyPart('Message', 'description or error under the label.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _matrix(const [
        FwCheckbox(label: 'Unchecked', value: false),
        FwCheckbox(label: 'Checked', value: true),
        FwCheckbox(label: 'Mixed', value: null, tristate: true),
        FwCheckbox(label: 'Disabled', value: false, enabled: false),
      ]),
      const SizedBox(height: 12),
      FwCheckboxGroup<String>(
        label: 'Toppings',
        options: const [
          FwOption(value: 'cheese', label: 'Cheese'),
          FwOption(
            value: 'pepperoni',
            label: 'Pepperoni',
            description: 'Spicy salami',
          ),
          FwOption(value: 'anchovy', label: 'Anchovy', enabled: false),
        ],
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Row', 's1 vertical padding; label wraps.'),
    LayoutSpec('States', 'unchecked/checked/indeterminate x enabled/disabled.'),
  ],
  dos: const [
    'Use indeterminate only for "some children selected".',
    'Type group values; never hard-code stringly state in the app.',
  ],
  donts: const ["Don't use a checkbox for an immediately-applied setting."],
  a11y: const [
    'Row announces label + checked state as one node.',
    'Keyboard: Tab to the row, Space toggles.',
  ],
);

/// F06 radio group doc board.
Widget radioDoc() => ComponentDoc(
  id: 'F06',
  name: 'Radio group',
  tier: 'Molecules',
  summary:
      'Exclusive choice over typed IDs. Arrow keys move between enabled '
      'options and select as they go; each option carries '
      'mutually-exclusive checked semantics.',
  notFor: 'multiple choice (use checkboxes), binary on/off (use switch)',
  anatomy: const [
    AnatomyPart('Options', 'radio + label rows; disabled options skip.'),
    AnatomyPart('Group', 'one value; Form validation supported.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwRadioGroup<String>(
        label: 'Shipping',
        initialValue: 'standard',
        options: const [
          FwOption(
            value: 'standard',
            label: 'Standard',
            description: '5–7 business days',
          ),
          FwOption(
            value: 'express',
            label: 'Express',
            description: '2 business days',
          ),
          FwOption(value: 'drone', label: 'Drone', enabled: false),
        ],
      ),
    ],
  ),
  layoutSpecs: const [LayoutSpec('Row', 's1 vertical padding; label wraps.')],
  dos: const [
    'Keep option lists short; long lists want a select.',
    'Preselect a sensible default for required groups.',
  ],
  donts: const ["Don't leave a required group with no selection and no error."],
  a11y: const [
    'Arrow keys traverse and select; Tab enters/leaves the group.',
    'Screen readers hear position via the exclusive group.',
  ],
);

/// F07 switch doc board.
Widget switchDoc() => ComponentDoc(
  id: 'F07',
  name: 'Switch',
  tier: 'Molecules',
  summary:
      'Immediate on/off setting with a merged label node. Busy replaces the '
      'switch with a spinner and blocks input — the caller owns async '
      'state. For choices submitted with a form, prefer a checkbox.',
  notFor: 'form-submitted choices, tri-state',
  anatomy: const [
    AnatomyPart('Label', 'setting name + optional description.'),
    AnatomyPart('Control', 'switch, or spinner when busy (see tests).'),
  ],
  properties: _matrix(const [
    FwSwitch(label: 'Wi-Fi', value: true),
    FwSwitch(label: 'Bluetooth', value: false),
    FwSwitch(label: 'Airplane', value: false, enabled: false),
  ]),
  layoutSpecs: const [LayoutSpec('Row', 'label expands; control trailing.')],
  dos: const [
    'Apply the change immediately on toggle.',
    'Show busy while the setting commits remotely.',
  ],
  donts: const ["Don't use a switch for 'agree to terms' style confirmations."],
  a11y: const [
    'Row announces label + on/off as one node; Space toggles.',
    'Busy announces a loading state, not a stuck switch.',
  ],
);

/// F08 select doc board.
Widget selectDoc() => ComponentDoc(
  id: 'F08',
  name: 'Select',
  tier: 'Molecules',
  summary:
      'Dropdown for small typed option sets: placeholder, per-option '
      'disabled items, and error state with message. Values compare with '
      '== — type your option IDs.',
  notFor: 'large or remote option sets (use combobox in Phase 4)',
  anatomy: const [
    AnatomyPart('Shell', 'FwField label and error message.'),
    AnatomyPart('Box', 'filled treatment matching text inputs.'),
    AnatomyPart('Menu', 'native dropdown; disabled items skip.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwSelect<String>(
        label: 'Size',
        placeholder: 'Pick a size',
        options: const [
          FwOption(value: 's', label: 'Small'),
          FwOption(value: 'm', label: 'Medium'),
          FwOption(value: 'l', label: 'Large', enabled: false),
        ],
      ),
      const SizedBox(height: 12),
      FwSelect<String>(
        label: 'Country',
        externalError: 'Select your country.',
        options: const [
          FwOption(value: 'au', label: 'Australia'),
          FwOption(value: 'nz', label: 'New Zealand'),
        ],
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Box', 'filled, md radius, error border on invalid.'),
    LayoutSpec('Menu', 'native overlay; width matches the box.'),
  ],
  dos: const [
    'Keep sets small and local; document the limit.',
    'Give options stable typed IDs.',
  ],
  donts: const ["Don't embed remote fetching inside the select."],
  a11y: const [
    'Collapsed state announces label + current value.',
    'Error message appears with the icon, like text inputs.',
  ],
);

/// F09 slider doc board.
Widget sliderDoc() => ComponentDoc(
  id: 'F09',
  name: 'Slider',
  tier: 'Molecules',
  summary:
      'Value selection across a numeric domain: continuous or discrete, '
      'with separated drag (onChanged) and commit (onChangeEnd) events. '
      'Leading/trailing icon slots flank the track (they flip in RTL); an '
      'optional glyph paints inside the thumb. The circular form offers '
      'the same contract for compact spaces.',
  notFor: 'exact numeric entry (use a number field), ranges (Phase 4)',
  anatomy: const [
    AnatomyPart('Label', 'merged into the slider semantics.'),
    AnatomyPart('Readout', 'formatted value; visual only.'),
    AnatomyPart(
      'Track',
      'token colors; tick marks when discrete; labeled marks optional.',
    ),
    AnatomyPart(
      'Icon slots',
      'leading/trailing at the logical ends; thumbIcon glyph optional.',
    ),
    AnatomyPart('Ring', 'circular form: drag around the ring.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwSlider(
        label: 'Volume',
        value: 0.6,
        unit: '%',
        showValueBubble: true,
        leading: const Icon(Icons.volume_down),
        trailing: const Icon(Icons.volume_up),
        thumbIcon: Icons.volume_up,
        onChanged: (_) {},
      ),
      const SizedBox(height: 12),
      FwSlider(
        label: 'Steps',
        value: 3,
        min: 0,
        max: 10,
        divisions: 10,
        showTicks: true,
        marks: const [
          FwSliderMark(0, label: 'Min'),
          FwSliderMark(5, label: 'Mid'),
          FwSliderMark(10, label: 'Max'),
        ],
        onChanged: (_) {},
      ),
      const SizedBox(height: 12),
      FwSlider(
        label: 'Brightness',
        value: 0.9,
        showFill: false,
        onChanged: (_) {},
      ),
      const SizedBox(height: 12),
      FwSlider(
        label: 'Volume limit',
        value: 0.95,
        unit: '%',
        errorText: 'Above the quiet-hours limit',
        onChanged: (_) {},
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FwSlider(
            label: 'Level',
            value: 0.5,
            axis: Axis.vertical,
            leading: const Icon(Icons.arrow_upward),
            trailing: const Icon(Icons.arrow_downward),
            onChanged: (_) {},
          ),
          FwCircularSlider(
            label: 'Temperature',
            value: 72,
            min: 50,
            max: 90,
            unit: '°',
            size: 140,
            onChanged: (_) {},
          ),
        ],
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Domain', 'min < max asserted; divisions > 0.'),
    LayoutSpec('Events', 'onChanged during drag; onChangeEnd on release.'),
    LayoutSpec('Vertical', '160px tall box; drag works rotated.'),
  ],
  dos: const [
    'Persist or fetch on commit, not on every drag frame.',
    'Format values with units for humans and screen readers.',
  ],
  donts: const ["Don't use a slider when the exact number matters."],
  a11y: const [
    'Slider node announces label + formatted value; arrows adjust.',
    'Ring exposes increase/decrease actions; direct drag needs no motion.',
  ],
);

/// F22 one-time-code input doc board.
Widget otpDoc() => ComponentDoc(
  id: 'F22',
  name: 'One-time-code input',
  tier: 'Molecules',
  summary:
      'PIN/OTP entry: one logical text field with segmented visuals. Paste, '
      'password managers, and SMS autofill work because the editor is a '
      'normal TextField; the boxes are decorative.',
  notFor: 'passwords (use FwPasswordField), arbitrary codes',
  anatomy: const [
    AnatomyPart('Boxes', 'segmented visuals; decorative.'),
    AnatomyPart('Editor', 'transparent TextField; owns semantics.'),
    AnatomyPart('Shell', 'FwField label and error.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwOtpInput(label: 'Verification code', length: 6),
      const SizedBox(height: 12),
      FwOtpInput(
        label: 'PIN',
        length: 4,
        obscureText: true,
        externalError: 'Wrong code, try again',
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Box', 'square, md radius, 2px focus ring.'),
    LayoutSpec('Gap', 's2 between boxes.'),
  ],
  dos: const [
    'Fire onCompleted for verification; validate length on submit.',
    'Keep oneTimeCode autofill hints so SMS codes fill in.',
  ],
  donts: const [
    "Don't build per-box fields; paste and autofill break.",
    "Don't announce each box separately to screen readers.",
  ],
  a11y: const [
    'Announced as one text field; boxes excluded from semantics.',
    'Digits-only keyboard; length limit enforced.',
  ],
);

/// F21+ rating doc board.
Widget ratingDoc() => ComponentDoc(
  id: 'F21',
  name: 'Rating',
  tier: 'Molecules',
  summary:
      'Star rating: read-only display with fractional fill, and an '
      'interactive input (tap, drag, arrow keys). Stars are decorative; one '
      'semantic node carries the value.',
  notFor: 'precise numeric input (use a slider), like buttons',
  anatomy: const [
    AnatomyPart('Stars', 'decorative; clipped for fractions.'),
    AnatomyPart('Input', 'slider semantics with step.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const FwRatingDisplay(value: 3.5, max: 5),
      const SizedBox(height: 12),
      FwRatingInput(label: 'Rate your experience', value: 4, onChanged: (_) {}),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Star', '24px display, 32px input; no gaps.'),
    LayoutSpec('Step', '1.0 or 0.5; snapped and clamped.'),
  ],
  dos: const ['Label the input; announce "x out of 5".'],
  donts: const ["Don't make each star a separate button."],
  a11y: const [
    'One slider node: value, increase/decrease actions.',
    'Arrow keys adjust by step; stars excluded from semantics.',
  ],
);

/// F23 phone field doc board.
Widget phoneDoc() => const ComponentDoc(
  id: 'F23',
  name: 'Phone field',
  tier: 'Molecules',
  summary:
      'Phone number entry: searchable country picker with dial code plus a '
      'digits-only national input. Parsing is dependency-free; the value is '
      'country + digits with an e164 getter.',
  notFor: 'formatted display (format in your app), validation by region',
  anatomy: const [
    AnatomyPart('Picker', 'flag + dial code; opens search dialog.'),
    AnatomyPart('Input', 'phone keyboard, digits only.'),
    AnatomyPart('Value', 'FwPhoneNumber: country + nationalNumber.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const FwPhoneField(label: 'Phone number', hintText: '412 345 678'),
      const SizedBox(height: 12),
      const FwPhoneField(
        label: 'Work phone',
        initialCountryCode: 'US',
        description: 'We only call about your booking.',
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Picker', 'min 48px tap target.'),
    LayoutSpec('Dialog', 'search + list; 320px wide.'),
  ],
  dos: const [
    'Store e164; format national numbers for display yourself.',
    'Validate length per country in your app logic.',
  ],
  donts: const ["Don't embed a libphonenumber; keep it dependency-free."],
  a11y: const [
    'Picker is a button with the dial code; dialog is modal.',
    'telephoneNumber autofill hint on the input.',
  ],
);

/// F15 inline calendar doc board.
Widget calendarDoc() => const ComponentDoc(
  id: 'F15',
  name: 'Calendar',
  tier: 'Organisms',
  summary:
      'Inline month grid for picking a single date or a range. Controlled: '
      'the caller owns the selection. This is the inline companion to '
      'dialog date pickers (Phase 4) — same contract, no overlay.',
  notFor: 'dialog/modal picking (Phase 4), time selection',
  anatomy: const [
    AnatomyPart('Header', 'prev/next month chevrons around the month title.'),
    AnatomyPart('Weekdays', 'narrow names rotated to firstDayOfWeek.'),
    AnatomyPart('Day', 'circle highlight when selected; ring for today.'),
    AnatomyPart('Range', 'start/end circles with a band between.'),
  ],
  properties: const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_CalendarDemo(), SizedBox(height: 24), _RangeDemo()],
  ),
  layoutSpecs: const [
    LayoutSpec('Day cell', '44px tall; 36px highlight circle.'),
    LayoutSpec('Grid', '7 columns; rows fit the month.'),
  ],
  dos: const [
    'Clamp with minDate/maxDate for booking windows.',
    'Set firstDayOfWeek from the locale.',
  ],
  donts: const ['Don\'t use for time; pair with a time field.'],
  a11y: const [
    'Each day is a button labelled with the full date.',
    'Selected days announce selected; disabled days are dimmed.',
  ],
);

class _CalendarDemo extends StatefulWidget {
  const _CalendarDemo();

  @override
  State<_CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<_CalendarDemo> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return FwCalendar(
      selectedDate: _selected,
      onDateSelected: (d) => setState(() => _selected = d),
    );
  }
}

class _RangeDemo extends StatefulWidget {
  const _RangeDemo();

  @override
  State<_RangeDemo> createState() => _RangeDemoState();
}

class _RangeDemoState extends State<_RangeDemo> {
  DateTime? _start;
  DateTime? _end;

  @override
  Widget build(BuildContext context) {
    return FwDateRangePicker(
      start: _start,
      end: _end,
      onRangeSelected: (s, e) => setState(() {
        _start = s;
        _end = e;
      }),
    );
  }
}

/// M12 gauge doc board.
Widget gaugeDoc() => const ComponentDoc(
  id: 'M12',
  name: 'Gauge',
  tier: 'Molecules',
  summary:
      'Radial arc meter for a value in a domain. Display-only: no gestures. '
      'Color comes from the intent token; ticks mark the divisions; the '
      'center shows the formatted value.',
  notFor: 'interactive input (use FwSlider), exact numeric entry',
  anatomy: const [
    AnatomyPart('Track', 'surfaceContainerHighest arc.'),
    AnatomyPart('Fill', 'intent-colored arc over the value fraction.'),
    AnatomyPart('Ticks', 'tickCount divisions around the sweep.'),
    AnatomyPart('Readout', 'formatted value + caption, centered.'),
  ],
  properties: const Wrap(
    spacing: 24,
    runSpacing: 16,
    alignment: WrapAlignment.center,
    children: [
      FwGauge(value: 72, unit: '%', label: 'Battery'),
      FwGauge(
        value: 0.85,
        min: 0,
        max: 1,
        label: 'Tank',
        intent: FwIntent.info,
        valueFormatter: _tankFormat,
      ),
      FwGauge(
        value: 96,
        label: 'CPU',
        intent: FwIntent.danger,
        unit: '%',
        tickCount: 10,
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Arc', '240° sweep with a gap at the bottom by default.'),
    LayoutSpec('Size', 'square; default 160px.'),
  ],
  dos: const ['Clamp the value; out-of-domain values render at the edge.'],
  donts: const ['Don\'t animate the value yourself; rebuild on change.'],
  a11y: const [
    'Semantics expose the label and formatted value as a meter.',
    'The readout text is visual-only; the node announces it.',
  ],
);

String _tankFormat(double v) => '${(v * 100).round()}% full';

/// M13 QR display doc board.
Widget qrDoc() => const ComponentDoc(
  id: 'M13',
  name: 'QR code',
  tier: 'Molecules',
  summary:
      'Display-only QR code for a payload (URL, text, vCard). No scanning '
      'or camera — pair with a platform scanner plugin for capture flows. '
      'Modules use theme roles, never raw colors.',
  notFor: 'scanning codes, barcodes (1D)',
  anatomy: const [
    AnatomyPart('Modules', 'theme text role on the surface role.'),
    AnatomyPart('Quiet zone', '16px padding; scanners need the margin.'),
    AnatomyPart('Frame', 'sm radius + border, like a card.'),
  ],
  properties: const Wrap(
    spacing: 24,
    runSpacing: 16,
    alignment: WrapAlignment.center,
    children: [
      FwQrDisplay(data: 'https://example.com', semanticLabel: 'Example link'),
      FwQrDisplay(data: 'WIFI:T:WPA;S:CafeNet;P:espresso;;', size: 120),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Size', 'square; default 160px incl. padding.'),
    LayoutSpec('Quiet zone', 'keep the 16px padding.'),
  ],
  dos: const [
    'Label the code for screen readers (semanticLabel).',
    'Test-scan printed sizes before shipping.',
  ],
  donts: const ['Don\'t place on a busy background; keep contrast.'],
  a11y: const [
    'Exposed as an image with the label; modules are hidden.',
    'Always provide the payload as text nearby when it matters.',
  ],
);

/// A-tier reorderable list doc board.
Widget reorderDoc() => ComponentDoc(
  id: 'A02',
  name: 'Reorderable list',
  tier: 'Molecules',
  summary:
      'Drag-to-reorder list with token-styled handles and haptic feedback. '
      'Items are keyed by value; the caller owns the order.',
  notFor: 'sorting by column (use FwDataTable), swipe actions',
  anatomy: const [
    AnatomyPart('Tile', 'caller-built content.'),
    AnatomyPart('Handle', 'drag_handle icon; the drag affordance.'),
    AnatomyPart('Proxy', 'lifted tile with a shadow while dragging.'),
  ],
  properties: _ReorderDemo(),
  layoutSpecs: const [LayoutSpec('Handle', '48px touch target.')],
  dos: const ['Keep tile heights stable while dragging.'],
  donts: const ['Don\'t reorder on tap; handles start the drag.'],
  a11y: const [
    'Each handle is a button labelled "Reorder <item>".',
    'Provide arrow-key reordering as an alternative where it matters.',
  ],
);

class _ReorderDemo extends StatefulWidget {
  @override
  State<_ReorderDemo> createState() => _ReorderDemoState();
}

class _ReorderDemoState extends State<_ReorderDemo> {
  var _items = const ['Inbox', 'Today', 'Upcoming', 'Someday'];

  @override
  Widget build(BuildContext context) {
    return FwReorderableList<String>(
      items: _items,
      itemBuilder: (context, item) => ListTile(title: Text(item)),
      handleSemanticLabel: (item) => 'Reorder $item',
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _items.removeAt(oldIndex);
          _items = [..._items]..insert(newIndex, item);
        });
      },
    );
  }
}

/// A-tier sticky headers doc board.
Widget stickyDoc() => const ComponentDoc(
  id: 'A03',
  name: 'Sticky headers',
  tier: 'Organisms',
  summary:
      'Section list whose headers pin to the top while their section scrolls '
      'underneath. Built on slivers; headers get an opaque backdrop.',
  notFor: 'tab bars, collapsing app bars',
  anatomy: const [
    AnatomyPart('Header', 'pinned; opaque surface backdrop.'),
    AnatomyPart('Section', 'sliver list under its header.'),
  ],
  properties: SizedBox(
    height: 280,
    child: FwStickyList(
      sections: [
        FwStickySection(
          header: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Favorites'),
          ),
          children: const [
            ListTile(title: Text('Espresso')),
            ListTile(title: Text('Pour over')),
          ],
        ),
        FwStickySection(
          header: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('All drinks'),
          ),
          children: const [
            ListTile(title: Text('Latte')),
            ListTile(title: Text('Cappuccino')),
            ListTile(title: Text('Mocha')),
          ],
        ),
      ],
    ),
  ),
  layoutSpecs: const [
    LayoutSpec('Header extent', 'fixed 48px; headers must fit.'),
  ],
  dos: const ['Keep headers short; they occlude content.'],
  donts: const ['Don\'t nest scrollables inside sections.'],
  a11y: const ['Headers are plain text; sections read in order.'],
);

/// A-tier resizable panels doc board.
Widget panelsDoc() => ComponentDoc(
  id: 'A04',
  name: 'Resizable panels',
  tier: 'Organisms',
  summary:
      'Split panes with a draggable divider. The divider is a slider for '
      'assistive tech; the ratio clamps to the configured bounds.',
  notFor: 'drawer layouts, full app scaffolding',
  anatomy: const [
    AnatomyPart('Panes', 'flex-weighted by the ratio.'),
    AnatomyPart('Divider', '48px hit area; 4px visual grip.'),
  ],
  properties: SizedBox(
    height: 160,
    child: Builder(
      builder: (context) => FwResizablePanels(
        first: Container(
          color: context.fwTheme.colors.of(FwColorRole.primaryContainer),
          alignment: Alignment.center,
          child: const Text('First'),
        ),
        second: Container(
          color: context.fwTheme.colors.of(FwColorRole.surfaceContainerHighest),
          alignment: Alignment.center,
          child: const Text('Second'),
        ),
      ),
    ),
  ),
  layoutSpecs: const [LayoutSpec('Ratio', '0.2–0.8 clamp by default.')],
  dos: const ['Persist the ratio for app layouts.'],
  donts: const ['Don\'t use below ~320px wide.'],
  a11y: const [
    'Divider is a slider: arrows move it 10%.',
    'Announces the percentage.',
  ],
);

/// A-tier chat bubbles doc board.
Widget chatDoc() => const ComponentDoc(
  id: 'A05',
  name: 'Chat bubbles',
  tier: 'Molecules',
  summary:
      'Message bubbles: sent end-aligns with the primary tint, received '
      'start-aligns on the surface tint. Ticks show delivery for sent '
      'messages.',
  notFor: 'comment threads, email',
  anatomy: const [
    AnatomyPart('Bubble', 'asymmetric radius; the tail side is tighter.'),
    AnatomyPart('Meta', 'timestamp + delivery ticks, dimmed.'),
    AnatomyPart('Name', 'sender name on received messages.'),
  ],
  properties: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FwChatBubble(
        message: 'The mockups are ready 🎉',
        side: FwChatSide.sent,
        timestamp: '10:24',
        status: FwChatStatus.read,
      ),
      SizedBox(height: 8),
      FwChatBubble(
        message: 'On it — reviewing now.',
        side: FwChatSide.received,
        senderName: 'Amara',
        timestamp: '10:26',
      ),
    ],
  ),
  layoutSpecs: const [LayoutSpec('Width', 'caps at 320px.')],
  dos: const ['Group consecutive messages from one sender.'],
  donts: const ['Don\'t use ticks on received messages.'],
  a11y: const [
    'Each bubble is one node: "You: …, 10:24".',
    'Ticks are decorative; status is in the label.',
  ],
);

/// F24 signature pad doc board.
Widget signatureDoc() => const ComponentDoc(
  id: 'F24',
  name: 'Signature pad',
  tier: 'Molecules',
  summary:
      'Freehand capture area for signatures. Reports ink presence; clear '
      'wipes the pad. Export via a RepaintBoundary key if you need an image.',
  notFor: 'drawing apps, handwriting recognition',
  anatomy: const [
    AnatomyPart('Pad', '160px capture area with hint text.'),
    AnatomyPart('Ink', 'text-role strokes, round caps.'),
    AnatomyPart('Clear', 'ghost button; disabled when empty.'),
  ],
  properties: const FwSignaturePad(),
  layoutSpecs: const [LayoutSpec('Pad', '160px tall; full width.')],
  dos: const ['Confirm intent with a checkbox alongside.'],
  donts: const ['Don\'t require pixel-perfect signatures.'],
  a11y: const ['Labelled "Signature pad" with the hint as its hint.'],
);

/// F20 color picker doc board.
Widget colorPickerDoc() => const ComponentDoc(
  id: 'F20',
  name: 'Color picker',
  tier: 'Organisms',
  summary:
      'Hue slider + saturation/value pad + preset swatches. A value '
      'boundary: it trades in raw Color data like a text field trades in '
      'strings.',
  notFor: 'brand theming (use FwTheme), contrast checking',
  anatomy: const [
    AnatomyPart('Pad', '16:9 saturation/value area for the hue.'),
    AnatomyPart('Hue', 'spectrum slider with thumb.'),
    AnatomyPart('Presets', 'quick-pick swatches that wrap.'),
  ],
  properties: const SizedBox(
    width: 320,
    child: FwColorPicker(
      onColorSelected: _noopColor,
      initialColor: Color(0xFF1B6DE0),
      presets: [
        Color(0xFF1B6DE0),
        Color(0xFF0E9F6E),
        Color(0xFFE3A008),
        Color(0xFFC81E1E),
        Color(0xFF7C3AED),
      ],
    ),
  ),
  layoutSpecs: const [LayoutSpec('Pad', '16:9 aspect.')],
  dos: const ['Announce the hex value for confirmation.'],
  donts: const ['Don\'t use for picking theme colors at runtime.'],
  a11y: const [
    'Exposed as a labelled control with the hex as its value.',
    'Presets are buttons.',
  ],
);

void _noopColor(Color _) {}

/// A-tier guided tour doc board.
Widget tourDoc() => const ComponentDoc(
  id: 'A06',
  name: 'Guided tour',
  tier: 'Organisms',
  summary:
      'Walkthrough overlay: a spotlight cutout around each step\'s target '
      'with an anchored card (title, description, dots, Back/Next/Skip). '
      'Tapping the scrim ends the tour.',
  notFor: 'single tooltips (use FwTooltip), onboarding forms',
  anatomy: const [
    AnatomyPart('Scrim', 'dims the screen; tap to dismiss.'),
    AnatomyPart('Spotlight', 'cutout + ring around the target.'),
    AnatomyPart('Card', 'anchored below/above the target.'),
  ],
  properties: const _TourDemo(),
  layoutSpecs: const [
    LayoutSpec('Card', '300px wide; flips above the target when needed.'),
  ],
  dos: const ['Keep tours to ≤5 steps; each step one idea.'],
  donts: const ['Don\'t auto-start tours; let the user opt in.'],
  a11y: const [
    'The card is a live region announcing step x of n.',
    'Skip is always reachable by keyboard.',
  ],
);

class _TourDemo extends StatefulWidget {
  const _TourDemo();

  @override
  State<_TourDemo> createState() => _TourDemoState();
}

class _TourDemoState extends State<_TourDemo> {
  final _firstKey = GlobalKey();
  final _secondKey = GlobalKey();
  late final FwTourController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FwTourController(
      steps: [
        FwTourStep(
          targetKey: _firstKey,
          title: 'Search',
          description: 'Find anything in your workspace here.',
        ),
        FwTourStep(
          targetKey: _secondKey,
          title: 'Create',
          description: 'Start a new project from this button.',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FwTour(
      controller: _controller,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              FwButton(
                key: _firstKey,
                label: 'Search',
                variant: FwButtonVariant.outline,
                onPressed: () {},
              ),
              FwButton(key: _secondKey, label: 'Create', onPressed: () {}),
            ],
          ),
          const SizedBox(height: 12),
          FwButton(
            label: 'Start tour',
            variant: FwButtonVariant.ghost,
            onPressed: _controller.start,
          ),
        ],
      ),
    );
  }
}

/// B01 alert doc board.
Widget alertDoc() => ComponentDoc(
  id: 'B01',
  name: 'Alert',
  tier: 'Molecules',
  summary:
      'Status banner: intent-colored edge, icon, title, optional body and '
      'action, optional dismiss. Announcements are opt-in — set announce '
      'when the alert is added dynamically.',
  notFor: 'toasts (Phase 4), inline field errors (use FwField)',
  anatomy: const [
    AnatomyPart('Edge', '4px intent color on the leading side.'),
    AnatomyPart('Icon', 'per intent; decorative beside the title.'),
    AnatomyPart('Dismiss', 'icon button with "Dismiss" tooltip.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwAlert(intent: FwAlertIntent.success, title: 'Saved', onDismiss: () {}),
      const SizedBox(height: 12),
      FwAlert(
        intent: FwAlertIntent.danger,
        title: 'Upload failed',
        body: 'The file exceeds the 10 MB limit.',
        action: const TextButton(onPressed: null, child: Text('Details')),
        onDismiss: () {},
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Padding', 's3 all around; s2 icon gap.'),
    LayoutSpec('Action', 'below the body, left-aligned.'),
  ],
  dos: const [
    'Announce only dynamically-added alerts (announce: true).',
    'Give the dismiss button its tooltip; it is the accessible name.',
  ],
  donts: const ["Don't announce on every rebuild."],
  a11y: const ['Opt-in live region; icon is decorative next to the title.'],
);

/// B03/B04/B05 progress doc board.
Widget progressDoc() => const ComponentDoc(
  id: 'B03',
  name: 'Progress',
  tier: 'Molecules',
  summary:
      'Determinate or indeterminate progress: linear bar with an outside '
      'percentage label, circular ring, and a busy indicator that degrades '
      'to static text under reduced motion. One progress model throughout.',
  notFor: 'skeleton loading (use FwSkeleton), button spinners alone',
  anatomy: const [
    AnatomyPart('Track', 'token colors; thickness configurable.'),
    AnatomyPart('Label', 'percentage outside the bar; visual only.'),
    AnatomyPart('Busy', 'spinner + label; static icon when reduced motion.'),
  ],
  properties: const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwLinearProgress(value: 0.42),
      SizedBox(height: 12),
      // Indeterminate forms animate; shown in widget tests, not static docs.
      FwLinearProgress(value: 0.85, intent: FwAlertIntent.success),
      SizedBox(height: 12),
      Row(
        children: [
          FwCircularProgress(value: 0.75),
          SizedBox(width: 16),
          FwCircularProgress(value: 0.3),
        ],
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Bar', '4px default thickness; rounded ends.'),
    LayoutSpec('Ring', '36px default; stroke 4px.'),
  ],
  dos: const [
    'Label determinate progress with a real value for screen readers.',
    'Use FwBusyIndicator (not a bare spinner) for block loading.',
  ],
  donts: const [
    "Don't put a second progress announcement inside a button.",
    "Don't animate when the user asked for reduced motion.",
  ],
  a11y: const [
    'Bar/ring nodes carry the percentage value.',
    'Busy indicator is a live region with static text fallback.',
  ],
);

/// B06 skeleton doc board.
Widget skeletonDoc() => const ComponentDoc(
  id: 'B06',
  name: 'Skeleton',
  tier: 'Molecules',
  summary:
      'Loading placeholders with reserved geometry: text lines, avatar, '
      'and blocks. Decorative (excluded from semantics) and static by '
      'default — shimmer is opt-in and disabled under reduced motion.',
  notFor: 'progress with a known percentage, empty states',
  anatomy: const [
    AnatomyPart('Block', 'rounded rect; token surface color.'),
    AnatomyPart('Avatar', 'circular 40px placeholder.'),
    AnatomyPart('Shimmer', 'opt-in gradient sweep; never the default.'),
  ],
  properties: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          FwSkeleton.avatar(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FwSkeleton(width: 120),
                SizedBox(height: 8),
                FwSkeleton(width: 200),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      FwSkeleton(height: 80),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Line', '16px tall; 4px radius.'),
    LayoutSpec('Gap', '8px between lines; 12px after avatar.'),
  ],
  dos: const [
    'Reserve the geometry the real content will take.',
    'Keep shimmer opt-in; respect reduced motion.',
  ],
  donts: const [
    "Don't expose placeholders to screen readers.",
    "Don't shimmer by default.",
  ],
  a11y: const [
    'Excluded from semantics; pair with a busy indicator for status.',
  ],
);

/// B07 state panel doc board.
Widget statePanelDoc() => ComponentDoc(
  id: 'B07',
  name: 'State panel',
  tier: 'Molecules',
  summary:
      'Empty, error, and offline states: icon or illustration slot, heading, '
      'description, and actions. The app supplies retry callbacks and the '
      'offline condition — the panel never guesses connectivity.',
  notFor: 'inline validation errors, toasts',
  anatomy: const [
    AnatomyPart('Visual', '48px icon or illustration slot.'),
    AnatomyPart('Copy', 'heading + muted description, centered.'),
    AnatomyPart('Actions', 'wrapped row; retry is app-supplied.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const FwStatePanel.empty(
        heading: 'No results',
        description: 'Try a different search.',
      ),
      const SizedBox(height: 12),
      FwStatePanel.error(
        heading: 'Something went wrong',
        description: 'We could not load your data.',
        onRetry: () {},
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Padding', 's6 all around; centered column.'),
    LayoutSpec('Actions', 'wrap-centered below the copy.'),
  ],
  dos: const [
    'Pass a real onRetry; make offline a first-class app state.',
    'Use the illustration slot when the illustration system lands.',
  ],
  donts: const ["Don't infer offline from one failed request."],
  a11y: const ['Heading is text; actions are real buttons.'],
);

/// B09 status dot doc board.
Widget statusDotDoc() => const ComponentDoc(
  id: 'B09',
  name: 'Status dot',
  tier: 'Molecules',
  summary:
      'Dot-plus-text status/legend indicator. The caller supplies the '
      'localized label — the widget never invents status text and never '
      'polls. Dot color follows the intent roles shared with badges.',
  notFor: 'badge counts (use FwBadge), progress (use FwLinearProgress)',
  anatomy: const [
    AnatomyPart('Dot', 'intent color fill; decorative.'),
    AnatomyPart('Label', 'caller-supplied localized text.'),
  ],
  properties: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FwStatusDot(label: 'Online', intent: FwIntent.success),
      SizedBox(height: 8),
      FwStatusDot(label: 'Away', intent: FwIntent.warning),
      SizedBox(height: 8),
      FwStatusDot(label: 'Do not disturb', intent: FwIntent.danger),
      SizedBox(height: 8),
      FwStatusDot(label: 'Offline', intent: FwIntent.neutral),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Dot', 's2 token diameter by default.'),
    LayoutSpec('Gap', 's2 token between dot and text.'),
  ],
  dos: const [
    'Supply localized status text from the app.',
    'Pair color with text — never color alone.',
  ],
  donts: const [
    "Don't poll or infer status inside the widget.",
    "Don't use for counts — that's a badge.",
  ],
  a11y: const [
    'One semantic node announces the label; the dot is decorative.',
    'semanticLabel overrides the announced text when needed.',
  ],
);

/// D03 accordion doc board.
Widget accordionDoc() => const ComponentDoc(
  id: 'D03',
  name: 'Accordion',
  tier: 'Organisms',
  summary:
      'Expandable panels with controlled open IDs. Single-open by default; '
      'allowMultiple keeps panels open together. Headers are keyboard '
      'buttons with expanded semantics; closed bodies leave the semantics '
      'tree and cannot take focus.',
  notFor: 'long scrolling content (use a list), dialogs',
  anatomy: const [
    AnatomyPart('Header', 'button row; content plus rotating glyph.'),
    AnatomyPart('Body', 'collapsible; retained or disposed.'),
    AnatomyPart('Dividers', 'hairlines between panels.'),
  ],
  properties: const _AccordionDemo(),
  layoutSpecs: const [
    LayoutSpec('Header', 's4 horizontal, s3 vertical padding.'),
    LayoutSpec('Body', 's4 padding; animates on the motion token.'),
    LayoutSpec('Policy', 'single-open default; allowMultiple opt-in.'),
  ],
  dos: const [
    'Own the open IDs in app state; the widget reports the next set.',
    'Keep headers short — bodies carry the detail.',
  ],
  donts: const [
    "Don't nest accordions more than one level deep.",
    "Don't put essential actions only inside closed panels.",
  ],
  a11y: const [
    'Headers expose button + expanded semantics; Enter/Space toggle.',
    'Closed bodies are hidden from semantics and focus.',
    'Focus inside a closing panel moves to its header.',
  ],
);

/// Interactive accordion demo for the doc board.
class _AccordionDemo extends StatefulWidget {
  const _AccordionDemo();

  @override
  State<_AccordionDemo> createState() => _AccordionDemoState();
}

class _AccordionDemoState extends State<_AccordionDemo> {
  Set<String> _open = const {'shipping'};

  @override
  Widget build(BuildContext context) {
    return FwAccordion(
      openIds: _open,
      onOpenChanged: (ids) => setState(() => _open = ids),
      items: const [
        FwAccordionItem(
          id: 'shipping',
          header: FwText('Shipping options', role: FwTextRole.body),
          body: FwText(
            'Standard (5–7 days), express (2 days), or overnight.',
            role: FwTextRole.bodySm,
          ),
        ),
        FwAccordionItem(
          id: 'returns',
          header: FwText('Returns', role: FwTextRole.body),
          body: FwText(
            '30-day returns; refunds to the original payment method.',
            role: FwTextRole.bodySm,
          ),
        ),
        FwAccordionItem(
          id: 'warranty',
          header: FwText('Warranty', role: FwTextRole.body),
          body: FwText(
            'Two-year limited warranty included.',
            role: FwTextRole.bodySm,
          ),
          enabled: false,
        ),
      ],
    );
  }
}

/// Demo row for the data table doc board.
class _DemoUser {
  const _DemoUser(this.id, this.name, this.role, this.status);
  final String id;
  final String name;
  final String role;
  final FwIntent status;
}

/// D04/D05 data table doc board.
Widget tableDoc() => const ComponentDoc(
  id: 'D04',
  name: 'Data table',
  tier: 'Organisms',
  summary:
      'Schema-driven table for bounded data sets: sortable headers, '
      'selection, row actions, client-side filtering, built-in pagination, '
      'and empty/loading/error states. Sorting and selection are app-owned '
      '— the table reports taps and announces state. Filtering and paging '
      'can be table-owned (filter/filterTest, pageSize) or app-owned for '
      'server-driven data. Below the compact breakpoint rows become cards '
      'via the app-supplied builder.',
  notFor: 'huge virtualized data (use slivers), complex cell editors',
  anatomy: const [
    AnatomyPart('Schema', 'FwDataColumn: id, label, cell, sortable.'),
    AnatomyPart('Header', 'sort buttons announce direction.'),
    AnatomyPart('Rows', 'checkbox selection; trailing actions.'),
    AnatomyPart('Filter', 'filter + filterTest narrow rows client-side.'),
    AnatomyPart('Pages', 'pageSize enables the range label + prev/next.'),
    AnatomyPart('States', 'loading / error+retry / empty.'),
    AnatomyPart('Compact', 'card builder under the breakpoint.'),
  ],
  properties: const _TableDemo(),
  layoutSpecs: const [
    LayoutSpec('Columns', 'fixed width or flex; numeric right-aligns.'),
    LayoutSpec('Overflow', 'horizontal scroll when wider than viewport.'),
    LayoutSpec('Compact', '600px default breakpoint; cards via builder.'),
    LayoutSpec('Limits', 'bounded sets (~500 rows); simple cells.'),
  ],
  dos: const [
    'Own sorting in the app; the table reports taps.',
    'Use filter/filterTest + pageSize for client-side data sets.',
    'Page/filter server-side by passing the sliced rows instead.',
    'Represent essential columns in the compact card builder.',
  ],
  donts: const [
    "Don't drop essential columns on phones — restyle, don't remove.",
    "Don't put nested tables or editors in cells.",
  ],
  a11y: const [
    'Sort headers announce "sorted ascending/descending".',
    'Selection uses native checkboxes; select-all is tri-state.',
    'Loading/error/empty states are announced.',
  ],
);

/// Interactive data table demo for the doc board.
class _TableDemo extends StatefulWidget {
  const _TableDemo();

  @override
  State<_TableDemo> createState() => _TableDemoState();
}

class _TableDemoState extends State<_TableDemo> {
  String? _sortId = 'name';
  bool _ascending = true;
  Set<String> _selected = const {};

  static const _all = [
    _DemoUser('u1', 'Ada Lovelace', 'Engineer', FwIntent.success),
    _DemoUser('u2', 'Grace Hopper', 'Admiral', FwIntent.info),
    _DemoUser('u3', 'Katherine Johnson', 'Mathematician', FwIntent.warning),
  ];

  List<_DemoUser> get _rows {
    final rows = List<_DemoUser>.of(_all);
    if (_sortId == 'name') {
      rows.sort(
        (a, b) =>
            _ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return FwDataTable<_DemoUser>(
      columns: [
        FwDataColumn<_DemoUser>(
          id: 'name',
          label: 'Name',
          sortable: true,
          cell: (u) => Text(u.name),
        ),
        FwDataColumn<_DemoUser>(
          id: 'role',
          label: 'Role',
          cell: (u) => Text(u.role),
        ),
        FwDataColumn<_DemoUser>(
          id: 'status',
          label: 'Status',
          cell: (u) => FwStatusDot(label: u.status.name, intent: u.status),
        ),
      ],
      rows: _rows,
      getRowId: (u) => u.id,
      sortColumnId: _sortId,
      sortAscending: _ascending,
      onSort: (id) => setState(() {
        if (_sortId == id) {
          _ascending = !_ascending;
        } else {
          _sortId = id;
          _ascending = true;
        }
      }),
      selectable: true,
      selectedIds: _selected,
      onSelectionChanged: (ids) => setState(() => _selected = ids),
      rowActions: (u) => [
        FwDataRowAction<_DemoUser>(
          id: 'edit',
          label: 'Edit ${u.name}',
          icon: Icons.edit,
          onInvoked: (_) {},
        ),
      ],
      compactBuilder: (context, scope) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(scope.row.name),
              Text(scope.row.role),
              const SizedBox(height: 4),
              FwStatusDot(
                label: scope.row.status.name,
                intent: scope.row.status,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// D07 timeline doc board.
Widget timelineDoc() => const ComponentDoc(
  id: 'D07',
  name: 'Timeline',
  tier: 'Organisms',
  summary:
      'Vertical event list with status dots, app-formatted time labels, '
      'and optional actions. Events read in list order; the connecting '
      'line is decorative. Time formatting and timezones belong to the app.',
  notFor: 'horizontal processes (use FwStepper)',
  anatomy: const [
    AnatomyPart('Dot', 'intent color; statusLabel makes it meaningful.'),
    AnatomyPart('Glyph', 'optional icon inside the dot.'),
    AnatomyPart('Line', 'decorative connector; excluded from semantics.'),
    AnatomyPart('Content', 'time, title, description, action.'),
    AnatomyPart('Dense', 'compact spacing variant.'),
  ],
  properties: FwTimeline(
    dense: true,
    events: [
      FwTimelineEvent(
        title: 'Deployed v2.4',
        time: '10:24',
        description: 'All regions healthy.',
        icon: Icons.check,
        intent: FwIntent.success,
        statusLabel: 'Completed',
      ),
      FwTimelineEvent(
        title: 'Incident #482 opened',
        time: '09:12',
        description: 'Elevated error rate on checkout.',
        icon: Icons.warning,
        intent: FwIntent.warning,
        statusLabel: 'Attention',
      ),
      FwTimelineEvent(
        title: 'Rollback completed',
        time: '08:40',
        icon: Icons.history,
        intent: FwIntent.info,
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Gutter', 's5 token; dot 12px.'),
    LayoutSpec('Spacing', 's5 between events.'),
    LayoutSpec('Direction', 'gutter on the logical start (RTL-aware).'),
  ],
  dos: const [
    'Format times in the app, with the user timezone.',
    'Give dots a statusLabel when the color carries meaning.',
  ],
  donts: const ["Don't use the timeline for branching workflows."],
  a11y: const [
    'Connecting line is excluded from semantics.',
    'Dots announce their statusLabel when provided.',
    'Event order in the tree matches visual order.',
  ],
);

Widget listDoc() => const ComponentDoc(
  id: 'D02',
  name: 'List',
  tier: 'Organisms',
  summary:
      'Scrollable collection of FwListTile rows with token padding. '
      'Compose for settings, inboxes, and menus.',
  notFor: 'grids, very long virtualized collections (use slivers)',
  anatomy: const [
    AnatomyPart('Rows', 'FwListTile children.'),
    AnatomyPart('Padding', 'token padding around rows.'),
    AnatomyPart('Dividers', 'optional row separators.'),
  ],
  properties: SizedBox(
    height: 180,
    child: FwList(
      children: [
        FwListTile(
          title: FwText('Ada Lovelace', role: FwTextRole.body),
          subtitle: FwText('Analytical engines', role: FwTextRole.bodySm),
          trailing: FwIcon(Icons.chevron_right),
        ),
        FwListTile(
          title: FwText('Grace Hopper', role: FwTextRole.body),
          subtitle: FwText('Compilers', role: FwTextRole.bodySm),
          selected: true,
        ),
      ],
    ),
  ),
  layoutSpecs: const [
    LayoutSpec('Padding', 'FwSpace token; s0 available.'),
    LayoutSpec('Scrolling', 'native ScrollView; caller owns controller.'),
  ],
  dos: const [
    'Keep rows homogeneous in height where possible.',
    'Own the scroll controller in the caller.',
  ],
  donts: const ["Don't nest shrink-wrapped lists inside long pages."],
  a11y: const [
    'Rows expose their combined semantics.',
    'Keyboard scrolling follows platform behavior.',
  ],
);

Widget autoGridDoc() => ComponentDoc(
  id: 'L05',
  name: 'Auto-fit grid',
  tier: 'Organisms',
  summary:
      'Responsive grid computing its column count from the available width, '
      'a minimum item width, and the gap. Stable item keys survive resizes.',
  notFor: 'fixed 12-column layouts (use FwRow)',
  anatomy: const [
    AnatomyPart('Items', 'children with stable keys.'),
    AnatomyPart('Measure', 'columns from bounded width and gap.'),
    AnatomyPart('Aspect', 'optional aspect ratio per cell.'),
  ],
  properties: FwAutoGrid(
    minItemWidth: 140,
    gap: FwSpace.s3,
    children: [
      for (var i = 0; i < 6; i++)
        Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFFE7E0CB + i * 0x00040400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FwText('item $i', role: FwTextRole.label),
        ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Columns', 'floor((width + gap) / (minItemWidth + gap)).'),
    LayoutSpec('Gap', 'token; shrinks at very narrow widths.'),
  ],
  dos: const [
    'Key items stably so state survives column-count changes.',
    'Use lazy grids for large collections.',
  ],
  donts: const ["Don't use for full-span editorial layouts."],
  a11y: const [
    'Item order matches focus order.',
    'Resizing never drops focus to a removed item.',
  ],
);

Widget showDoc() => const ComponentDoc(
  id: 'L06',
  name: 'Show / responsive builder',
  tier: 'Organisms',
  summary:
      'Shows or hides children by width range, with an explicit retained '
      'state policy. Hidden children leave focus and semantics correctly.',
  notFor: 'animating visibility (use animated wrappers)',
  anatomy: const [
    AnatomyPart('Range', 'below/above a breakpoint.'),
    AnatomyPart('Policy', 'remove vs retain state, documented cost.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwShow(
        below: FwBreakpoint.md,
        child: FwText('Only on narrow widths', role: FwTextRole.bodySm),
      ),
      FwShow(
        above: FwBreakpoint.md,
        child: FwText('Only on wide widths', role: FwTextRole.bodySm),
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Breakpoints', 'FwBreakpoint values; exact minimums.'),
  ],
  dos: const [
    'State the retention policy where it matters.',
    'Test that hidden controls are not focusable.',
  ],
  donts: const ["Don't hide required actions where users can't find them."],
  a11y: const [
    'Removed children leave the semantics tree.',
    'Retained state has a documented memory cost.',
  ],
);

// ---------------------------------------------------------------------------
// Overlays (Phase 4).
// ---------------------------------------------------------------------------

/// O01 dialog doc board.
Widget dialogDoc() => const ComponentDoc(
  id: 'O01',
  name: 'Dialog',
  tier: 'Molecules',
  summary:
      'Modal dialog with title/content/actions slots. Dismissal always '
      'returns a typed FwOverlayResult naming the reason (action, barrier, '
      'systemBack, swipe, programmatic) — never bare null.',
  notFor: 'modeless flows (use a sheet) or full pages (use navigation).',
  anatomy: const [
    AnatomyPart('Barrier', 'attributable dim layer; tap = barrier reason.'),
    AnatomyPart('Card', 'elevation level 3, lg radius, max width by size.'),
    AnatomyPart('Title', 'h4 role, announced as the dialog heading.'),
    AnatomyPart('Content', 'scrolls internally on short windows.'),
    AnatomyPart('Actions', 'wrapping row; close with FwDialog.close.'),
  ],
  properties: const _DialogDemo(),
  layoutSpecs: const [
    LayoutSpec(
      'Sizes',
      'sm 320 / md 480 / lg 640 max width; full = fullscreen.',
    ),
    LayoutSpec('Card', 'elevation 3 surface, s6 outer padding, s4 action row.'),
    LayoutSpec('Route', 'viewport metrics propagated; local theme supported.'),
  ],
  dos: const [
    'Close actions with FwDialog.close(context, value) for typed results.',
    'Keep dialogs focused: one decision per dialog.',
  ],
  donts: const [
    "Don't read a bare null as cancel — branch on the dismiss reason.",
    "Don't put full pages inside dialogs; navigate instead.",
  ],
  a11y: const [
    'Route is labelled (scopesRoute/namesRoute); title is a heading.',
    'Focus is contained while open; Escape/back dismiss with a reason.',
  ],
);

/// Interactive O01 demo: opens a dialog and reports the typed result.
class _DialogDemo extends StatefulWidget {
  const _DialogDemo();

  @override
  State<_DialogDemo> createState() => _DialogDemoState();
}

class _DialogDemoState extends State<_DialogDemo> {
  String _last = 'No dialog opened yet.';

  Future<void> _open(FwDialogSize size) async {
    final result = await FwDialog.show<String>(
      context: context,
      title: const Text('Archive project?'),
      content: const Text(
        'Archived projects stay visible to admins and can be restored.',
      ),
      size: size,
      actions: [
        FwButton(
          label: 'Cancel',
          variant: FwButtonVariant.ghost,
          onPressed: () => FwDialog.close(context),
        ),
        FwButton(
          label: 'Archive',
          onPressed: () => FwDialog.close(context, 'archived'),
        ),
      ],
    );
    setState(() {
      _last = 'value=${result.value}, reason=${result.reason.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _matrix([
          for (final size in FwDialogSize.values)
            FwButton(
              label: 'Open ${size.name}',
              variant: FwButtonVariant.outline,
              onPressed: () => _open(size),
            ),
        ]),
        const SizedBox(height: 8),
        Text(
          _last,
          style: context.fwTheme.typeScale.resolve(FwTextRole.bodySm, context),
        ),
      ],
    );
  }
}

/// O02 confirmation dialog doc board.
Widget confirmDoc() => const ComponentDoc(
  id: 'O02',
  name: 'Confirmation dialog',
  tier: 'Molecules',
  summary:
      'O01 composition for confirm/cancel decisions. Destructive confirms '
      'get danger intent; while busy, barrier/back/Escape are locked and '
      'the caller must resolve explicitly.',
  anatomy: const [
    AnatomyPart('Title', 'the decision being asked.'),
    AnatomyPart('Message', 'consequences, in plain words.'),
    AnatomyPart('Cancel', 'ghost button; disabled while busy.'),
    AnatomyPart(
      'Confirm',
      'danger intent when destructive; loading while busy.',
    ),
  ],
  properties: const _ConfirmDemo(),
  layoutSpecs: const [
    LayoutSpec('Size', 'sm (320 max) — confirmations stay compact.'),
    LayoutSpec('Focus', 'initial focus on the safe action for destructive.'),
  ],
  dos: const [
    'Perform the operation in the caller after a true result.',
    'Drive busy from your async operation; never leave it locked.',
  ],
  donts: const [
    "Don't allow dismissal while busy — the lock exists for a reason.",
    "Don't confirm destructive actions without naming the consequence.",
  ],
  a11y: const [
    'Busy state announces via the loading button label.',
    'Focus stays inside until the operation resolves.',
  ],
);

/// Interactive O02 demo.
class _ConfirmDemo extends StatefulWidget {
  const _ConfirmDemo();

  @override
  State<_ConfirmDemo> createState() => _ConfirmDemoState();
}

class _ConfirmDemoState extends State<_ConfirmDemo> {
  String _last = 'No confirmation opened yet.';

  Future<void> _open(bool destructive) async {
    final result = await FwConfirmDialog.show(
      context: context,
      title: destructive ? 'Delete workspace?' : 'Publish changes?',
      message: destructive
          ? 'This permanently deletes the workspace and its data.'
          : 'Members will see the new version immediately.',
      destructive: destructive,
      confirmLabel: destructive ? 'Delete' : 'Publish',
    );
    setState(() {
      _last = 'value=${result.value}, reason=${result.reason.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _matrix([
          FwButton(
            label: 'Confirm publish',
            variant: FwButtonVariant.outline,
            onPressed: () => _open(false),
          ),
          FwButton(
            label: 'Confirm delete',
            variant: FwButtonVariant.outline,
            intent: FwIntent.danger,
            onPressed: () => _open(true),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          _last,
          style: context.fwTheme.typeScale.resolve(FwTextRole.bodySm, context),
        ),
      ],
    );
  }
}

/// O03 bottom sheet doc board.
Widget sheetDoc() => const ComponentDoc(
  id: 'O03',
  name: 'Bottom sheet',
  tier: 'Molecules',
  summary:
      'Modal or persistent bottom sheet with drag handle and snap points. '
      'Content lifts above the software keyboard; swipe-down dismisses '
      'with the swipe reason.',
  notFor: 'critical decisions (use a dialog) or long forms (use a page).',
  anatomy: const [
    AnatomyPart('Drag handle', 'labelled for screen readers.'),
    AnatomyPart('Title', 'optional heading.'),
    AnatomyPart('Content', 'snaps between snap points while dragging.'),
    AnatomyPart('Keyboard', 'inset padding lifts content above the keyboard.'),
  ],
  properties: const _SheetDemo(),
  layoutSpecs: const [
    LayoutSpec('Surface', 'elevation 3, lg top radius, safe-area inset.'),
    LayoutSpec('Snaps', 'fractions of visible height, e.g. [0.5, 0.9].'),
  ],
  dos: const [
    'Keep sheet content short; deep flows deserve a page.',
    'Offer snap points when content has a natural half state.',
  ],
  donts: const ["Don't hide the only path forward behind a swipe."],
  a11y: const [
    'Drag handle is labelled; the sheet is a modal route.',
    'Escape/back dismiss like dialogs.',
  ],
);

/// Interactive O03 demo.
class _SheetDemo extends StatefulWidget {
  const _SheetDemo();

  @override
  State<_SheetDemo> createState() => _SheetDemoState();
}

class _SheetDemoState extends State<_SheetDemo> {
  String _last = 'No sheet opened yet.';

  Future<void> _open() async {
    final result = await FwSheet.showModal<String>(
      context: context,
      title: const Text('Share link'),
      snapPoints: const [0.4, 0.85],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Anyone with the link can view this board.'),
          const SizedBox(height: 12),
          FwButton(
            label: 'Copy link',
            onPressed: () => FwDialog.close(context, 'copied'),
          ),
        ],
      ),
    );
    setState(() {
      _last = 'value=${result.value}, reason=${result.reason.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FwButton(
          label: 'Open sheet',
          variant: FwButtonVariant.outline,
          onPressed: _open,
        ),
        const SizedBox(height: 8),
        Text(
          _last,
          style: context.fwTheme.typeScale.resolve(FwTextRole.bodySm, context),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overlays continued (Phase 4, P4.2).
// ---------------------------------------------------------------------------

/// O03 drawer doc board.
Widget drawerDoc() => const ComponentDoc(
  id: 'O03',
  name: 'Drawer',
  tier: 'Molecules',
  summary:
      'Start/end navigation drawer for a Scaffold: header/content/footer '
      'slots over caller-owned items. Native drawer behavior — scrim tap, '
      'back button, edge swipe, focus return — comes from the Scaffold.',
  notFor: 'bottom sheets (O03 sheet) or primary phone navigation.',
  anatomy: const [
    AnatomyPart('Header', 'brand/account slot, s4 padding.'),
    AnatomyPart('Content', 'scrollable nav items, s2 gutters.'),
    AnatomyPart('Footer', 'settings/sign-out slot.'),
  ],
  properties: const _DrawerDemo(),
  layoutSpecs: const [
    LayoutSpec('Width', '320dp default; end radius lg on the opening edge.'),
    LayoutSpec('Surface', 'surfaceContainerLow with safe-area inset.'),
  ],
  dos: const [
    'Put it in Scaffold.drawer (start) or endDrawer (end).',
    'Keep the item list caller-owned with shared destination IDs.',
  ],
  donts: const ["Don't duplicate selection state between drawer and rail."],
  a11y: const [
    'Back button and scrim dismiss; focus returns to the trigger.',
    'Drawer content is a labelled navigation region.',
  ],
);

/// Interactive O03 demo: a self-contained Scaffold with a drawer.
class _DrawerDemo extends StatelessWidget {
  const _DrawerDemo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Scaffold(
        drawer: const FwDrawer(
          header: const Text('Acme Inc'),
          content: const Column(
            children: [
              ListTile(leading: Icon(Icons.home), title: Text('Home')),
              ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
            ],
          ),
          footer: const Text('v1.0'),
        ),
        body: Builder(
          builder: (context) => Center(
            child: FwButton(
              label: 'Open drawer',
              variant: FwButtonVariant.outline,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
    );
  }
}

/// O04 popover doc board.
Widget popoverDoc() => const ComponentDoc(
  id: 'O04',
  name: 'Popover',
  tier: 'Molecules',
  summary:
      'Anchored interactive content (filters, previews) that is not a '
      'dialog: no scrim, no focus trap. Logical start/end placement flips '
      'in RTL; a colliding placement flips once to its opposite.',
  notFor: 'passive hints (use tooltip) or decisions (use dialog).',
  anatomy: const [
    AnatomyPart('Anchor', 'caller-built; owns the toggle gesture.'),
    AnatomyPart('Follower', 'OverlayPortal + transform follower, s2 gap.'),
    AnatomyPart('Card', 'elevation 3, md radius, 320 max width.'),
  ],
  properties: const _PopoverDemo(),
  layoutSpecs: const [
    LayoutSpec('Gap', 's2 token between anchor and card.'),
    LayoutSpec('Placement', 'bottom/top/start/end; flip on collision.'),
  ],
  dos: const [
    'Keep popover content interactive and dismissible.',
    'Toggle from the anchor; also allow tap-outside and Escape.',
  ],
  donts: const ["Don't put required actions only inside a popover."],
  a11y: const [
    'Announced as a plain container, not a route or dialog.',
    'Escape dismisses; focus stays where the user left it.',
  ],
);

/// Interactive O04 demo.
class _PopoverDemo extends StatefulWidget {
  const _PopoverDemo();

  @override
  State<_PopoverDemo> createState() => _PopoverDemoState();
}

class _PopoverDemoState extends State<_PopoverDemo> {
  final _controller = FwPopoverController();
  FwPopoverPlacement _placement = FwPopoverPlacement.bottom;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _matrix([
          for (final placement in FwPopoverPlacement.values)
            FwButton(
              label: placement.name,
              variant: placement == _placement
                  ? FwButtonVariant.solid
                  : FwButtonVariant.outline,
              onPressed: () => setState(() => _placement = placement),
            ),
        ]),
        const SizedBox(height: 12),
        Center(
          child: FwPopover(
            controller: _controller,
            placement: _placement,
            anchor: FwButton(
              label: 'Filter',
              variant: FwButtonVariant.outline,
              leading: const Icon(Icons.filter_list, size: 18),
              onPressed: _controller.toggle,
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Only show:'),
                Text('• In stock'),
                Text('• On sale'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// O06 menu doc board.
Widget menuDoc() => const ComponentDoc(
  id: 'O06',
  name: 'Menu',
  tier: 'Molecules',
  summary:
      'Dropdown menu over a shared typed entry model: actions, separators, '
      'group labels, checked items, submenus. Native MenuAnchor supplies '
      'Arrow/Home/End/Enter/Escape and focus restoration.',
  anatomy: const [
    AnatomyPart('Trigger', 'caller-built; receives the MenuController.'),
    AnatomyPart('Entries', 'typed model; values delivered to onSelected.'),
    AnatomyPart('Checked', 'leading check mark for toggle items.'),
    AnatomyPart('Submenu', 'native hover/keyboard open, Escape steps out.'),
  ],
  properties: const _MenuDemo(),
  layoutSpecs: const [
    LayoutSpec('Panel', 'surfaceContainerHigh, md radius, s2 padding.'),
    LayoutSpec('Items', 'label role text; 20px leading icons.'),
  ],
  dos: const [
    'Model entries with stable typed values, not label strings.',
    'Use labels to group; separators to divide groups.',
  ],
  donts: const ["Don't nest submenus more than one level deep."],
  a11y: const [
    'Full keyboard map from the native anchor.',
    'Focus returns to the trigger when the menu had focus.',
  ],
);

/// Interactive O06 demo.
class _MenuDemo extends StatefulWidget {
  const _MenuDemo();

  @override
  State<_MenuDemo> createState() => _MenuDemoState();
}

class _MenuDemoState extends State<_MenuDemo> {
  String _last = 'No selection yet.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwMenu<String>(
          entries: const [
            FwMenuLabel('Sort by'),
            FwMenuAction(value: 'name', label: 'Name', checked: true),
            FwMenuAction(value: 'date', label: 'Date'),
            FwMenuSeparator(),
            FwMenuSubmenu(
              label: 'More',
              children: [FwMenuAction(value: 'size', label: 'Size')],
            ),
          ],
          onSelected: (v) => setState(() => _last = 'Selected: $v'),
          trigger: (context, controller) => FwButton(
            label: 'Sort',
            variant: FwButtonVariant.outline,
            trailing: const Icon(Icons.arrow_drop_down, size: 18),
            onPressed: controller.open,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _last,
          style: context.fwTheme.typeScale.resolve(FwTextRole.bodySm, context),
        ),
      ],
    );
  }
}

/// O07 context menu doc board.
Widget contextMenuDoc() => const ComponentDoc(
  id: 'O07',
  name: 'Context menu',
  tier: 'Molecules',
  summary:
      'Secondary-click / Menu-key / long-press menu over content. '
      'One level deep (no submenus); always pair with a visible '
      'non-right-click alternative such as an overflow button.',
  anatomy: const [
    AnatomyPart('Region', 'focusable; owns the invocation gestures.'),
    AnatomyPart('Menu', 'popup at the pointer or region center.'),
  ],
  properties: const _ContextMenuDemo(),
  layoutSpecs: const [
    LayoutSpec('Position', 'anchored at the pointer; clamped to the window.'),
  ],
  dos: const [
    'Offer long-press on touch and the Menu key on keyboard.',
    'Mirror the actions in a visible overflow menu.',
  ],
  donts: const ["Don't make right-click the only path to an action."],
  a11y: const [
    'Region is focusable; Menu/Shift+F10 opens the menu.',
    'Every action stays reachable without a pointer.',
  ],
);

/// Interactive O07 demo.
class _ContextMenuDemo extends StatefulWidget {
  const _ContextMenuDemo();

  @override
  State<_ContextMenuDemo> createState() => _ContextMenuDemoState();
}

class _ContextMenuDemoState extends State<_ContextMenuDemo> {
  String _last = 'Right-click, long-press, or focus + Menu key.';

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FwContextMenuRegion<String>(
          entries: const [
            FwMenuAction(value: 'rename', label: 'Rename'),
            FwMenuAction(value: 'duplicate', label: 'Duplicate'),
            FwMenuSeparator(),
            FwMenuAction(value: 'delete', label: 'Delete'),
          ],
          onSelected: (v) => setState(() => _last = 'Selected: $v'),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colors.of(FwColorRole.surfaceContainerLow),
              borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
            ),
            child: const Center(child: Text('Report.pdf')),
          ),
        ),
        const SizedBox(height: 8),
        Text(_last, style: theme.typeScale.resolve(FwTextRole.bodySm, context)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pickers and advanced inputs (Phase 4, P4.3).
// ---------------------------------------------------------------------------

/// F10 range slider doc board.
Widget rangeSliderDoc() => const ComponentDoc(
  id: 'F10',
  name: 'Range slider',
  tier: 'Molecules',
  summary:
      'Two-thumb slider for bounded ranges. Endpoints stay ordered by the '
      'platform; both thumbs get native semantics and the readout mirrors '
      'in RTL.',
  notFor: 'single values (use a slider) or precise entry (use a number field).',
  anatomy: const [
    AnatomyPart('Label', 'persistent, above the track.'),
    AnatomyPart('Readout', 'formatted "start – end" pair.'),
    AnatomyPart('Thumbs', 'two native range thumbs.'),
  ],
  properties: const _RangeSliderDemo(),
  layoutSpecs: const [LayoutSpec('Track', 'native range track, full width.')],
  dos: const [
    'Format the readout for the locale (units, decimals).',
    'Prefer step divisions for discrete ranges.',
  ],
  donts: const ["Don't let thumbs cross: the platform keeps them ordered."],
  a11y: const [
    'Each thumb is individually adjustable by keyboard and screen reader.',
  ],
);

/// Interactive F10 demo.
class _RangeSliderDemo extends StatefulWidget {
  const _RangeSliderDemo();

  @override
  State<_RangeSliderDemo> createState() => _RangeSliderDemoState();
}

class _RangeSliderDemoState extends State<_RangeSliderDemo> {
  RangeValues _values = const RangeValues(20, 80);

  @override
  Widget build(BuildContext context) {
    return FwRangeSlider(
      label: 'Price range',
      values: _values,
      min: 0,
      max: 100,
      divisions: 20,
      unit: '%',
      onChanged: (v) => setState(() => _values = v),
    );
  }
}

/// F11 number field doc board.
Widget numberFieldDoc() => const ComponentDoc(
  id: 'F11',
  name: 'Number field',
  tier: 'Molecules',
  summary:
      'Numeric input with increment/decrement actions. Null means empty, '
      'not invalid: bad intermediate text reverts on commit, and the '
      'stepper clamps to min/max with decimal rounding.',
  anatomy: const [
    AnatomyPart('Input', 'numeric keyboard, char filter.'),
    AnatomyPart('Stepper', '− / + icon actions with tooltips.'),
  ],
  properties: const _NumberFieldDemo(),
  layoutSpecs: const [
    LayoutSpec('Actions', 'compact icon buttons in the suffix slot.'),
  ],
  dos: const [
    'Set min/max/step/decimalPlaces for the domain.',
    'Let null flow through as "no value" for optional fields.',
  ],
  donts: const ["Don't coerce text while the user is still typing."],
  a11y: const [
    'Stepper buttons are labelled Increment/Decrement.',
    'Invalid commits revert; the last valid value is never lost.',
  ],
);

/// Interactive F11 demo.
class _NumberFieldDemo extends StatefulWidget {
  const _NumberFieldDemo();

  @override
  State<_NumberFieldDemo> createState() => _NumberFieldDemoState();
}

class _NumberFieldDemoState extends State<_NumberFieldDemo> {
  double? _value = 4;

  @override
  Widget build(BuildContext context) {
    return FwNumberField(
      label: 'Quantity',
      value: _value,
      min: 0,
      max: 10,
      step: 1,
      onChanged: (v) => setState(() => _value = v),
      description: 'Current: ${_value?.toString() ?? 'empty'}',
    );
  }
}

/// F13 combobox doc board.
Widget comboboxDoc() => const ComponentDoc(
  id: 'F13',
  name: 'Combobox',
  tier: 'Molecules',
  summary:
      'Autocomplete over local or async suggestions. Debounce plus query '
      'sequence IDs mean only the latest fetch can update the listbox — '
      'stale results never corrupt the selection.',
  notFor: 'small fixed sets (use a select) or free text (use a text field).',
  anatomy: const [
    AnatomyPart('Field', 'query input; keeps focus while open.'),
    AnatomyPart('Listbox', 'anchored popover; flips on collision.'),
    AnatomyPart('States', 'loading spinner, error, and empty rows.'),
  ],
  properties: const _ComboboxDemo(),
  layoutSpecs: const [
    LayoutSpec('Listbox', 'max 240 tall, scrolls; 320 max width.'),
  ],
  dos: const [
    'Debounce async sources; guard with sequence IDs.',
    'Announce loading/error/empty states in the listbox.',
  ],
  donts: const ["Don't apply results from a superseded query."],
  a11y: const [
    'Arrow keys move the active option, Enter selects, Escape closes.',
    'Disabled options are skipped by pointer and keyboard alike.',
  ],
);

/// Interactive F13 demo (local filter).
class _ComboboxDemo extends StatefulWidget {
  const _ComboboxDemo();

  @override
  State<_ComboboxDemo> createState() => _ComboboxDemoState();
}

class _ComboboxDemoState extends State<_ComboboxDemo> {
  static const _fruits = [
    FwOption(value: 'apple', label: 'Apple'),
    FwOption(value: 'apricot', label: 'Apricot'),
    FwOption(value: 'banana', label: 'Banana'),
    FwOption(value: 'cherry', label: 'Cherry', enabled: false),
  ];

  FwOption<String>? _selected;

  List<FwOption<String>> _suggest(String query) {
    final q = query.toLowerCase();
    return _fruits.where((o) => o.label.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FwCombobox<String>(
      label: 'Fruit',
      selectedOption: _selected,
      onSelected: (o) => setState(() => _selected = o),
      suggestionsBuilder: _suggest,
      hintText: 'Type to search…',
    );
  }
}

/// F14 multi-select doc board.
Widget multiSelectDoc() => const ComponentDoc(
  id: 'F14',
  name: 'Multi-select',
  tier: 'Molecules',
  summary:
      'Tag-style multi selection over stable typed IDs. Chips remove with '
      'a tap; the searchable dialog caps at maxSelection and disables the '
      'rest.',
  anatomy: const [
    AnatomyPart('Chips', 'wrap; each removes its value.'),
    AnatomyPart('Dialog', 'search field + checkbox list.'),
    AnatomyPart('Footer', 'Clear and Done actions.'),
  ],
  properties: const _MultiSelectDemo(),
  layoutSpecs: const [
    LayoutSpec('Chips', 'wrap with 6px spacing; dense InputChips.'),
  ],
  dos: const [
    'Identify options by stable IDs, not labels.',
    'Show the count when the cap is reached.',
  ],
  donts: const ["Don't silently drop selections at the cap — disable instead."],
  a11y: const [
    'Dialog is keyboard navigable; Escape cancels.',
    'Chip removal is a labelled button per chip.',
  ],
);

/// Interactive F14 demo.
class _MultiSelectDemo extends StatefulWidget {
  const _MultiSelectDemo();

  @override
  State<_MultiSelectDemo> createState() => _MultiSelectDemoState();
}

class _MultiSelectDemoState extends State<_MultiSelectDemo> {
  static const _options = [
    FwOption(value: 'a', label: 'Alpha'),
    FwOption(value: 'b', label: 'Beta'),
    FwOption(value: 'c', label: 'Gamma'),
    FwOption(value: 'd', label: 'Delta'),
  ];

  Set<String> _selected = {'a'};

  @override
  Widget build(BuildContext context) {
    return FwMultiSelect<String>(
      label: 'Letters',
      options: _options,
      selected: _selected,
      maxSelection: 3,
      onChanged: (s) => setState(() => _selected = s),
    );
  }
}

/// F15 date field doc board.
Widget dateFieldDoc() => const ComponentDoc(
  id: 'F15',
  name: 'Date field',
  tier: 'Molecules',
  summary:
      'Civil-date input with a token-adapted calendar picker. Values are '
      'year/month/day only — never UTC timestamps; convert at the boundary.',
  anatomy: const [
    AnatomyPart('Field', 'read-only, locale-formatted.'),
    AnatomyPart('Actions', 'clear + calendar affordances.'),
  ],
  properties: const _DateFieldDemo(),
  layoutSpecs: const [
    LayoutSpec('Picker', 'native dialog, framework color scheme.'),
  ],
  dos: const [
    'Constrain with firstDate/lastDate and selectableDayPredicate.',
    'Store civil dates; convert to instants at the boundary.',
  ],
  donts: const ["Don't treat the value as a UTC timestamp."],
  a11y: const ['Native picker brings its own keyboard/screen-reader support.'],
);

/// Interactive F15 demo.
class _DateFieldDemo extends StatefulWidget {
  const _DateFieldDemo();

  @override
  State<_DateFieldDemo> createState() => _DateFieldDemoState();
}

class _DateFieldDemoState extends State<_DateFieldDemo> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) {
    return FwDateField(
      label: 'Start date',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

/// F16 time field doc board.
Widget timeFieldDoc() => const ComponentDoc(
  id: 'F16',
  name: 'Time field',
  tier: 'Molecules',
  summary:
      'Time input with a token-adapted clock picker. 12/24-hour display '
      'follows the locale unless the app forces 24-hour.',
  anatomy: const [
    AnatomyPart('Field', 'read-only, locale-formatted.'),
    AnatomyPart('Actions', 'clear + clock affordances.'),
  ],
  properties: const _TimeFieldDemo(),
  layoutSpecs: const [
    LayoutSpec('Picker', 'native dialog, framework color scheme.'),
  ],
  dos: const ['Respect the locale 12/24-hour convention.'],
  donts: const ["Don't invent a custom clock face."],
  a11y: const ['Native picker brings its own keyboard/screen-reader support.'],
);

/// Interactive F16 demo.
class _TimeFieldDemo extends StatefulWidget {
  const _TimeFieldDemo();

  @override
  State<_TimeFieldDemo> createState() => _TimeFieldDemoState();
}

class _TimeFieldDemoState extends State<_TimeFieldDemo> {
  TimeOfDay? _value;

  @override
  Widget build(BuildContext context) {
    return FwTimeField(
      label: 'Start time',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback continued (Phase 4, P4.4).
// ---------------------------------------------------------------------------

/// B02 toast doc board.
Widget toastDoc() => const ComponentDoc(
  id: 'B02',
  name: 'Toast',
  tier: 'Molecules',
  summary:
      'Context-free toast service over a host: severity, action, queue, '
      'dedup, timeout or persistent. One toast shows at a time; the rest '
      'queue. Announced via live region, never steals focus.',
  notFor: 'modal decisions (use a dialog) or persistent status (use a banner).',
  anatomy: const [
    AnatomyPart('Host', 'placed once, e.g. in MaterialApp.builder.'),
    AnatomyPart('Card', 'severity icon, message, optional action, close.'),
    AnatomyPart('Service', 'FwToast.show() — no context needed.'),
  ],
  properties: const _ToastDemo(),
  layoutSpecs: const [
    LayoutSpec('Placement', 'top or bottom; 16px margins, safe-area aware.'),
    LayoutSpec('Queue', 'FIFO; dedupKey replaces instead of queueing.'),
  ],
  dos: const [
    'Keep messages short; one action at most.',
    'Use dedupKey for repeating status (e.g. "Saving…").',
    'Prefer persistent only for ongoing work with a manual dismiss.',
  ],
  donts: const ["Don't stack multiple toasts visually — they queue."],
  a11y: const [
    'Live region announces; focus never moves.',
    'Hover pauses the timeout; accessible navigation triples it.',
    'Swipe or close button dismisses.',
  ],
);

/// Interactive B02 demo.
class _ToastDemo extends StatelessWidget {
  const _ToastDemo();

  @override
  Widget build(BuildContext context) {
    return _matrix([
      FwButton(
        label: 'Info toast',
        variant: FwButtonVariant.outline,
        onPressed: () => FwToast.show(
          const FwToast(
            message: 'Changes saved',
            severity: FwToastSeverity.info,
          ),
        ),
      ),
      FwButton(
        label: 'Undo toast',
        variant: FwButtonVariant.outline,
        onPressed: () => FwToast.show(
          FwToast(
            message: 'File deleted',
            severity: FwToastSeverity.error,
            actionLabel: 'Undo',
            onAction: () => FwToast.show(
              const FwToast(
                message: 'Restored',
                severity: FwToastSeverity.success,
              ),
            ),
          ),
        ),
      ),
      FwButton(
        label: 'Dedup demo',
        variant: FwButtonVariant.outline,
        onPressed: () {
          FwToast.show(const FwToast(message: 'Saving…', dedupKey: 'save'));
          Future.delayed(const Duration(seconds: 1), () {
            FwToast.show(
              const FwToast(
                message: 'Saved',
                severity: FwToastSeverity.success,
                dedupKey: 'save',
              ),
            );
          });
        },
      ),
    ]);
  }
}

/// B08 task list doc board.
Widget taskListDoc() => const ComponentDoc(
  id: 'B08',
  name: 'Task list',
  tier: 'Molecules',
  summary:
      'Upload/task progress over typed state: per-item queued, running, '
      'succeeded, failed, or cancelled, with cancel/retry/dismiss actions. '
      'Presentation only — transport lives in the app.',
  anatomy: const [
    AnatomyPart('Row', 'status icon, label, progress, actions.'),
    AnatomyPart('Progress', 'determinate bar or indeterminate spinner.'),
    AnatomyPart('Actions', 'cancel while active; retry/dismiss when done.'),
  ],
  properties: const _TaskListDemo(),
  layoutSpecs: const [
    LayoutSpec('Rows', 'separated list; shrinks to content.'),
  ],
  dos: const [
    'Report progress 0..1 only when totals are known.',
    'Keep task IDs stable across rebuilds.',
  ],
  donts: const ["Don't aggregate progress unless every task reports totals."],
  a11y: const [
    'Status changes announce via the row label.',
    'Actions are labelled with the task name.',
  ],
);

/// Interactive B08 demo.
class _TaskListDemo extends StatefulWidget {
  const _TaskListDemo();

  @override
  State<_TaskListDemo> createState() => _TaskListDemoState();
}

class _TaskListDemoState extends State<_TaskListDemo> {
  var _tasks = const [
    FwTask(
      id: 'a',
      label: 'upload.png',
      status: FwTaskStatus.running,
      progress: 0.6,
      detail: '4.8 MB of 8 MB',
    ),
    FwTask(
      id: 'b',
      label: 'photo.jpg',
      status: FwTaskStatus.failed,
      detail: 'Network error',
    ),
    FwTask(id: 'c', label: 'doc.pdf', status: FwTaskStatus.succeeded),
  ];

  void _update(String id, FwTask Function(FwTask) fn) {
    setState(() {
      _tasks = [
        for (final t in _tasks)
          if (t.id == id) fn(t) else t,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return FwTaskList(
      tasks: _tasks,
      onCancel: (id) =>
          _update(id, (t) => t.copyWith(status: FwTaskStatus.cancelled)),
      onRetry: (id) => _update(
        id,
        (t) => t.copyWith(status: FwTaskStatus.queued, progress: 0),
      ),
      onDismiss: (id) => setState(() {
        _tasks = _tasks.where((t) => t.id != id).toList();
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification center (Phase 4, P4.5).
// ---------------------------------------------------------------------------

/// B11 notification center doc board.
Widget notificationCenterDoc() => const ComponentDoc(
  id: 'B11',
  name: 'Notification center',
  tier: 'Organisms',
  summary:
      'In-app notification list: unread badges, grouping, mark-read and '
      'clear-all, empty state with an illustration slot. Taps report the '
      'notification; the app owns deep-link navigation. Push delivery stays '
      'platform work.',
  notFor: 'transient confirmations (use a toast) or system push UI.',
  anatomy: const [
    AnatomyPart('Header', 'unread count + mark-all-read / clear-all.'),
    AnatomyPart('Groups', 'section headers by group key.'),
    AnatomyPart('Row', 'severity icon, title/body/time, unread dot.'),
    AnatomyPart('Badge', 'FwUnreadBadge for nav icons; hides at zero.'),
  ],
  properties: const _NotificationCenterDemo(),
  layoutSpecs: const [
    LayoutSpec('List', 'grouped, scrollable; swipe-to-dismiss rows.'),
    LayoutSpec('Empty', 'centered illustration + title + body.'),
  ],
  dos: const [
    'Keep notification IDs stable for mark-read/dismiss.',
    'Let the app own deep links — the center never navigates.',
    'Group by a meaningful key, not by recency alone.',
  ],
  donts: const ["Don't badge the app icon from here — that's platform work."],
  a11y: const [
    'Unread count announced; rows are tappable list items.',
    'Relative times ("5m ago") have absolute-time tooltips.',
  ],
);

/// Interactive B11 demo.
class _NotificationCenterDemo extends StatefulWidget {
  const _NotificationCenterDemo();

  @override
  State<_NotificationCenterDemo> createState() =>
      _NotificationCenterDemoState();
}

class _NotificationCenterDemoState extends State<_NotificationCenterDemo> {
  var _items = [
    FwNotification(
      id: '1',
      title: 'Ada mentioned you',
      body: '"Can you review the tokens PR?" — #general',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      group: 'Mentions',
      deepLink: '/chat/general',
    ),
    FwNotification(
      id: '2',
      title: 'Build passed',
      body: 'main · 3m 12s',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      severity: FwNotificationSeverity.success,
      group: 'CI',
    ),
    FwNotification(
      id: '3',
      title: 'Storage almost full',
      body: '92% of 10 GB used',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      severity: FwNotificationSeverity.warning,
      read: true,
      group: 'System',
    ),
  ];

  String _lastTap = 'Tap a notification to see its deep link.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 420,
          child: FwNotificationCenter(
            notifications: _items,
            onNotificationTap: (n) => setState(() {
              _lastTap = 'Deep link: ${n.deepLink ?? '(none)'}';
            }),
            onMarkRead: (id) => setState(() {
              _items = [
                for (final n in _items)
                  if (n.id == id) n.copyWith(read: true) else n,
              ];
            }),
            onMarkAllRead: () => setState(() {
              _items = [for (final n in _items) n.copyWith(read: true)];
            }),
            onClearAll: () => setState(() => _items = []),
            onDismiss: (id) => setState(() {
              _items = _items.where((n) => n.id != id).toList();
            }),
            emptyIllustration: Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: context.fwTheme.colors.of(FwColorRole.textMuted),
            ),
            emptyTitle: 'All caught up',
            emptyBody: 'New mentions, builds, and alerts land here.',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _lastTap,
          style: context.fwTheme.typeScale.resolve(FwTextRole.bodySm, context),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 5 — action groups and gesture confirmations.
// ---------------------------------------------------------------------------

/// A04 button group doc board.
Widget buttonGroupDoc() => ComponentDoc(
  id: 'A04',
  name: 'Button group',
  tier: 'Molecules',
  summary:
      'Related actions with shared shape and border rules. Attached groups '
      'draw one outer border with 1px dividers (no doubled seams); spaced '
      'groups use a token gap. Horizontal groups stack vertically below '
      '480 logical px so labels never overflow.',
  notFor: 'exclusive choice (use FwSegmentedGroup), menus (use FwSplitButton)',
  anatomy: const [
    AnatomyPart('Items', 'FwButtonGroupItem: label, icon, action, intent.'),
    AnatomyPart('Outer border', 'one shared border in attached mode.'),
    AnatomyPart('Dividers', '1px separators, never doubled borders.'),
    AnatomyPart('Stack rule', 'horizontal wraps to vertical when narrow.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwButtonGroup(
        attached: true,
        items: [
          FwButtonGroupItem(label: 'Left', onPressed: () {}),
          FwButtonGroupItem(label: 'Center', onPressed: () {}),
          FwButtonGroupItem(label: 'Right', onPressed: () {}),
        ],
      ),
      const SizedBox(height: 12),
      FwButtonGroup(
        items: [
          FwButtonGroupItem(
            label: 'Save',
            icon: const Icon(Icons.save_outlined, size: 18),
            onPressed: () {},
          ),
          FwButtonGroupItem(
            label: 'Delete',
            intent: FwIntent.danger,
            onPressed: () {},
          ),
        ],
      ),
      const SizedBox(height: 12),
      FwButtonGroup(
        axis: Axis.vertical,
        attached: true,
        items: [
          FwButtonGroupItem(label: 'Top', onPressed: () {}),
          FwButtonGroupItem(label: 'Bottom', onPressed: () {}),
        ],
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Gap', 's2 between spaced buttons.'),
    LayoutSpec('Touch target', '48dp minimum per item, all sizes.'),
    LayoutSpec('Radius', 'md token; outer corners only when attached.'),
  ],
  dos: const [
    'Use attached groups for tightly related choices (alignment, view modes).',
    'Keep 2–4 items; more belongs in a menu.',
  ],
  donts: const [
    "Don't mix intents casually — one danger item per group at most.",
    "Don't use attached groups for unrelated primary actions.",
  ],
  a11y: const [
    'Source order matches visual order in both axes.',
    'Each item is an independent button with its own label.',
  ],
);

/// A05 segmented group doc board.
Widget segmentedDoc() => ComponentDoc(
  id: 'A05',
  name: 'Segmented group',
  tier: 'Molecules',
  summary:
      'Single- or multiple-choice control with typed values and controlled '
      'selection. Arrow keys move focus and selection (automatic '
      'activation); disabled items are skipped. Roving tabindex: one tab '
      'stop for the whole group.',
  notFor: 'long option lists (use select/radio group), actions (use buttons)',
  anatomy: const [
    AnatomyPart('Items', 'typed values with label, icon, enabled flag.'),
    AnatomyPart('Selection', 'controlled Set<T>; single or multi.'),
    AnatomyPart('Roving focus', 'one tab stop; arrows move within.'),
  ],
  properties: Builder(
    builder: (context) {
      return _SegmentedDemo();
    },
  ),
  layoutSpecs: const [
    LayoutSpec('Dividers', '1px outline dividers between segments.'),
    LayoutSpec('Selected fill', 'solid intent fill via layer-3 tokens.'),
    LayoutSpec('Touch target', '48dp minimum per segment.'),
  ],
  dos: const [
    'Use for 2–5 mutually exclusive view options.',
    'Pair icons with labels for clarity.',
  ],
  donts: const [
    "Don't use segmented groups for primary form submission.",
    "Don't allow empty selection when a choice is required.",
  ],
  a11y: const [
    'Each segment exposes selected semantics.',
    'Arrow-key behavior mirrors native radio groups.',
  ],
);

class _SegmentedDemo extends StatefulWidget {
  @override
  State<_SegmentedDemo> createState() => _SegmentedDemoState();
}

class _SegmentedDemoState extends State<_SegmentedDemo> {
  Set<String> _selection = {'day'};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FwSegmentedGroup<String>(
          items: const [
            FwSegmentedItem(
              value: 'day',
              label: 'Day',
              icon: Icon(Icons.wb_sunny_outlined, size: 18),
            ),
            FwSegmentedItem(
              value: 'week',
              label: 'Week',
              icon: Icon(Icons.date_range_outlined, size: 18),
            ),
            FwSegmentedItem(value: 'month', label: 'Month', enabled: false),
          ],
          selection: _selection,
          onSelectionChanged: (s) => setState(() => _selection = s),
          emptySelectionAllowed: false,
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${_selection.join(', ')}',
          style: context.fwTheme.typeScale.resolve(FwTextRole.bodySm, context),
        ),
      ],
    );
  }
}

/// A06 split button doc board.
Widget splitButtonDoc() => ComponentDoc(
  id: 'A06',
  name: 'Split button',
  tier: 'Molecules',
  summary:
      'A primary action plus an independently named menu trigger. Composes '
      'FwButton, FwIconButton and FwMenu: two distinct touch targets and '
      'focus stops. Opening the menu never invokes the primary action.',
  notFor: 'single actions (use FwButton), choice (use FwSegmentedGroup)',
  anatomy: const [
    AnatomyPart('Primary', 'the default action; its own button.'),
    AnatomyPart('Trigger', 'menu-only button with its own accessible name.'),
    AnatomyPart('Menu', 'FwMenu entries; selection is typed.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwSplitButton<String>(
        label: 'Save',
        onPressed: () {},
        entries: const [
          FwMenuAction(value: 'draft', label: 'Save draft'),
          FwMenuAction(value: 'template', label: 'Save as template'),
        ],
        onMenuSelected: (_) {},
      ),
      const SizedBox(height: 12),
      FwSplitButton<String>(
        label: 'Export',
        variant: FwButtonVariant.outline,
        intent: FwIntent.neutral,
        onPressed: () {},
        menuLabel: 'More export formats',
        entries: const [
          FwMenuAction(value: 'pdf', label: 'PDF'),
          FwMenuAction(value: 'csv', label: 'CSV'),
        ],
        onMenuSelected: (_) {},
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Gap', 's1 between primary and trigger.'),
    LayoutSpec('Targets', 'two independent 48dp touch targets.'),
  ],
  dos: const [
    'Give the trigger its own name ("More actions"), never the primary label.',
    'Reserve for a clear default plus alternatives.',
  ],
  donts: const [
    "Don't let the trigger invoke the primary action.",
    "Don't hide destructive actions only in the split menu.",
  ],
  a11y: const [
    'Two tab stops with distinct accessible names.',
    'Menu inherits FwMenu keyboard behavior.',
  ],
);

/// A09 copy action doc board.
Widget copyActionDoc() => const ComponentDoc(
  id: 'A09',
  name: 'Copy action',
  tier: 'Atoms',
  summary:
      'Copies text with bounded feedback: idle -> copying -> copied (or '
      'error), announced through a live region. Clipboard access is an '
      'injected interface; no permission is assumed and copied text is '
      'never logged or exposed to semantics.',
  notFor: 'copying secrets without user intent, rich content',
  anatomy: const [
    AnatomyPart('Trigger', 'icon button; tooltip is the accessible name.'),
    AnatomyPart('Feedback', 'copied/error icon swap, bounded duration.'),
    AnatomyPart('Live region', 'status announcements for screen readers.'),
  ],
  properties: const Row(
    children: [
      FwCopyAction(text: 'demo-token'),
      SizedBox(width: 12),
      FwCopyAction(text: 'demo-token', intent: FwIntent.neutral),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Feedback', 'reverts after 2s (configurable).'),
    LayoutSpec('Touch target', '48dp minimum.'),
  ],
  dos: const [
    'Use for copyable tokens, links, and codes.',
    'Keep the copied text out of semantics and logs.',
  ],
  donts: const [
    "Don't assume clipboard permission — handle failure.",
    "Don't leave the copied state visible indefinitely.",
  ],
  a11y: const [
    'Status changes announced via live region.',
    'Tooltip doubles as the accessible name.',
  ],
);

/// +A10 slide to confirm doc board.
Widget slideConfirmDoc() => ComponentDoc(
  id: 'A10',
  name: 'Slide to confirm',
  tier: 'Molecules',
  summary:
      'Drag the thumb past the threshold to confirm high-stakes actions. '
      'States: idle -> dragging -> loading -> success | failure. Drag '
      'direction follows text direction. A plain confirm button is always '
      'rendered as the keyboard/switch-access path — the gesture is never '
      'the only way.',
  notFor: 'low-stakes actions (use a button), reversible choices',
  anatomy: const [
    AnatomyPart('Track', 'progress fill follows the thumb.'),
    AnatomyPart('Thumb', 'drag handle; 48dp touch target.'),
    AnatomyPart('Status', 'label swaps through the state machine.'),
    AnatomyPart('Fallback', 'plain button; the accessible path.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwSlideToConfirm(onConfirm: () {}, fallbackLabel: 'Confirm payment'),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Threshold', '0.85 of track width by default.'),
    LayoutSpec('Height', '56dp track, 48dp thumb.'),
    LayoutSpec('Reset', 'terminal states hold 2s, then snap back.'),
  ],
  dos: const [
    'Use for payments, unlocks, irreversible sends.',
    'Always provide the fallback button.',
  ],
  donts: const [
    "Don't use slide-to-confirm for routine actions.",
    "Don't rely on drag animation under reduced motion.",
  ],
  a11y: const [
    'Fallback button is keyboard and switch-access reachable.',
    'Status changes announced through a live region.',
    'Reduced motion: thumb snaps instead of animating.',
  ],
);

/// +A11 hold to confirm doc board.
Widget holdConfirmDoc() => ComponentDoc(
  id: 'A11',
  name: 'Hold to confirm',
  tier: 'Molecules',
  summary:
      'Press-and-hold fills the button over a duration; releasing early '
      'cancels and resets. Haptics fire on press and on confirm. A plain '
      'button fallback covers non-gesture users; reduced-motion users '
      'confirm with a single tap.',
  notFor: 'low-stakes actions, timed interactions',
  anatomy: const [
    AnatomyPart('Fill', 'progress fill over the hold duration.'),
    AnatomyPart('Label', 'swaps to Confirmed on completion.'),
    AnatomyPart('Fallback', 'plain button; the accessible path.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [FwHoldToConfirm(onConfirm: () {}, fallbackLabel: 'Delete now')],
  ),
  layoutSpecs: const [
    LayoutSpec('Duration', '1200ms default hold.'),
    LayoutSpec('Height', '52dp.'),
  ],
  dos: const [
    'Use for destructive, irreversible actions.',
    'Pair with a confirmation dialog for the most severe actions.',
  ],
  donts: const [
    "Don't set hold durations above 2s.",
    "Don't use hold-to-confirm without the fallback.",
  ],
  a11y: const [
    'Fallback button is keyboard and switch-access reachable.',
    'Haptics are skipped under accessible navigation.',
    'Reduced motion: a tap confirms immediately.',
  ],
);

Widget tabsDoc() => ComponentDoc(
  id: 'N01',
  name: 'Tabs',
  tier: 'Molecules',
  summary:
      'Tabbed navigation with underline and contained variants. One '
      'selection model drives tabs and panels; FwTabPanels preserves panel '
      'state with optional lazy loading.',
  notFor: 'primary app navigation (use FwSidebar/FwBottomNavigation)',
  anatomy: const [
    AnatomyPart('Tab', 'selectable tab: label, icon, badge.'),
    AnatomyPart('Indicator', 'underline or pill marks selection.'),
    AnatomyPart('Panels', 'keep-alive or lazy content per tab.'),
  ],
  properties: _TabsDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Overflow', 'tabs scroll horizontally when they exceed width.'),
    LayoutSpec('Panels', 'fill the remaining space below the tab strip.'),
  ],
  dos: const [
    'Use tabs for peer views within one screen.',
    'Keep tab labels short; badges carry counts.',
  ],
  donts: const [
    "Don't use tabs for top-level app navigation.",
    "Don't put more than 6 tabs without scrolling.",
  ],
  a11y: const [
    'Tabs are in a tablist with arrow-key navigation.',
    'Panels are labelled by their tab.',
  ],
);

class _TabsDemoHost extends StatefulWidget {
  @override
  State<_TabsDemoHost> createState() => _TabsDemoHostState();
}

class _TabsDemoHostState extends State<_TabsDemoHost> {
  int _index = 0;
  FwTabVariant _variant = FwTabVariant.underline;

  static const _items = [
    FwTabItem(label: 'Overview'),
    FwTabItem(label: 'Details', icon: Icon(Icons.info_outline, size: 18)),
    FwTabItem(label: 'Activity', badgeLabel: '5'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<FwTabVariant>(
          segments: const [
            ButtonSegment(
              value: FwTabVariant.underline,
              label: Text('Underline'),
            ),
            ButtonSegment(
              value: FwTabVariant.contained,
              label: Text('Contained'),
            ),
          ],
          selected: {_variant},
          onSelectionChanged: (s) => setState(() => _variant = s.first),
        ),
        const SizedBox(height: 12),
        FwTabs(
          items: _items,
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
          variant: _variant,
        ),
        SizedBox(
          height: 100,
          child: FwTabPanels(
            selectedIndex: _index,
            children: const [
              Center(child: Text('Overview panel')),
              Center(child: Text('Details panel')),
              Center(child: Text('Activity panel')),
            ],
          ),
        ),
      ],
    );
  }
}

Widget breadcrumbDoc() => ComponentDoc(
  id: 'N04',
  name: 'Breadcrumb',
  tier: 'Molecules',
  summary:
      'Typed navigation trail. The current page is marked for screen '
      'readers; on narrow widths ancestors collapse into a menu.',
  notFor: 'primary navigation (use sidebar/rail/bottom nav)',
  anatomy: const [
    AnatomyPart('Crumb', 'link to an ancestor page.'),
    AnatomyPart('Separator', 'directional chevron between crumbs.'),
    AnatomyPart('Current page', 'non-link, marked current for AT.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwBreadcrumb(
        items: const [
          FwBreadcrumbItem(label: 'Home'),
          FwBreadcrumbItem(label: 'Projects'),
          FwBreadcrumbItem(label: 'Apollo'),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: 300,
        child: FwBreadcrumb(
          items: const [
            FwBreadcrumbItem(label: 'Home'),
            FwBreadcrumbItem(label: 'Projects'),
            FwBreadcrumbItem(label: 'Team'),
            FwBreadcrumbItem(label: 'Apollo'),
          ],
        ),
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec(
      'Collapse',
      'below 400px: first crumb, overflow menu, last two crumbs.',
    ),
    LayoutSpec('Separator', 'directional chevron, flips in RTL.'),
  ],
  dos: const [
    'Mark the current page for screen readers.',
    'Keep trails short; collapse handles the rest.',
  ],
  donts: const [
    "Don't make the current page a link.",
    "Don't use breadcrumbs as the only navigation.",
  ],
  a11y: const [
    'Current page carries the current-page semantics.',
    'Collapsed ancestors stay reachable via the overflow menu.',
  ],
);

Widget navbarDoc() => ComponentDoc(
  id: 'N02',
  name: 'Navbar',
  tier: 'Organisms',
  summary:
      'Top app bar: menu trigger, title, search slot, and actions. Below '
      '560px the actions collapse into a compact slot.',
  notFor: 'primary destination switching (use sidebar/rail/bottom nav)',
  anatomy: const [
    AnatomyPart('Menu trigger', 'opens the navigation drawer.'),
    AnatomyPart('Title', 'current section or product name.'),
    AnatomyPart('Actions', 'contextual actions; compact below 560px.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwNavbar(
        title: 'Dashboard',
        onMenuPressed: () {},
        actions: [
          FwIconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          FwIconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {},
          ),
        ],
        compactActions: [
          FwIconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onPressed: () {},
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: 400,
        child: FwNavbar(
          title: 'Dashboard',
          actions: [
            FwIconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () {},
            ),
          ],
          compactActions: [
            FwIconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More',
              onPressed: () {},
            ),
          ],
        ),
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Height', 'fixed 64px.'),
    LayoutSpec('Collapse', 'actions move to the compact slot under 560px.'),
    LayoutSpec('Title', 'truncates with ellipsis.'),
  ],
  dos: const [
    'Keep at most 3 actions; overflow the rest.',
    'Provide a compact slot for narrow widths.',
  ],
  donts: const [
    "Don't put primary navigation destinations in the navbar.",
    "Don't hide critical actions in the compact slot.",
  ],
  a11y: const [
    'Menu trigger has an accessible name.',
    'Title is a heading for screen readers.',
  ],
);

Widget sidebarDoc() => ComponentDoc(
  id: 'N03',
  name: 'Sidebar',
  tier: 'Organisms',
  summary:
      'Persistent desktop navigation driven by FwDestination models. '
      'Collapses to an icon rail with tooltips; nested destinations expand '
      'inline.',
  notFor: 'mobile navigation (use FwBottomNavigation)',
  anatomy: const [
    AnatomyPart('Destination', 'icon + label + optional badge.'),
    AnatomyPart('Group', 'labeled section of destinations.'),
    AnatomyPart('Nested', 'parent expands to reveal children.'),
  ],
  properties: _SidebarDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Width', '280px expanded, 72px collapsed.'),
    LayoutSpec('Model', 'one FwDestination list drives every surface.'),
    LayoutSpec('Nesting', 'one level; parents expand inline.'),
  ],
  dos: const [
    'Drive sidebar, rail, and bottom nav from one selection model.',
    'Group related destinations under labeled sections.',
  ],
  donts: const [
    "Don't duplicate selection state between sidebar and rail.",
    "Don't nest more than one level deep.",
  ],
  a11y: const [
    'Selected destination carries selected semantics.',
    'Collapsed icons expose tooltips as accessible names.',
    'Expand state is announced for nested parents.',
  ],
);

class _SidebarDemoHost extends StatefulWidget {
  @override
  State<_SidebarDemoHost> createState() => _SidebarDemoHostState();
}

class _SidebarDemoHostState extends State<_SidebarDemoHost> {
  String _selected = 'home';
  bool _expanded = true;

  static const _destinations = [
    FwDestination(id: 'home', label: 'Home', icon: Icon(Icons.home_outlined)),
    FwDestination(
      id: 'search',
      label: 'Search',
      icon: Icon(Icons.search_outlined),
      badgeLabel: '3',
    ),
    FwDestination(
      id: 'reports',
      label: 'Reports',
      icon: Icon(Icons.bar_chart_outlined),
      children: [
        FwDestination(
          id: 'weekly',
          label: 'Weekly',
          icon: Icon(Icons.calendar_view_week_outlined),
        ),
        FwDestination(
          id: 'monthly',
          label: 'Monthly',
          icon: Icon(Icons.calendar_month_outlined),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Expanded'),
          value: _expanded,
          onChanged: (v) => setState(() => _expanded = v),
        ),
        SizedBox(
          height: 320,
          child: FwSidebar(
            destinations: _destinations,
            selectedId: _selected,
            onDestinationSelected: (id) => setState(() => _selected = id),
            expanded: _expanded,
            header: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Acme'),
            ),
          ),
        ),
      ],
    );
  }
}

Widget paginationDoc() => ComponentDoc(
  id: 'N05',
  name: 'Pagination',
  tier: 'Molecules',
  summary:
      'Page navigation with first/prev/numbered/next/last and an optional '
      'page-size selector. Page numbers collapse with ellipsis.',
  notFor: 'infinite scroll (use lazy loading)',
  anatomy: const [
    AnatomyPart('Nav buttons', 'first/previous/next/last, disabled at bounds.'),
    AnatomyPart('Page numbers', '1-based; ellipsis marks gaps.'),
    AnatomyPart('Page size', 'optional rows-per-page selector.'),
  ],
  properties: _PaginationDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Overflow', 'wraps on narrow widths.'),
    LayoutSpec('Targets', '40px minimum touch targets.'),
  ],
  dos: const [
    'Disable (not hide) nav buttons at the bounds.',
    'Announce the current page to screen readers.',
  ],
  donts: const [
    "Don't use pagination for fewer than 2 pages.",
    "Don't reset to page 1 silently on filter change.",
  ],
  a11y: const [
    'The control announces "page X of Y".',
    'Current page carries selected semantics.',
  ],
);

class _PaginationDemoHost extends StatefulWidget {
  @override
  State<_PaginationDemoHost> createState() => _PaginationDemoHostState();
}

class _PaginationDemoHostState extends State<_PaginationDemoHost> {
  int _page = 1;
  int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    return FwPagination(
      page: _page,
      pageCount: 12,
      onPageChanged: (p) => setState(() => _page = p),
      pageSizes: const [10, 20, 50],
      pageSize: _pageSize,
      onPageSizeChanged: (s) => setState(() => _pageSize = s),
    );
  }
}

Widget stepperDoc() => ComponentDoc(
  id: 'N06',
  name: 'Stepper',
  tier: 'Molecules',
  summary:
      'Linear progress with skippable steps, validation gating via '
      'onStepContinue, and a controlsBuilder for custom buttons.',
  notFor: 'non-linear flows (use tabs)',
  anatomy: const [
    AnatomyPart('Step', 'marker, label, optional description.'),
    AnatomyPart('Connector', 'progress line between steps.'),
    AnatomyPart('Controls', 'Continue/Back/Skip; customizable.'),
  ],
  properties: _StepperDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Axis', 'horizontal or vertical.'),
    LayoutSpec('Labels', 'truncate with ellipsis at 2x text.'),
  ],
  dos: const [
    'Gate Continue on validation via onStepContinue.',
    'Mark optional steps; offer Skip.',
  ],
  donts: const [
    "Don't let users skip required steps.",
    "Don't use a stepper for more than 7 steps.",
  ],
  a11y: const [
    'Steps announce position and current state.',
    'Validation failures are announced, not just colored.',
  ],
);

class _StepperDemoHost extends StatefulWidget {
  @override
  State<_StepperDemoHost> createState() => _StepperDemoHostState();
}

class _StepperDemoHostState extends State<_StepperDemoHost> {
  int _step = 0;

  static const _steps = [
    FwStepData(label: 'Account', description: 'Email and password'),
    FwStepData(label: 'Profile', description: 'Optional bio', optional: true),
    FwStepData(label: 'Review', description: 'Confirm details'),
  ];

  @override
  Widget build(BuildContext context) {
    return FwStepper(
      steps: _steps,
      currentStep: _step,
      onStepChanged: (i) => setState(() => _step = i),
    );
  }
}

Widget bottomNavigationDoc() => ComponentDoc(
  id: 'N07',
  name: 'Bottom navigation',
  tier: 'Organisms',
  summary:
      'Compact-width primary navigation. Same FwDestination model as the '
      'rail and sidebar; one selection model drives all three.',
  notFor: 'more than 5 destinations (use a drawer)',
  anatomy: const [
    AnatomyPart('Item', 'icon, label, optional badge.'),
    AnatomyPart('Selection', 'controlled; shared with rail/sidebar.'),
  ],
  properties: _BottomNavDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Items', 'max 5; labels truncate to one line.'),
    LayoutSpec('Safe area', 'respects the bottom system inset.'),
  ],
  dos: const [
    'Share one selection model across bottom nav, rail, and sidebar.',
    'Keep labels to one or two words.',
  ],
  donts: const [
    "Don't duplicate selection state per surface.",
    "Don't use bottom nav on desktop widths.",
  ],
  a11y: const [
    'Selected item carries selected semantics.',
    'Badges expose their count as a label.',
  ],
);

class _BottomNavDemoHost extends StatefulWidget {
  @override
  State<_BottomNavDemoHost> createState() => _BottomNavDemoHostState();
}

class _BottomNavDemoHostState extends State<_BottomNavDemoHost> {
  String _selected = 'home';

  static const _destinations = [
    FwDestination(id: 'home', label: 'Home', icon: Icon(Icons.home_outlined)),
    FwDestination(
      id: 'search',
      label: 'Search',
      icon: Icon(Icons.search_outlined),
      badgeLabel: '3',
    ),
    FwDestination(
      id: 'library',
      label: 'Library',
      icon: Icon(Icons.library_books_outlined),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FwBottomNavigation(
      destinations: _destinations,
      selectedId: _selected,
      onDestinationSelected: (id) => setState(() => _selected = id),
    );
  }
}

Widget navigationRailDoc() => ComponentDoc(
  id: 'N08',
  name: 'Navigation rail',
  tier: 'Organisms',
  summary:
      'Medium-width primary navigation: a vertical icon rail with optional '
      'labels and leading/trailing slots.',
  notFor: 'compact widths (use bottom navigation)',
  anatomy: const [
    AnatomyPart('Item', 'pill-highlighted icon + label.'),
    AnatomyPart('Leading/trailing', 'slots for FAB or avatar.'),
  ],
  properties: _RailDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Width', '80px default.'),
    LayoutSpec('Labels', 'below icons; tooltips when hidden.'),
  ],
  dos: const [
    'Share one selection model across rail, sidebar, and bottom nav.',
    'Use the leading slot for the primary action.',
  ],
  donts: const [
    "Don't put more than 7 destinations in the rail.",
    "Don't hide labels without tooltips.",
  ],
  a11y: const [
    'Selected item carries selected semantics.',
    'Hidden labels surface as tooltips.',
  ],
);

class _RailDemoHost extends StatefulWidget {
  @override
  State<_RailDemoHost> createState() => _RailDemoHostState();
}

class _RailDemoHostState extends State<_RailDemoHost> {
  String _selected = 'home';

  static const _destinations = [
    FwDestination(id: 'home', label: 'Home', icon: Icon(Icons.home_outlined)),
    FwDestination(
      id: 'search',
      label: 'Search',
      icon: Icon(Icons.search_outlined),
      badgeLabel: '3',
    ),
    FwDestination(
      id: 'settings',
      label: 'Settings',
      icon: Icon(Icons.settings_outlined),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Row(
        children: [
          FwNavigationRail(
            destinations: _destinations,
            selectedId: _selected,
            onDestinationSelected: (id) => setState(() => _selected = id),
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add_circle_outline),
            ),
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: Center(child: Text('Content'))),
        ],
      ),
    );
  }
}

Widget adaptiveScaffoldDoc() => ComponentDoc(
  id: 'L09',
  name: 'Adaptive scaffold',
  tier: 'Organisms',
  summary:
      'Bottom navigation on compact, rail on medium, sidebar on expanded. '
      'One selection model drives all; bodies stay mounted so state '
      'survives width transitions.',
  notFor: 'single-width layouts (use plain Scaffold)',
  anatomy: const [
    AnatomyPart('Destinations', 'one FwDestination list for every surface.'),
    AnatomyPart('Bodies', 'IndexedStack keeps state across transitions.'),
    AnatomyPart('Breakpoints', '600 / 1240 logical px via FwGrid.'),
  ],
  properties: _AdaptiveScaffoldDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Compact <600', 'FwBottomNavigation.'),
    LayoutSpec('Medium 600-1240', 'FwNavigationRail.'),
    LayoutSpec('Expanded >=1240', 'FwSidebar.'),
  ],
  dos: const [
    'Drive all surfaces from one selection model.',
    'Keep bodies mounted to preserve field and scroll state.',
  ],
  donts: const [
    "Don't duplicate destination lists per breakpoint.",
    "Don't rebuild bodies on width change.",
  ],
  a11y: const [
    'Navigation landmarks are labeled per surface.',
    'Selection changes are announced.',
  ],
);

class _AdaptiveScaffoldDemoHost extends StatefulWidget {
  @override
  State<_AdaptiveScaffoldDemoHost> createState() =>
      _AdaptiveScaffoldDemoHostState();
}

class _AdaptiveScaffoldDemoHostState extends State<_AdaptiveScaffoldDemoHost> {
  String _selected = 'home';

  static const _destinations = [
    FwDestination(id: 'home', label: 'Home', icon: Icon(Icons.home_outlined)),
    FwDestination(
      id: 'search',
      label: 'Search',
      icon: Icon(Icons.search_outlined),
    ),
    FwDestination(
      id: 'settings',
      label: 'Settings',
      icon: Icon(Icons.settings_outlined),
    ),
  ];

  static const _bodies = {
    'home': Center(child: Text('Home body')),
    'search': Center(child: Text('Search body')),
    'settings': Center(child: Text('Settings body')),
  };

  Widget _preview(String label, double width, FwViewportClass cls) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$label (${width.round()}px)'),
        const SizedBox(height: 8),
        Container(
          height: 380,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          // Fixed preview widths; the outer scrolls horizontally on narrow
          // screens instead of overflowing.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: FwAdaptiveScaffold(
                destinations: _destinations,
                selectedId: _selected,
                onDestinationSelected: (id) => setState(() => _selected = id),
                bodies: _bodies,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _preview('Compact: bottom navigation', 360, FwViewportClass.compact),
        const SizedBox(height: 16),
        _preview('Medium: navigation rail', 700, FwViewportClass.medium),
        const SizedBox(height: 16),
        _preview('Expanded: sidebar', 1000, FwViewportClass.expanded),
      ],
    );
  }
}

Widget masterDetailDoc() => ComponentDoc(
  id: 'L10',
  name: 'Master-detail',
  tier: 'Organisms',
  summary:
      'Split view on wide, stacked with system-back on narrow. Both panes '
      'stay mounted so scroll and field state survive.',
  notFor: 'unrelated screens (use navigation)',
  anatomy: const [
    AnatomyPart('Master', 'list pane; selection drives the detail.'),
    AnatomyPart('Detail', 'content pane; full-screen on narrow.'),
    AnatomyPart('Back', 'PopScope returns to master on narrow.'),
  ],
  properties: _MasterDetailDemoHost(),
  layoutSpecs: const [
    LayoutSpec('Breakpoint', '720px default; master 360px.'),
    LayoutSpec('Narrow', 'IndexedStack; system back pops to master.'),
  ],
  dos: const [
    'Map onSelected to your router for deep links.',
    'Keep both panes mounted to preserve state.',
  ],
  donts: const [
    "Don't lose detail state on rotation.",
    "Don't show an empty detail without an empty state.",
  ],
  a11y: const [
    'Back navigation is announced on narrow.',
    'Master list uses list semantics.',
  ],
);

class _MasterDetailDemoHost extends StatefulWidget {
  @override
  State<_MasterDetailDemoHost> createState() => _MasterDetailDemoHostState();
}

class _MasterDetailDemoHostState extends State<_MasterDetailDemoHost> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: FwMasterDetail(
        master: ListView(
          children: [
            for (var i = 0; i < 8; i++)
              ListTile(
                title: Text('Item $i'),
                selected: _selected == 'item-$i',
                onTap: () => setState(() => _selected = 'item-$i'),
              ),
          ],
        ),
        detail: Center(child: Text('Detail: ${_selected ?? 'none'}')),
        selectedId: _selected,
        onSelected: (id) => setState(() => _selected = id),
        emptyDetail: const Center(child: Text('Select an item')),
      ),
    );
  }
}

Widget onboardingDoc() => ComponentDoc(
  id: 'R01',
  name: 'Onboarding flow',
  tier: 'Organisms',
  summary:
      'Intro pages with indicators, Skip, and Next/Get started. The app '
      'owns completion; onDone/onSkip are the route-neutral contracts.',
  notFor: 'feature tours inside the app (use coach marks)',
  anatomy: const [
    AnatomyPart('Page', 'title, body, optional illustration.'),
    AnatomyPart('Indicators', 'animated dots mark progress.'),
    AnatomyPart('Actions', 'Skip, Next, Get started.'),
  ],
  properties: SizedBox(
    height: 480,
    child: FwOnboardingFlow(
      pages: const [
        FwOnboardingPage(
          title: 'Welcome',
          body: 'A quick tour of what this app can do.',
          illustration: Icon(Icons.waving_hand_outlined, size: 64),
        ),
        FwOnboardingPage(
          title: 'Stay organized',
          body: 'Everything you need, one tap away.',
          illustration: Icon(Icons.dashboard_outlined, size: 64),
        ),
        FwOnboardingPage(
          title: 'Ready',
          body: "Let's get started.",
          illustration: Icon(Icons.rocket_launch_outlined, size: 64),
        ),
      ],
      onDone: () {},
      onSkip: () {},
    ),
  ),
  layoutSpecs: const [
    LayoutSpec('Pages', 'PageView; swipe can be disabled.'),
    LayoutSpec('Indicators', '24px active, 8px inactive.'),
  ],
  dos: const ['Always offer Skip.', 'Persist the seen flag in the app.'],
  donts: const [
    "Don't show onboarding on every launch.",
    "Don't put more than 5 pages.",
  ],
  a11y: const [
    'Page changes are announced with position.',
    'All actions are keyboard reachable.',
  ],
);

Widget scrollAreaDoc() => const ComponentDoc(
  id: 'L08',
  name: 'Scroll area',
  tier: 'Molecules',
  summary:
      'Scrollable region with matching scrollbars. The controller is '
      'caller-owned so position can be preserved and restored.',
  notFor: 'short content that fits (no scroll needed)',
  anatomy: [
    AnatomyPart('Viewport', 'SingleChildScrollView.'),
    AnatomyPart('Scrollbar', 'optional; follows the controller.'),
  ],
  properties: SizedBox(
    height: 160,
    child: FwScrollArea(
      child: Column(
        children: [
          Text('Line 1'),
          Text('Line 2'),
          Text('Line 3'),
          Text('Line 4'),
          Text('Line 5'),
          Text('Line 6'),
          Text('Line 7'),
          Text('Line 8'),
        ],
      ),
    ),
  ),
  layoutSpecs: [
    LayoutSpec('Controller', 'caller-owned; never created internally.'),
  ],
  dos: [
    'Own the controller to restore scroll position.',
    'Use for overflow content, not for page layout.',
  ],
  donts: ["Don't nest scroll areas without a bounded height."],
  a11y: ['Keyboard scrolling works via the native scrollable.'],
);

Widget sliverAdaptersDoc() => const ComponentDoc(
  id: 'L12',
  name: 'Sliver adapters',
  tier: 'Molecules',
  summary:
      'Padded sliver sections and sticky headers for CustomScrollView. '
      'Stay lazy; keep scroll physics unified.',
  notFor: 'short lists (use Column)',
  anatomy: [
    AnatomyPart('Section', 'SliverPadding + SliverList or SliverGrid.'),
    AnatomyPart('Sticky header', 'pins while content scrolls under.'),
  ],
  properties: SizedBox(
    height: 280,
    child: CustomScrollView(
      slivers: [
        FwStickyHeader(child: Text('Pinned header')),
        FwSliverSection(
          children: [Text('Row 1'), Text('Row 2'), Text('Row 3')],
        ),
        FwStickyHeader(child: Text('Grid section')),
        FwSliverSection(
          columns: 2,
          children: [
            Text('Cell 1'),
            Text('Cell 2'),
            Text('Cell 3'),
            Text('Cell 4'),
          ],
        ),
      ],
    ),
  ),
  layoutSpecs: [
    LayoutSpec('Padding', 'defaults to the pageInset alias.'),
    LayoutSpec('Grid', 'lazy; configurable columns.'),
  ],
  dos: [
    'Prefer slivers over shrink-wrapped grids in long pages.',
    'Give sticky headers an opaque background.',
  ],
  donts: ["Don't put slivers inside a Column without bounds."],
  a11y: ['Headers are headings for screen readers.'],
);
Widget richTextDoc() => ComponentDoc(
  id: 'T02',
  name: 'Rich text',
  tier: 'Atoms',
  summary:
      'Inline-styled paragraph: emphasis, tappable links, and code spans in '
      'one text flow. Recognizers are owned and disposed by the widget; '
      'selectable rendering is a separate documented path.',
  notFor: 'block structure (use Quote/Lists), markdown parsing',
  anatomy: [
    const AnatomyPart('Segments', 'typed list: text, link, or code.'),
    const AnatomyPart('Emphasis', 'bold/italic/underline/strikethrough.'),
    const AnatomyPart('Link', 'underlined intent color, tap recognizer.'),
    const AnatomyPart('Code span', 'monospace on a tokenized surface.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwRichText(
        segments: [
          const FwTextSegment('Ship '),
          FwLinkSegment('accessible', onTap: () {}),
          const FwTextSegment(' UI with '),
          const FwCodeSegment('FwRichText'),
          const FwTextSegment(' — ', emphasis: FwEmphasis.bold),
          const FwTextSegment('fast.', emphasis: FwEmphasis.italic),
        ],
      ),
      const SizedBox(height: 8),
      const FwRichText(
        selectable: true,
        segments: [FwTextSegment('Selectable rendering path.')],
      ),
    ],
  ),
  layoutSpecs: [
    const LayoutSpec('Flow', 'wraps as one paragraph; essential text wraps.'),
    const LayoutSpec('Role', 'any typography role via [role].'),
  ],
  dos: [
    'Keep links few and descriptive inside a paragraph.',
    'Use selectable mode for content users may copy.',
  ],
  donts: ["Don't nest interactive spans inside buttons."],
  a11y: [
    'Link segments expose link semantics with tap actions.',
    'Recognizers are disposed — no leaked gesture state.',
  ],
);

/// T09 read-more doc board.
Widget readMoreDoc() => const ComponentDoc(
  id: 'T09',
  name: 'Read more',
  tier: 'Molecules',
  summary:
      'Expandable paragraph: truncates to a line limit with a real button '
      'toggle. The full text is always one tap away for keyboard and '
      'screen-reader users.',
  notFor: 'accordion sections (use FwAccordion), hiding essential content',
  anatomy: const [
    AnatomyPart('Text', 'truncated with ellipsis at maxLines.'),
    AnatomyPart('Toggle', 'button switching Read more / Show less.'),
  ],
  properties: FwReadMore(
    text:
        'Flutter is Google’s UI toolkit for building natively compiled '
        'applications for mobile, web, and desktop from a single codebase. '
        'It uses the Dart language and a reactive widget tree to describe '
        'the interface declaratively, rebuilding only what changes.',
  ),
  layoutSpecs: const [
    LayoutSpec('Lines', '3 by default; configurable.'),
    LayoutSpec('Toggle', 'text button directly under the paragraph.'),
  ],
  dos: const [
    'Use a button toggle, never a tap-on-text gesture alone.',
    'Keep truncated previews meaningful without expansion.',
  ],
  donts: const ["Don't truncate legally required or safety-critical text."],
  a11y: const [
    'Toggle is a button with a clear label.',
    'Expansion is immediate; no animation to wait for.',
  ],
);


Widget quoteListDoc() => const ComponentDoc(
  id: 'T07',
  name: 'Quote & lists',
  tier: 'Atoms',
  summary:
      'Blockquote with directional marker and citation; nested bullet and '
      'ordered lists with depth-appropriate markers. Markers sit on the '
      'logical start side and flip in RTL.',
  notFor: 'interactive disclosure (use Accordion)',
  anatomy: [
    AnatomyPart('Marker', 'border (quote) or glyph (lists), logical-start.'),
    AnatomyPart('Citation', 'caption role, em-dash prefixed.'),
    AnatomyPart('Nesting', 'depth changes bullet glyph / number style.'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FwQuote(
        text: 'Simplicity is the soul of efficiency.',
        citation: 'Austin Freeman',
      ),
      SizedBox(height: 12),
      FwBulletList(
        items: [
          FwListItemData(
            'First principle',
            children: [FwListItemData('Nested detail')],
          ),
          FwListItemData('Second principle'),
        ],
      ),
      SizedBox(height: 12),
      FwOrderedList(
        items: [
          FwListItemData(
            'Setup',
            children: [FwListItemData('Install'), FwListItemData('Configure')],
          ),
          FwListItemData('Ship'),
        ],
      ),
    ],
  ),
  layoutSpecs: [
    LayoutSpec('Indent', 's4 per nesting level.'),
    LayoutSpec('Marker column', 'fixed s4-wide, centered glyph.'),
  ],
  dos: ['Nest at most three levels deep.', 'Keep item text short.'],
  donts: ["Don't use lists for tabular data (use the data table)."],
  a11y: [
    'Items read in document order.',
    'Quote marker is decorative; text stays readable.',
  ],
);

Widget codeDoc() => ComponentDoc(
  id: 'T08',
  name: 'Code & keyboard',
  tier: 'Atoms',
  summary:
      'Inline code spans, code blocks with wrap-or-scroll and copy action, '
      'and keyboard-shortcut chips. Code renders verbatim — syntax '
      'highlighting is adapter work, not core.',
  notFor: 'rich text editing, syntax-highlighted display',
  anatomy: [
    const AnatomyPart('Inline code', 'monospace on a subtle surface.'),
    const AnatomyPart('Block', 'tokenized container, optional language tag.'),
    const AnatomyPart('Copy', 'icon button writing to the clipboard.'),
    const AnatomyPart('Kbd', 'one chip per key, joined by "+".'),
  ],
  properties: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const FwInlineCode(code: 'flutter pub get'),
      const SizedBox(height: 8),
      FwCodeBlock(
        code: 'void main() {\n  runApp(const App());\n}',
        language: 'dart',
        onCopied: () {},
      ),
      const SizedBox(height: 8),
      const FwKbd(keys: ['⌘', 'K']),
    ],
  ),
  layoutSpecs: [
    const LayoutSpec('Block scroll', 'horizontal scroll unless [wrap].'),
    const LayoutSpec('Copy target', 'icon button, 48px touch target.'),
  ],
  dos: [
    'Label the code language when known.',
    'Confirm copies with a toast via onCopied.',
  ],
  donts: ["Don't put secrets in copyable blocks without warning."],
  a11y: [
    'Kbd announces keys joined with "plus", not the "+" glyph.',
    'Code blocks expose a "Code" semantics label.',
  ],
);

/// U01 dotted border doc board.
Widget dottedBorderDoc() => const ComponentDoc(
  id: 'U01',
  name: 'Dotted border',
  tier: 'Atoms',
  summary:
      'Dotted and dashed borders for drop zones, empty states, and coupon-style cards. '
      'The pattern is painted; the color is a theme role.',
  anatomy: const [
    AnatomyPart('Pattern', 'Round dots or short dashes.'),
    AnatomyPart('Border', 'theme-role color, configurable stroke.'),
  ],
  properties: Wrap(
    spacing: 16,
    runSpacing: 16,
    children: const [
      FwDottedBorder(child: Text('Dotted (default)')),
      FwDottedBorder(style: FwBorderStyle.dashed, child: Text('Dashed')),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Pattern', 'Dot = round cap; dash = dashWidth x strokeWidth.'),
    LayoutSpec('Padding', 'Inner padding, defaults to 16px token.'),
  ],
  dos: const [
    'Use dotted borders to signal drop targets and placeholders.',
    'Pair with an explicit label inside the border.',
  ],
  donts: const [
    "Don't use dotted borders as the only affordance for a drop zone.",
  ],
  a11y: const ['The border itself is decorative; the child carries semantics.'],
);

/// B12 badge placement doc board.
Widget badgePlacementDoc() => const ComponentDoc(
  id: 'B12',
  name: 'Badge placement',
  tier: 'Atoms',
  summary:
      'Overlays a badge on an icon, avatar, or button at a corner. '
      'The offset nudges the badge outward into the margin.',
  anatomy: const [
    AnatomyPart('Child', 'The annotated widget.'),
    AnatomyPart('Badge', 'Center anchored to the chosen corner.'),
  ],
  properties: const Wrap(
    spacing: 32,
    runSpacing: 16,
    children: [
      FwBadgePlacement(
        badge: FwBadge(count: 3),
        child: Icon(Icons.mail, size: 40),
      ),
      FwBadgePlacement(
        badge: FwBadge(dot: true),
        child: Icon(Icons.notifications, size: 40),
      ),
    ],
  ),
  layoutSpecs: const [
    LayoutSpec('Alignment', 'Corner anchor; badge center sits on the corner.'),
    LayoutSpec('Offset', 'Positive values push the badge outward.'),
  ],
  dos: const [
    'Use count badges for unread totals; use dot badges for "new" flags.',
  ],
  donts: const ["Don't cover the child's interactive affordance."],
  a11y: const [
    'The badge is announced after the child in the semantics tree.',
    'Counts get a semantic label ("3 unread"), not just the digit.',
  ],
);

/// M14 empty state doc board.
Widget emptyStateDoc() => ComponentDoc(
  id: 'M14',
  name: 'Empty state',
  tier: 'Molecules',
  summary:
      'A centered composition for "nothing here yet": artwork, title, '
      'description, and a call to action. Artwork is caller-supplied.',
  anatomy: const [
    AnatomyPart('Art', 'Icon in a 72dp circle, or custom illustration.'),
    AnatomyPart('Title', 'Heading explaining the empty state.'),
    AnatomyPart('Action', 'A single centered call to action.'),
  ],
  properties: FwEmptyState(
    icon: Icons.inbox,
    title: 'No messages',
    description: 'When someone writes to you, it will show up here.',
    action: FwButton(label: 'Compose', onPressed: () {}),
  ),
  layoutSpecs: const [
    LayoutSpec('Art', '72dp circle for the icon slot; custom art any size.'),
    LayoutSpec('Action', 'A single primary action, centered.'),
  ],
  dos: const [
    'Explain why the screen is empty and what to do next.',
    'Keep one clear action.',
  ],
  donts: const ["Don't show an empty state for loading - use a skeleton."],
  a11y: const [
    'The title is the heading; screen readers get title then description.',
  ],
);
