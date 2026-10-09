import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// O05 — Tooltip preferring the native implementation.
///
/// Hover, focus, and long-press triggers plus keyboard discoverability come
/// from [Tooltip] itself. This facade exists to document the contract:
///
/// * Essential instructions are never tooltip-only — tooltips supplement,
///   they don't carry required information.
/// * [excludeFromSemantics]: when the child already exposes the message
///   (e.g. an [FwIconButton] tooltip), set this to true to avoid
///   duplicating the announcement. The default (false) announces the
///   message once.
/// * [richMessage] is only for content that stays safe when read linearly
///   by a screen reader; prefer plain [message].
class FwTooltip extends StatelessWidget {
  const FwTooltip({
    super.key,
    required this.message,
    required this.child,
    this.richMessage,
    this.waitDuration,
    this.showDuration,
    this.preferBelow,
    this.excludeFromSemantics = false,
    this.textStyle,
  });

  final String message;
  final Widget child;

  /// Rich content, only when safe for linear screen-reader reading.
  final InlineSpan? richMessage;
  final Duration? waitDuration;
  final Duration? showDuration;
  final bool? preferBelow;

  /// Set when the child already announces [message].
  final bool excludeFromSemantics;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Tooltip(
      message: message,
      richMessage: richMessage,
      waitDuration: waitDuration,
      showDuration: showDuration,
      preferBelow: preferBelow,
      excludeFromSemantics: excludeFromSemantics ? true : null,
      textStyle:
          textStyle ?? theme.typeScale.resolve(FwTextRole.bodySm, context),
      decoration: BoxDecoration(
        color: theme.colors.of(FwColorRole.inverseSurface),
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
      ),
      child: child,
    );
  }
}
