import 'package:flutter/widgets.dart';

/// Explicit typography scope for [FwEm] resolution.
///
/// `FwEm(n)` resolves to `n` times [declaredSize], the *declared* (unscaled)
/// typography size of the current text scope. Using [FwEm] without an
/// enclosing [FwEmScope] is an error, never a silent fallback.
@immutable
class FwEmScope extends InheritedWidget {
  const FwEmScope({super.key, required this.declaredSize, required super.child})
    : assert(declaredSize > 0);
  // Note: `declaredSize > 0` also rejects NaN in debug builds. A non-finite
  // declared size cannot lay out text and is rejected when read.

  /// Declared font size in logical pixels, before the system [TextScaler].
  final double declaredSize;

  /// Returns the nearest scope's declared size, or throws an actionable
  /// error when [FwEm] is used without a typography scope.
  static double declaredSizeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FwEmScope>();
    if (scope == null) {
      throw FlutterError(
        'FwEm used without an FwEmScope. Wrap the subtree in an FwEmScope '
        'declaring the current typography size, or use FwRem for '
        'root-relative sizing instead.',
      );
    }
    return scope.declaredSize;
  }

  /// Returns the nearest scope's declared size, or null when absent.
  static double? maybeDeclaredSizeOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<FwEmScope>();
    return scope?.declaredSize;
  }

  @override
  bool updateShouldNotify(FwEmScope oldWidget) =>
      declaredSize != oldWidget.declaredSize;
}
