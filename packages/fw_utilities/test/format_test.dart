import 'package:flutter_test/flutter_test.dart';
import 'package:fw_utilities/fw_utilities.dart';

void main() {
  group('FwNumberFormat', () {
    test('groups thousands by default', () {
      expect(const FwNumberFormat().format(1234567.891), '1,234,567.89');
    });

    test('respects decimalPlaces', () {
      expect(const FwNumberFormat(decimalPlaces: 0).format(12.5), '13');
      expect(const FwNumberFormat(decimalPlaces: 3).format(1.2), '1.200');
    });

    test('handles negatives', () {
      expect(const FwNumberFormat().format(-9876.5), '-9,876.50');
    });

    test('small values are not grouped', () {
      expect(const FwNumberFormat().format(999.99), '999.99');
    });

    test('custom separators (de style)', () {
      const f = FwNumberFormat(groupSeparator: '.', decimalSeparator: ',');
      expect(f.format(1234567.89), '1.234.567,89');
    });

    test('grouping can be disabled', () {
      const f = FwNumberFormat(grouping: false);
      expect(f.format(1234567.89), '1234567.89');
    });

    test('zero and integers', () {
      expect(const FwNumberFormat().format(0), '0.00');
      expect(const FwNumberFormat().format(42), '42.00');
    });

    test('NaN and infinity', () {
      expect(const FwNumberFormat().format(double.nan), 'NaN');
      expect(const FwNumberFormat().format(double.infinity), '∞');
      expect(const FwNumberFormat().format(double.negativeInfinity), '-∞');
    });
  });

  group('FwCurrencyFormat', () {
    test('default dollar format', () {
      expect(const FwCurrencyFormat().format(1234.5), r'$1,234.50');
    });

    test('symbol after amount', () {
      const f = FwCurrencyFormat(symbol: '€', symbolAfter: true);
      expect(f.format(1234.5), '1,234.50 €');
    });

    test('negatives put the sign first', () {
      expect(const FwCurrencyFormat().format(-5), r'-$5.00');
    });

    test('zero decimals (yen style)', () {
      const f = FwCurrencyFormat(symbol: '¥', decimalPlaces: 0);
      expect(f.format(1234.6), '¥1,235');
    });

    test('ISO code style', () {
      const f = FwCurrencyFormat(symbol: 'USD', symbolAfter: true);
      expect(f.format(99.9), '99.90 USD');
    });
  });

  group('FwDateFormat', () {
    final dt = DateTime(2026, 10, 10, 14, 30, 5);

    test('custom pattern', () {
      expect(const FwDateFormat('dd MMM yyyy').format(dt), '10 Oct 2026');
    });

    test('named constructors', () {
      expect(const FwDateFormat.yMd().format(dt), '2026-10-10');
      expect(const FwDateFormat.dMy().format(dt), '10/10/2026');
      expect(const FwDateFormat.hm().format(dt), '14:30');
    });

    test('all tokens', () {
      expect(
        const FwDateFormat('yyyy yy MMMM MMM MM M dd d HH H mm ss').format(dt),
        '2026 26 October Oct 10 10 10 10 14 14 30 05',
      );
    });

    test('literal text passes through', () {
      expect(const FwDateFormat('yyyy/MM/dd').format(dt), '2026/10/10');
    });

    test('single-digit padding', () {
      final early = DateTime(2026, 3, 5, 9, 7, 3);
      expect(
        const FwDateFormat('dd-MM-yyyy HH:mm:ss').format(early),
        '05-03-2026 09:07:03',
      );
    });
  });
}
