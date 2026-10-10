import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

/// P3 (improvement-plan-2) hierarchy boards: elevation, density, and the
/// one-change-at-a-time playground.
///
/// Registration (add to catalog.dart — this file is deliberately not wired
/// into main.dart):
///
/// ```dart
/// import 'docs/hierarchy_p3_doc.dart';
/// // inside tokenBoards() in catalog.dart:
/// board('Elevation (P3)', elevationBoard()),
/// board('Density (P3)', densityBoard()),
/// board('Hierarchy playground (P3)', hierarchyPlaygroundBoard()),
/// ```

/// All six elevation levels with a tonal toggle.
///
/// P3.1 adopts the Material 3 stance: tonal surface tint *plus* shadow.
/// The one visual-breaking change in plan 2: FwSheet moved 3 → 1 and
/// FwCard.elevated gained the level-1 tint.
Widget elevationBoard() => Builder(
  builder: (context) {
    return const _ElevationDemo();
  },
);

class _ElevationDemo extends StatefulWidget {
  const _ElevationDemo();

  @override
  State<_ElevationDemo> createState() => _ElevationDemoState();
}

class _ElevationDemoState extends State<_ElevationDemo> {
  var _tonal = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Tonal surface tint'),
            Switch(value: _tonal, onChanged: (v) => setState(() => _tonal = v)),
          ],
        ),
        const FwGap(FwSpace.s2),
        FwWrap(
          gap: FwSpace.s3,
          runGap: FwSpace.s3,
          children: [
            for (var level = 0; level <= 5; level++)
              Container(
                width: 96,
                height: 72,
                alignment: Alignment.center,
                decoration: const FwElevation()
                    .decoration(context, level, tonal: _tonal)
                    .copyWith(
                      borderRadius: BorderRadius.circular(
                        theme.radii.of(FwRadius.md),
                      ),
                    ),
                child: Text(
                  'L$level',
                  style: typeScale.resolve(FwTextRole.label, context),
                ),
              ),
          ],
        ),
        const FwGap(FwSpace.s2),
        Text(
          'M3 defaults: card 1 · dialog 3 · sheet 1 · FAB 3 · menu 3 · '
          'toast 3 · drawer 1. Every surface takes elevation + tonal props.',
          style: typeScale.resolve(FwTextRole.caption, context),
        ),
      ],
    );
  }
}

/// Density switcher: the same controls at compact / comfortable / spacious.
///
/// P3.2 — FwDensityScope overrides density per subtree; touch targets stay
/// ≥ 48px in every mode (a repository test enforces the floor).
Widget densityBoard() => Builder(
  builder: (context) {
    return const _DensityDemo();
  },
);

class _DensityDemo extends StatefulWidget {
  const _DensityDemo();

  @override
  State<_DensityDemo> createState() => _DensityDemoState();
}

class _DensityDemoState extends State<_DensityDemo> {
  var _density = FwDensity.comfortable;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: theme.spaceScale.of(FwSpace.s2, context),
          runSpacing: theme.spaceScale.of(FwSpace.s2, context),
          children: [
            for (final d in FwDensity.values)
              ChoiceChip(
                label: Text(d.name),
                selected: _density == d,
                onSelected: (_) => setState(() => _density = d),
              ),
          ],
        ),
        const FwGap(FwSpace.s3),
        FwDensityScope(
          density: _density,
          child: Builder(
            builder: (context) {
              final gapPx = context.fwTheme.spaceScale
                  .resolveAlias(FwSpaceAlias.controlBlock, context)
                  .toStringAsFixed(1);
              return FwVStack(
                gap: FwSpace.s3,
                children: [
                  const FwButton(label: 'Save', onPressed: null),
                  const FwChip(label: 'Filter chip'),
                  Text(
                    'controlBlock → ${gapPx}px '
                    '(×${FwMetrics.of(context).density.gapScale}) · '
                    'touch target ≥ 48px in all modes',
                    style: typeScale.resolve(FwTextRole.caption, context),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One-change-at-a-time playground (P3.4).
///
/// Hierarchy comes from four primitives — size, weight, color, spacing.
/// Emphasize with exactly one: three CTAs that are all bold + accent +
/// large are flat, not hierarchical.
Widget hierarchyPlaygroundBoard() => Builder(
  builder: (context) {
    return const _PlaygroundDemo();
  },
);

enum _Emphasis { none, size, weight, color, spacing }

class _PlaygroundDemo extends StatefulWidget {
  const _PlaygroundDemo();

  @override
  State<_PlaygroundDemo> createState() => _PlaygroundDemoState();
}

class _PlaygroundDemoState extends State<_PlaygroundDemo> {
  var _emphasis = _Emphasis.none;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    final colors = theme.colors;

    TextStyle titleStyle() {
      final base = typeScale.resolve(FwTextRole.h4, context);
      return switch (_emphasis) {
        _Emphasis.none => base,
        _Emphasis.size => typeScale.resolve(FwTextRole.h2, context),
        _Emphasis.weight => base.copyWith(fontWeight: FontWeight.w700),
        _Emphasis.color => base.copyWith(color: colors.of(FwColorRole.primary)),
        _Emphasis.spacing => base,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: theme.spaceScale.of(FwSpace.s2, context),
          runSpacing: theme.spaceScale.of(FwSpace.s2, context),
          children: [
            for (final e in _Emphasis.values)
              ChoiceChip(
                label: Text(e.name),
                selected: _emphasis == e,
                onSelected: (_) => setState(() => _emphasis = e),
              ),
          ],
        ),
        FwGap(_emphasis == _Emphasis.spacing ? FwSpace.s8 : FwSpace.s3),
        Text('Quarterly report', style: titleStyle()),
        const FwGap(FwSpace.s2),
        Text(
          'Revenue grew 12% against a flat market. The body never changes — '
          'only one primitive moves at a time, so the eye knows what matters.',
          style: typeScale.resolve(FwTextRole.body, context),
        ),
        const FwGap(FwSpace.s2),
        Text(
          'Size, weight, color, spacing — pick one per priority level. '
          'Combining all four on one element flattens the hierarchy.',
          style: typeScale.resolve(FwTextRole.caption, context),
        ),
      ],
    );
  }
}
