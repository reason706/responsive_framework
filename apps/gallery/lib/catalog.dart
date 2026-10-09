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
    const FwButton(
      label: 'Save',
      loading: true,
      loadingLabel: 'Saving…',
      onPressed: null,
    ),
    FwAsyncButton(label: 'Upload', onPressed: () async {}),
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
      'The circular form offers the same contract for compact spaces.',
  notFor: 'exact numeric entry (use a number field), ranges (Phase 4)',
  anatomy: const [
    AnatomyPart('Label', 'merged into the slider semantics.'),
    AnatomyPart('Readout', 'formatted value; visual only.'),
    AnatomyPart('Track', 'token colors; tick marks when discrete.'),
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
