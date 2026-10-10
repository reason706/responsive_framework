import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// Named overlay layers.
///
/// Flutter has no numeric z-order like CSS; these tokens document and
/// enforce the stacking contract for [OverlayEntry] insertion order,
/// semantics sort keys, and the gallery's layer diagrams. Higher layers
/// render above lower ones; two entries on the same layer must not overlap
/// in a way that depends on insertion order.
enum FwZIndex { base, raised, overlay, modal, toast, tooltip }

/// Theme-resolvable z-index table.
///
/// Defaults come from `tokens.yaml` (`z-index.*`); override per theme when
/// a product needs a different stacking contract (e.g. toasts below a
/// persistent player).
@immutable
class FwZIndices {
  const FwZIndices({
    this.base = FwTokenValues.zIndexBase,
    this.raised = FwTokenValues.zIndexRaised,
    this.overlay = FwTokenValues.zIndexOverlay,
    this.modal = FwTokenValues.zIndexModal,
    this.toast = FwTokenValues.zIndexToast,
    this.tooltip = FwTokenValues.zIndexTooltip,
  });

  /// Default document layer.
  final double base;

  /// Raised content: sticky headers, elevated cards.
  final double raised;

  /// Overlays: popovers, dropdowns, tooltips anchored to content.
  final double overlay;

  /// Modal layer: dialogs, sheets, drawers.
  final double modal;

  /// Transient notifications above modals.
  final double toast;

  /// Topmost: tooltips and the semantics debugger overlay.
  final double tooltip;

  /// Resolves a named layer to its ordering value.
  double of(FwZIndex layer) => switch (layer) {
    FwZIndex.base => base,
    FwZIndex.raised => raised,
    FwZIndex.overlay => overlay,
    FwZIndex.modal => modal,
    FwZIndex.toast => toast,
    FwZIndex.tooltip => tooltip,
  };

  FwZIndices copyWith({
    double? base,
    double? raised,
    double? overlay,
    double? modal,
    double? toast,
    double? tooltip,
  }) => FwZIndices(
    base: base ?? this.base,
    raised: raised ?? this.raised,
    overlay: overlay ?? this.overlay,
    modal: modal ?? this.modal,
    toast: toast ?? this.toast,
    tooltip: tooltip ?? this.tooltip,
  );
}
