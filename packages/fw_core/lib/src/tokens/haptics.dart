import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Haptic feedback tokens: semantic signals mapped to platform haptics.
///
/// Components trigger [FwHaptics] signals (tap/confirm/error/selection)
/// instead of calling [HapticFeedback] directly, so haptics stay consistent
/// and testable. The signal implementation is injectable and mockable;
/// [FwNoopHaptics] silences the channel entirely.
///
/// System accessibility is respected: signals are skipped when
/// [MediaQuery.accessibleNavigation] is true, and the whole channel can be
/// disabled per theme for users who request no haptics.
@immutable
class FwHaptics {
  const FwHaptics({
    this.enabled = true,
    this.signals = const FwSystemHaptics(),
  });

  /// Master switch for the haptic channel. Defaults to on.
  final bool enabled;

  /// The platform (or fake) signal implementation.
  final FwHapticSignals signals;

  void _fire(BuildContext context, void Function() signal) {
    if (!enabled) return;
    if (MediaQuery.accessibleNavigationOf(context)) return;
    signal();
  }

  /// Light confirmation of a tap.
  void tap(BuildContext context) => _fire(context, signals.tap);

  /// A completed confirmation (e.g. hold-to-confirm finished).
  void confirm(BuildContext context) => _fire(context, signals.confirm);

  /// An error or destructive outcome.
  void error(BuildContext context) => _fire(context, signals.error);

  /// A selection change (toggles, segmented controls, pickers).
  void selection(BuildContext context) => _fire(context, signals.selection);

  FwHaptics copyWith({bool? enabled, FwHapticSignals? signals}) => FwHaptics(
    enabled: enabled ?? this.enabled,
    signals: signals ?? this.signals,
  );
}

/// Injectable haptic signal implementation. Subclass in tests to record
/// calls instead of vibrating the device.
abstract class FwHapticSignals {
  const FwHapticSignals();

  void tap();
  void confirm();
  void error();
  void selection();
}

/// Default signals backed by [HapticFeedback].
class FwSystemHaptics extends FwHapticSignals {
  const FwSystemHaptics();

  @override
  void tap() => HapticFeedback.lightImpact();

  @override
  void confirm() => HapticFeedback.mediumImpact();

  @override
  void error() => HapticFeedback.heavyImpact();

  @override
  void selection() => HapticFeedback.selectionClick();
}

/// No-op signals: silences the haptic channel (tests, kiosk modes,
///
/// users who disable haptics).
class FwNoopHaptics extends FwHapticSignals {
  const FwNoopHaptics();

  @override
  void tap() {}

  @override
  void confirm() {}

  @override
  void error() {}

  @override
  void selection() {}
}
