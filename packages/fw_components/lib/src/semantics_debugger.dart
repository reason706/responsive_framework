/// Dev-only semantics overlay for the gallery (utils backlog).
library;

import 'package:flutter/widgets.dart';

/// Dev-only wrapper that visualizes the semantics tree as an overlay.
///
/// Wraps [child] in the framework's [SemanticsDebugger], which paints every
/// semantics node's bounds with its label and flags, and ensures semantics
/// are enabled. This is a development aid for the gallery and widget tests:
/// do not ship it in production UI.
///
/// Note: the framework overlay paints from the view's [PipelineOwner], so it
/// visualizes the whole view's semantics tree, not just [child]'s subtree.
/// In the gallery, wrap a single demo section to keep the overlay readable.
///
/// Toggle with [enabled] (e.g. from a gallery switch) without restructuring
/// the tree.
///
/// Example:
/// ```dart
/// FwSemanticsDebugger(
///   enabled: showSemantics,
///   child: const FwButton(label: 'Pay', onPressed: _pay),
/// )
/// ```
class FwSemanticsDebugger extends StatelessWidget {
  const FwSemanticsDebugger({
    super.key,
    required this.child,
    this.enabled = true,
    this.labelStyle,
  });

  /// The widget whose semantics should be inspected.
  final Widget child;

  /// When false, renders [child] unchanged.
  final bool enabled;

  /// Text style for the overlay labels. Defaults to the framework's
  /// (10px black); pass an explicit style to theme it.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return SemanticsDebugger(
      labelStyle: labelStyle ?? const TextStyle(fontSize: 10, height: 0.8),
      child: child,
    );
  }
}
