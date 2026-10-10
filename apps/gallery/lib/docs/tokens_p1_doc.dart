import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

/// P1 (improvement-plan-2) token boards: the extended spacing scale and the
/// new token families (icon size, z-index, opacity, radius classes).
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired into main.dart):
///
/// ```dart
/// import 'docs/tokens_p1_doc.dart';
/// // inside tokenBoards() in catalog.dart:
/// board('Spacing scale', spacingScaleBoard()),
/// board('Token families (P1)', tokenFamiliesBoard()),
/// ```

/// Renders every [FwSpace] token as a labeled bar plus the micro aliases.
Widget spacingScaleBoard() => Builder(
  builder: (context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    final label = typeScale.resolve(FwTextRole.caption, context);
    Widget row(String name, double px) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$name · ${px.toStringAsFixed(0)}px', style: label),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: px,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colors.scheme.primary,
                  borderRadius: BorderRadius.circular(
                    theme.radii.of(FwRadius.xs),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBar = (constraints.maxWidth - 128).clamp(0.0, 160.0);
        final scale = context.fwTheme.spaceScale;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final token in FwSpace.values)
              Builder(
                builder: (context) {
                  final px = FwSpaceRef(token).resolve(context);
                  return row(token.name, px.clamp(0.0, maxBar));
                },
              ),
            const SizedBox(height: 8),
            Text(
              'Micro aliases (fixed px, density-scaled): '
              'iconGap ${scale.resolveAlias(FwSpaceAlias.iconGap, context).toStringAsFixed(1)}px · '
              'hairlineGap ${scale.resolveAlias(FwSpaceAlias.hairlineGap, context).toStringAsFixed(1)}px',
              style: label,
            ),
          ],
        );
      },
    );
  },
);

/// Renders the P1.2 token families: icon sizes, z-index layers, opacity
/// levels, and per-class radii.
Widget tokenFamiliesBoard() => Builder(
  builder: (context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    final h4 = typeScale.resolve(FwTextRole.h4, context);
    final caption = typeScale.resolve(FwTextRole.caption, context);
    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: h4),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section(
          'Icon sizes (fixed px — root- and density-free)',
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final size in FwIconSize.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: theme.iconSizes.of(size),
                      color: theme.colors.scheme.primary,
                    ),
                    Text(size.name, style: caption),
                  ],
                ),
            ],
          ),
        ),
        section(
          'Z-index layers (overlay ordering contract)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final layer in FwZIndex.values)
                Text(
                  '${layer.name}: ${theme.zIndices.of(layer).toStringAsFixed(0)}',
                  style: caption,
                ),
            ],
          ),
        ),
        section(
          'Opacity levels',
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final level in FwOpacity.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: theme.opacities.of(level),
                      child: Container(
                        width: 40,
                        height: 40,
                        color: theme.colors.scheme.primary,
                      ),
                    ),
                    Text(level.name, style: caption),
                  ],
                ),
            ],
          ),
        ),
        section(
          'Radius classes (research: buttons/inputs smaller, cards/modals larger)',
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final klass in FwRadiusClass.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colors.scheme.primaryContainer,
                        borderRadius: theme.radiusClasses.borderRadius(klass),
                      ),
                    ),
                    Text(klass.name, style: caption),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  },
);
