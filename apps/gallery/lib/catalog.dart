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
      'The primary action control. Visual variant (solid, outline, ghost, '
      'link) is separate from semantic intent (primary, neutral, success, '
      'warning, danger, info): a destructive action is a solid danger '
      'button, not a red-styled primary.',
  notFor: 'navigation (use FwLink), icon-only actions (use FwIconButton)',
  anatomy: const [
    AnatomyPart('Label', 'label role; wraps instead of truncating.'),
    AnatomyPart(
      'Container',
      'intent colors from FwButtonColors (layer-3 tokens); state-layer '
          'overlays for hover/pressed/focus.',
    ),
    AnatomyPart('Icon slots', 'optional leading/trailing, s2 gap.'),
    AnatomyPart('Focus ring', 'focusWidth token, visible on all intents.'),
  ],
  properties: _matrix([
    for (final intent in FwIntent.values)
      FwButton(label: intent.name, intent: intent, onPressed: () {}),
    for (final variant in FwButtonVariant.values)
      FwButton(label: variant.name, variant: variant, onPressed: () {}),
    for (final size in FwButtonSize.values)
      FwButton(label: size.name, size: size, onPressed: () {}),
    const FwButton(label: 'Disabled', onPressed: null),
    const FwButton(
      label: 'Save',
      loading: true,
      loadingLabel: 'Saving…',
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
    LayoutSpec('Radius', 'md token.'),
    LayoutSpec('Label', 'grows and wraps; never clipped.'),
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

Widget listDoc() => const ComponentDoc(
  id: 'D02',
  name: 'List',
  tier: 'Organisms',
  summary:
      'Scrollable collection of FwListTile rows with token padding. '
      'Compose for settings, inboxes, and menus.',
  notFor: 'grids, very long virtualized collections (use slivers)',
  anatomy: [
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
  layoutSpecs: [
    LayoutSpec('Padding', 'FwSpace token; s0 available.'),
    LayoutSpec('Scrolling', 'native ScrollView; caller owns controller.'),
  ],
  dos: [
    'Keep rows homogeneous in height where possible.',
    'Own the scroll controller in the caller.',
  ],
  donts: ["Don't nest shrink-wrapped lists inside long pages."],
  a11y: [
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
  anatomy: [
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
  layoutSpecs: [
    LayoutSpec('Breakpoints', 'FwBreakpoint values; exact minimums.'),
  ],
  dos: [
    'State the retention policy where it matters.',
    'Test that hidden controls are not focusable.',
  ],
  donts: ["Don't hide required actions where users can't find them."],
  a11y: [
    'Removed children leave the semantics tree.',
    'Retained state has a documented memory cost.',
  ],
);
