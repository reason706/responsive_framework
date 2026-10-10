import 'package:flutter/foundation.dart';

/// Keyboard focus-ring token.
///
/// Focus rings follow `:focus-visible` semantics: shown for keyboard
/// focus, not for pointer taps. [width] is the ring stroke and [offset]
/// the gap between the component edge and the ring. The ring color comes
/// from `FwColorRole.focusRing`; high-contrast presets must keep it at
/// >= 3:1 against adjacent colors.
@immutable
class FwFocusRing {
  const FwFocusRing({this.width = 2, this.offset = 2})
    : assert(width > 0, 'focus ring width must be positive'),
      assert(offset >= 0, 'focus ring offset cannot be negative');

  final double width;
  final double offset;

  FwFocusRing copyWith({double? width, double? offset}) =>
      FwFocusRing(width: width ?? this.width, offset: offset ?? this.offset);

  FwFocusRing lerp(FwFocusRing other, double t) => FwFocusRing(
    width: width + (other.width - width) * t,
    offset: offset + (other.offset - offset) * t,
  );

  @override
  bool operator ==(Object other) =>
      other is FwFocusRing && width == other.width && offset == other.offset;

  @override
  int get hashCode => Object.hash(width, offset);
}
