import 'package:flutter/material.dart';

import '../metrics/metrics.dart';
import '../theme.dart';

/// Distinguishes "no override" from "override to null" for nullable fields.
///
/// Component styles use this so a caller can clear an inherited nullable
/// value (e.g. remove a default icon) without it being indistinguishable
/// from "not specified".
@immutable
class FwOverride<T> {
  const FwOverride.absent() : _value = null, present = false;

  const FwOverride.value(T? value) : _value = value, present = true;

  final T? _value;
  final bool present;

  /// The overriding value. Only meaningful when [present] is true.
  T? get value => _value;

  /// Resolves against [inherited]: the override wins when present,
  /// otherwise the inherited value is kept (even if the override is an
  /// explicit null).
  T? resolve(T? inherited) => present ? _value : inherited;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwOverride<T> &&
          present == other.present &&
          _value == other._value;

  @override
  int get hashCode => Object.hash(present, _value);

  @override
  String toString() =>
      present ? 'FwOverride.value($_value)' : 'FwOverride.absent()';
}

/// Scoped theme override with property-level precedence.
///
/// Build [theme] from the ambient theme — typically
/// `FwTheme.of(context).copyWith(...)` — so only the fields you pass change
/// and everything else inherits, per the override precedence chain:
///
/// ```text
/// explicit widget property
/// → widget partial style
/// → nearest component-theme scope (this widget)
/// → application component theme
/// → global semantic tokens
/// → documented built-in fallback
/// ```
///
/// The scope propagates the resolved Material adapter
/// ([FwTheme.toThemeData]) to descendants, so native primitives inside a
/// locally dark card or dialog render with the scoped theme instead of the
/// outer one. Root metrics are inherited, never redefined: changing a
/// dialog's color mode must not accidentally redefine `rem` — use an
/// explicit [FwRootScope] for that.
///
/// ```dart
/// Builder(
///   builder: (context) => FwThemeScope(
///     theme: context.fwTheme.copyWith(
///       colors: FwColors(darkScheme),
///     ),
///     child: const InverseCard(),
///   ),
/// )
/// ```
class FwThemeScope extends StatelessWidget {
  const FwThemeScope({super.key, required this.theme, required this.child});

  /// The fully resolved theme for this subtree. Unspecified properties must
  /// already be inherited via `copyWith` on the ambient theme.
  final FwTheme theme;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = Theme.of(context);
    final mapped = theme.toThemeData();
    final extensions = Map<Object, ThemeExtension<dynamic>>.of(
      parent.extensions,
    )..[FwTheme] = theme;
    return Theme(
      data: parent.copyWith(
        colorScheme: mapped.colorScheme,
        textTheme: mapped.textTheme,
        extensions: extensions.values,
      ),
      child: child,
    );
  }
}
