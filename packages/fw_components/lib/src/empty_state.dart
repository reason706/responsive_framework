import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Empty state with illustration slots.
///
/// A centered composition for "nothing here yet": an [illustration] slot
/// (icon, emoji-free glyph, or custom art), a [title], an optional
/// [description], and an optional [action] (usually a button). Keeps empty
/// screens consistent without dictating the artwork.
class FwEmptyState extends StatelessWidget {
  const FwEmptyState({
    super.key,
    this.illustration,
    this.icon,
    required this.title,
    this.description,
    this.action,
  }) : assert(
         illustration == null || icon == null,
         'Pass either illustration or icon, not both.',
       );

  /// Custom artwork slot. Takes precedence over [icon].
  final Widget? illustration;

  /// Simple glyph shown in a tinted circle when [illustration] is null.
  final IconData? icon;

  final String title;
  final String? description;

  /// Call-to-action, e.g. an [FwButton].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;

    Widget? art;
    if (illustration != null) {
      art = illustration!;
    } else if (icon != null) {
      art = Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.of(FwColorRole.surfaceContainerHighest),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 36, color: colors.of(FwColorRole.textMuted)),
      );
    }

    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s6, context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (art != null) ...[
              art,
              SizedBox(height: theme.spaceScale.of(FwSpace.s4, context)),
            ],
            Text(
              title,
              style: theme.typeScale.resolve(FwTextRole.h6, context),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
              Text(
                description!,
                style: theme.typeScale
                    .resolve(FwTextRole.body, context)
                    .copyWith(color: colors.of(FwColorRole.textMuted)),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: theme.spaceScale.of(FwSpace.s4, context)),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
