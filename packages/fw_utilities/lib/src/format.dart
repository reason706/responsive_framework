/// Pure-Dart number/currency/date formatting (utils backlog).
///
/// Dependency-free by design: group separators, decimal separators, currency
/// symbols, and month names are explicit parameters rather than locale
/// lookups, so `fw_utilities` stays tree-shakable with zero dependencies.
/// For full CLDR locale data (locale-aware month names, currency placement
/// rules, non-Latin digits), use `package:intl` instead — these helpers
/// cover the common explicit-format cases without it.
library;

/// Decimal number formatting with digit grouping.
///
/// ```dart
/// const FwNumberFormat().format(1234567.891); // '1,234,567.89'
/// const FwNumberFormat(decimalPlaces: 0, decimalSeparator: ',').format(12.5);
/// // '13' (rounded; separator unused without fraction digits)
/// ```
class FwNumberFormat {
  const FwNumberFormat({
    this.decimalPlaces = 2,
    this.groupSeparator = ',',
    this.decimalSeparator = '.',
    this.groupSize = 3,
    this.grouping = true,
  }) : assert(decimalPlaces >= 0, 'decimalPlaces cannot be negative'),
       assert(groupSize > 0, 'groupSize must be positive');

  /// Fraction digits; the value is rounded (half away from zero, via
  /// [double.toStringAsFixed]).
  final int decimalPlaces;

  /// Thousands separator, e.g. `','` (en) or `'.'` (de).
  final String groupSeparator;

  /// Decimal separator, e.g. `'.'` (en) or `','` (de).
  final String decimalSeparator;

  /// Digits per group; 3 for en/de, 2 for the Indian system after the first
  /// group — pass 2 with [grouping] for `1,00,000`-style output.
  final int groupSize;

  /// When false, no grouping is applied.
  final bool grouping;

  /// Formats [value], e.g. `1234567.891` → `'1,234,567.89'`.
  String format(num value) {
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value.isNegative ? '-∞' : '∞';
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(decimalPlaces);
    final dot = fixed.indexOf('.');
    var intPart = dot < 0 ? fixed : fixed.substring(0, dot);
    final fracPart = dot < 0 ? '' : fixed.substring(dot + 1);
    if (grouping && intPart.length > groupSize) {
      final buf = StringBuffer();
      var count = 0;
      for (var i = intPart.length - 1; i >= 0; i--) {
        buf.write(intPart[i]);
        count++;
        if (count == groupSize && i != 0) {
          buf.write(groupSeparator);
          count = 0;
        }
      }
      intPart = buf.toString().split('').reversed.join();
    }
    final fraction = decimalPlaces > 0 ? '$decimalSeparator$fracPart' : '';
    return '${negative ? '-' : ''}$intPart$fraction';
  }
}

/// Currency formatting built on [FwNumberFormat].
///
/// ```dart
/// const FwCurrencyFormat(symbol: '\$').format(1234.5); // '$1,234.50'
/// const FwCurrencyFormat(symbol: '€', symbolAfter: true).format(1234.5);
/// // '1,234.50 €'
/// ```
class FwCurrencyFormat {
  const FwCurrencyFormat({
    this.symbol = '\$',
    this.symbolAfter = false,
    this.decimalPlaces = 2,
    this.groupSeparator = ',',
    this.decimalSeparator = '.',
    this.groupSize = 3,
    this.grouping = true,
  }) : assert(decimalPlaces >= 0, 'decimalPlaces cannot be negative');

  /// Currency symbol, e.g. `'\$'`, `'€'`, `'¥'`. For ISO codes, pass
  /// `'USD'` with [symbolAfter] for `'1,234.50 USD'`-style output.
  final String symbol;

  /// When true, the symbol follows the amount (`'1,234.50 €'`).
  final bool symbolAfter;

  final int decimalPlaces;
  final String groupSeparator;
  final String decimalSeparator;
  final int groupSize;
  final bool grouping;

  /// Formats [value], e.g. `1234.5` → `'$1,234.50'`.
  String format(num value) {
    final number = FwNumberFormat(
      decimalPlaces: decimalPlaces,
      groupSeparator: groupSeparator,
      decimalSeparator: decimalSeparator,
      groupSize: groupSize,
      grouping: grouping,
    ).format(value.abs());
    final body = symbolAfter ? '$number $symbol' : '$symbol$number';
    return value < 0 ? '-$body' : body;
  }
}

/// Pattern date formatting without `package:intl`.
///
/// Tokens (matched longest-first): `yyyy` `yy` `MMMM` `MMM` `MM` `M` `dd`
/// `d` `HH` `H` `mm` `ss`. Month names are English; for localized names use
/// `package:intl`. Any other characters are copied verbatim (patterns cannot
/// escape token letters — avoid `M`/`d`/`y` in literal text).
///
/// ```dart
/// const FwDateFormat('dd MMM yyyy').format(DateTime(2026, 10, 10));
/// // '10 Oct 2026'
/// ```
class FwDateFormat {
  const FwDateFormat(this.pattern);

  /// ISO-like `2026-10-10`.
  const FwDateFormat.yMd() : pattern = 'yyyy-MM-dd';

  /// `10/10/2026`.
  const FwDateFormat.dMy() : pattern = 'dd/MM/yyyy';

  /// `14:30`.
  const FwDateFormat.hm() : pattern = 'HH:mm';

  /// The pattern; see the class docs for tokens.
  final String pattern;

  static const _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _monthsLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _two(int v) => v.toString().padLeft(2, '0');

  /// Formats [dt] per [pattern].
  String format(DateTime dt) {
    // Longest-first so 'MMMM' wins over 'MMM' over 'MM' over 'M'.
    const tokens = [
      'yyyy',
      'MMMM',
      'MMM',
      'MM',
      'dd',
      'HH',
      'mm',
      'ss',
      'yy',
      'M',
      'd',
      'H',
    ];
    final buf = StringBuffer();
    var i = 0;
    while (i < pattern.length) {
      String? match;
      for (final token in tokens) {
        if (pattern.startsWith(token, i)) {
          match = token;
          break;
        }
      }
      if (match == null) {
        buf.write(pattern[i]);
        i++;
        continue;
      }
      switch (match) {
        case 'yyyy':
          buf.write(dt.year.toString().padLeft(4, '0'));
        case 'yy':
          buf.write(_two(dt.year % 100));
        case 'MMMM':
          buf.write(_monthsLong[dt.month - 1]);
        case 'MMM':
          buf.write(_monthsShort[dt.month - 1]);
        case 'MM':
          buf.write(_two(dt.month));
        case 'M':
          buf.write(dt.month);
        case 'dd':
          buf.write(_two(dt.day));
        case 'd':
          buf.write(dt.day);
        case 'HH':
          buf.write(_two(dt.hour));
        case 'H':
          buf.write(dt.hour);
        case 'mm':
          buf.write(_two(dt.minute));
        case 'ss':
          buf.write(_two(dt.second));
      }
      i += match.length;
    }
    return buf.toString();
  }
}
