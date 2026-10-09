import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

/// The NoNameYet documentation contract, as a gallery template.
///
/// Every component page documents five boards:
/// 1. **Anatomy** — numbered parts of the component with token references.
/// 2. **Properties** — the variants x states matrix (live widgets).
/// 3. **Layout & spacing** — padding, gaps, alignment, and minimums.
/// 4. **Usage** — do / don't rules.
/// 5. **Accessibility** — semantics, keyboard, and text-scaling notes.
///
/// Numbers in the anatomy list map to the demo in Properties; read them
/// together like an annotated diagram.
///
/// Atomic tiers organize the catalog: Foundations -> Atoms -> Molecules ->
/// Organisms -> Patterns/Templates. A tier groups components by composition
/// level, so composition rules stay explicit.

/// One numbered part in an anatomy board.
@immutable
class AnatomyPart {
  const AnatomyPart(this.label, this.detail);

  /// Short part name, e.g. "Label".
  final String label;

  /// What it is and which token drives it, e.g. "label role, s2 icon gap".
  final String detail;
}

/// One row in the layout & spacing board.
@immutable
class LayoutSpec {
  const LayoutSpec(this.label, this.value);

  final String label;
  final String value;
}

/// A tier section header: tier name, what belongs in it, and the docs.
class TierSection extends StatelessWidget {
  const TierSection({
    super.key,
    required this.tier,
    required this.description,
    required this.children,
  });

  final String tier;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final typeScale = context.fwTheme.typeScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        FwDivider(
          label: Text(
            tier.toUpperCase(),
            style: typeScale.resolve(FwTextRole.label, context),
          ),
        ),
        const SizedBox(height: 4),
        Text(description, style: typeScale.resolve(FwTextRole.bodySm, context)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

/// Per-component documentation page implementing the five-board contract.
class ComponentDoc extends StatelessWidget {
  const ComponentDoc({
    super.key,
    required this.id,
    required this.name,
    required this.tier,
    required this.summary,
    this.notFor,
    required this.anatomy,
    required this.properties,
    required this.layoutSpecs,
    required this.dos,
    required this.donts,
    required this.a11y,
  });

  /// Catalog ID, e.g. "A01".
  final String id;

  /// Component name, e.g. "Button".
  final String name;

  /// Atomic tier: Foundations, Atoms, Molecules, Organisms, Patterns.
  final String tier;

  /// What it is and when to use it.
  final String summary;

  /// When *not* to use it.
  final String? notFor;

  /// Numbered anatomy parts; numbers map to [properties].
  final List<AnatomyPart> anatomy;

  /// The variants x states matrix (live widgets).
  final Widget properties;

  /// Padding, gaps, alignment, and minimums.
  final List<LayoutSpec> layoutSpecs;

  final List<String> dos;
  final List<String> donts;

  /// Semantics, keyboard, and text-scaling notes.
  final List<String> a11y;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    Widget boardTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: typeScale.resolve(FwTextRole.h4, context)),
    );

    Widget bullet(String text, {IconData? icon, Color? iconColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: typeScale.resolve(FwTextRole.bodySm, context),
            ),
          ),
        ],
      ),
    );

    return FwCard(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Tag(id),
              Text(name, style: typeScale.resolve(FwTextRole.h3, context)),
              _Tag(tier),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary, style: typeScale.resolve(FwTextRole.body, context)),
          if (notFor != null) ...[
            const SizedBox(height: 4),
            Text(
              'Not for: $notFor.',
              style: typeScale.resolve(FwTextRole.bodySm, context),
            ),
          ],
          const SizedBox(height: 16),
          boardTitle('Anatomy'),
          Column(
            children: [
              for (var i = 0; i < anatomy.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Number(i + 1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${anatomy[i].label} — ',
                                style: typeScale.resolve(
                                  FwTextRole.label,
                                  context,
                                ),
                              ),
                              TextSpan(
                                text: anatomy[i].detail,
                                style: typeScale.resolve(
                                  FwTextRole.bodySm,
                                  context,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          boardTitle('Properties — variants × states'),
          properties,
          const SizedBox(height: 16),
          boardTitle('Layout & spacing'),
          Table(
            columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
            children: [
              for (final spec in layoutSpecs)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        spec.label,
                        style: typeScale.resolve(FwTextRole.label, context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        spec.value,
                        style: typeScale.resolve(FwTextRole.bodySm, context),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          boardTitle('Usage'),
          Text(
            'Do',
            style: typeScale
                .resolve(FwTextRole.label, context)
                .copyWith(color: theme.colors.of(FwColorRole.success)),
          ),
          for (final d in dos)
            bullet(
              d,
              icon: Icons.check_circle,
              iconColor: theme.colors.of(FwColorRole.success),
            ),
          const SizedBox(height: 8),
          Text(
            "Don't",
            style: typeScale
                .resolve(FwTextRole.label, context)
                .copyWith(color: theme.colors.of(FwColorRole.error)),
          ),
          for (final d in donts)
            bullet(
              d,
              icon: Icons.cancel,
              iconColor: theme.colors.of(FwColorRole.error),
            ),
          const SizedBox(height: 16),
          boardTitle('Accessibility'),
          for (final note in a11y) bullet(note, icon: Icons.accessibility),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colors.of(FwColorRole.secondaryContainer),
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
      ),
      child: Text(
        text,
        style: theme.typeScale
            .resolve(FwTextRole.label, context)
            .copyWith(color: theme.colors.of(FwColorRole.onSecondaryContainer)),
      ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number(this.value);

  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colors.of(FwColorRole.primary),
      ),
      child: Text(
        '$value',
        style: theme.typeScale
            .resolve(FwTextRole.label, context)
            .copyWith(color: theme.colors.of(FwColorRole.onPrimary)),
      ),
    );
  }
}
