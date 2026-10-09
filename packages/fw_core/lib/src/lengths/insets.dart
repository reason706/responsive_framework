import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'length.dart';

/// Directional padding expressed in typed lengths.
///
/// Null edges resolve to zero. All lengths are validated at construction;
/// negative padding is invalid. Resolve with [resolve] to get an
/// [EdgeInsetsDirectional] in logical pixels.
///
/// Start/end edges follow the ambient [Directionality], so insets are
/// RTL-correct without caller branches.
@immutable
class FwInsets {
  factory FwInsets.all(FwLength value) =>
      FwInsets._(start: value, end: value, top: value, bottom: value);

  factory FwInsets.symmetric({FwLength? vertical, FwLength? horizontal}) =>
      FwInsets._(
        start: horizontal,
        end: horizontal,
        top: vertical,
        bottom: vertical,
      );

  factory FwInsets.directional({
    FwLength? start,
    FwLength? end,
    FwLength? top,
    FwLength? bottom,
  }) => FwInsets._(start: start, end: end, top: top, bottom: bottom);

  factory FwInsets.only({
    FwLength? start,
    FwLength? end,
    FwLength? top,
    FwLength? bottom,
    FwLength? left,
    FwLength? right,
  }) {
    if ((start != null || end != null) && (left != null || right != null)) {
      throw ArgumentError(
        'Use either directional start/end or physical left/right, not both.',
      );
    }
    return FwInsets._(
      start: start ?? left,
      end: end ?? right,
      top: top,
      bottom: bottom,
    );
  }

  /// Convenience for a single named spacing token on all edges.
  factory FwInsets.token(FwSpace token) => FwInsets.all(FwSpaceRef(token));

  /// Zero insets.
  factory FwInsets.zero() => const FwInsets._();

  const FwInsets._({this.start, this.end, this.top, this.bottom});

  final FwLength? start;
  final FwLength? end;
  final FwLength? top;
  final FwLength? bottom;

  /// Resolves every edge to logical pixels.
  EdgeInsetsDirectional resolve(BuildContext context) =>
      EdgeInsetsDirectional.only(
        start: start?.resolve(context) ?? 0,
        end: end?.resolve(context) ?? 0,
        top: top?.resolve(context) ?? 0,
        bottom: bottom?.resolve(context) ?? 0,
      );

  /// Context-free resolution for tooling and tests.
  EdgeInsetsDirectional resolveRaw({
    required double rootSize,
    double? explicitWidth,
    double? emSize,
  }) {
    double edge(FwLength? length) =>
        length?.resolveRaw(
          rootSize: rootSize,
          explicitWidth: explicitWidth,
          emSize: emSize,
        ) ??
        0;
    return EdgeInsetsDirectional.only(
      start: edge(start),
      end: edge(end),
      top: edge(top),
      bottom: edge(bottom),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwInsets &&
          start == other.start &&
          end == other.end &&
          top == other.top &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(start, end, top, bottom);

  @override
  String toString() =>
      'FwInsets(start: $start, end: $end, top: $top, bottom: $bottom)';
}
