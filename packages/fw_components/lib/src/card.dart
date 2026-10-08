import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Noninteractive surface. Interactive card behavior is deliberately separate.
class FwCard extends StatelessWidget {
  const FwCard({
    super.key,
    required this.child,
    this.padding = FwSpace.s4,
    this.radius = FwRadius.lg,
  });

  final Widget child;
  final FwSpace padding;
  final FwRadius radius;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Material(
      color: theme.colors.scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radii.of(radius)),
        side: BorderSide(color: theme.colors.scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.of(padding)),
        child: DefaultTextStyle(
          style: theme.typography.bodyMedium!.copyWith(
            color: theme.colors.scheme.onSurface,
          ),
          child: child,
        ),
      ),
    );
  }
}
