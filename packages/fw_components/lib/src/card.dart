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
      color: theme.colors.of(FwColorRole.surfaceMuted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radii.of(radius)),
        side: BorderSide(color: theme.colors.of(FwColorRole.border)),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spaceScale.of(padding, context)),
        child: DefaultTextStyle(
          style: theme.typeScale.resolve(FwTextRole.body, context),
          child: child,
        ),
      ),
    );
  }
}
