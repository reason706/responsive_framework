import 'package:flutter_test/flutter_test.dart';
import 'package:fw_utilities/fw_utilities.dart';

void main() {
  group('E6 FwDebouncer', () {
    test('collapses rapid calls into one', () async {
      final debouncer = FwDebouncer(delay: const Duration(milliseconds: 50));
      var calls = 0;
      debouncer.run(() => calls++);
      debouncer.run(() => calls++);
      debouncer.run(() => calls++);
      expect(calls, 0);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(calls, 1);
      debouncer.dispose();
    });

    test('cancel drops the pending action', () async {
      final debouncer = FwDebouncer(delay: const Duration(milliseconds: 30));
      var calls = 0;
      debouncer.run(() => calls++);
      debouncer.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(calls, 0);
      debouncer.dispose();
    });

    test('isPending reflects a scheduled action', () {
      final debouncer = FwDebouncer(delay: const Duration(milliseconds: 50));
      expect(debouncer.isPending, isFalse);
      debouncer.run(() {});
      expect(debouncer.isPending, isTrue);
      debouncer.cancel();
      expect(debouncer.isPending, isFalse);
      debouncer.dispose();
    });
  });

  group('E6 FwThrottler', () {
    test('first call fires immediately, trailing call fires once', () async {
      final throttler = FwThrottler(interval: const Duration(milliseconds: 50));
      var calls = 0;
      throttler.run(() => calls++);
      expect(calls, 1);
      throttler.run(() => calls++);
      throttler.run(() => calls++);
      expect(calls, 1);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(calls, 2);
      throttler.dispose();
    });
  });

  group('E6 formatters', () {
    testWidgets('digitsOnly strips non-digits', (tester) async {
      final formatter = FwFormatters.digitsOnly;
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: 'a1b2c3');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123');
    });

    testWidgets('upperCase forces uppercase', (tester) async {
      final formatter = FwFormatters.upperCase;
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: 'abc');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'ABC');
    });
  });
}
