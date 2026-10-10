import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

/// P2 (improvement-plan-2) layout primitives board: FwGap, FwBox, FwInline,
/// and the token-gated FwWrap.
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired into main.dart):
///
/// ```dart
/// import 'docs/layout_p2_doc.dart';
/// // inside tokenBoards() in catalog.dart:
/// board('Layout primitives (P2)', layoutPrimitivesBoard()),
/// ```

/// Interactive demos for the P2 spacing primitives.
Widget layoutPrimitivesBoard() => Builder(
  builder: (context) {
    final typeScale = context.fwTheme.typeScale;
    Widget section(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: typeScale.resolve(FwTextRole.h4, context)),
        const FwGap(FwSpace.s2),
        child,
        const FwGap(FwSpace.s4),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('FwGap — the single spacer', const _GapDemo()),
        section('FwBox — logical padding', const _BoxDemo()),
        section('FwInline — wrapping flow', const _InlineDemo()),
        section('FwWrap — token-gated wrap', const _WrapDemo()),
      ],
    );
  },
);

class _GapDemo extends StatefulWidget {
  const _GapDemo();

  @override
  State<_GapDemo> createState() => _GapDemoState();
}

class _GapDemoState extends State<_GapDemo> {
  var _token = FwSpace.s4;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final px =
        theme.spaceScale.of(_token, context) *
        FwMetrics.of(context).density.gapScale;
    Widget block(Color color) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.xs)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FwWrap(
          gap: FwSpace.s1,
          runGap: FwSpace.s1,
          children: [
            for (final t in [FwSpace.s1, FwSpace.s2, FwSpace.s4, FwSpace.s8])
              ChoiceChip(
                label: Text(t.name),
                selected: _token == t,
                onSelected: (_) => setState(() => _token = t),
              ),
          ],
        ),
        const FwGap(FwSpace.s2),
        Row(
          children: [
            block(theme.colors.scheme.primary),
            FwGap(_token),
            block(theme.colors.scheme.secondary),
            const FwGap(FwSpace.s2),
            Expanded(
              child: Text(
                '${_token.name} → ${px.toStringAsFixed(1)}px '
                '(density ×${FwMetrics.of(context).density.gapScale})',
                style: theme.typeScale.resolve(FwTextRole.caption, context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BoxDemo extends StatefulWidget {
  const _BoxDemo();

  @override
  State<_BoxDemo> createState() => _BoxDemoState();
}

class _BoxDemoState extends State<_BoxDemo> {
  var _rtl = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('RTL'),
            Switch(value: _rtl, onChanged: (v) => setState(() => _rtl = v)),
          ],
        ),
        Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: FwBox(
            paddingInlineStart: FwSpace.s8,
            paddingBlock: FwSpace.s2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colors.scheme.primaryContainer,
                borderRadius: BorderRadius.circular(
                  theme.radii.of(FwRadius.xs),
                ),
              ),
              child: Center(
                child: Text(
                  'start = ${_rtl ? 'right' : 'left'} in ${_rtl ? 'RTL' : 'LTR'}',
                  style: theme.typeScale.resolve(FwTextRole.caption, context),
                ),
              ),
            ),
          ),
        ),
        const FwGap(FwSpace.s2),
        Text(
          'paddingInlineStart: s8, paddingBlock: s2 — no physical left/right '
          'in the API.',
          style: theme.typeScale.resolve(FwTextRole.caption, context),
        ),
      ],
    );
  }
}

class _InlineDemo extends StatelessWidget {
  const _InlineDemo();

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: EdgeInsets.all(
            context.fwTheme.spaceScale.of(FwSpace.s2, context),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colors.of(FwColorRole.border)),
            borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.xs)),
          ),
          child: FwInline(
            gap: FwSpace.s2,
            rowGap: FwSpace.s2,
            children: [
              for (var i = 1; i <= 8; i++)
                Chip(label: Text('Tag $i'), key: ValueKey('tag-$i')),
            ],
          ),
        ),
        const FwGap(FwSpace.s2),
        Text(
          'FwInline wraps like Wrap but speaks tokens (gap + rowGap). '
          'FwHStack stays the non-wrapping variant.',
          style: theme.typeScale.resolve(FwTextRole.caption, context),
        ),
      ],
    );
  }
}

class _WrapDemo extends StatelessWidget {
  const _WrapDemo();

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Text(
      'FwWrap (L04) already gates Wrap.spacing/runSpacing behind FwSpace '
      'tokens — P2.3 verified the widget, its tests, and that no raw '
      'spacing: literals remain (P1.4 migrated them).',
      style: theme.typeScale.resolve(FwTextRole.caption, context),
    );
  }
}
