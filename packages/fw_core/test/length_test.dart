import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

void main() {
  group('FwPx', () {
    test('resolves to fixed pixels regardless of root', () {
      expect(FwPx(16).resolveRaw(rootSize: 16), 16);
      expect(FwPx(16).resolveRaw(rootSize: 20), 16);
      expect(FwPx(1).resolveRaw(rootSize: 18), 1);
    });

    test('rejects invalid values in release and debug builds', () {
      expect(() => FwPx(-1), throwsArgumentError);
      expect(() => FwPx(double.nan), throwsArgumentError);
      expect(() => FwPx(double.infinity), throwsArgumentError);
      expect(() => FwPx(double.negativeInfinity), throwsArgumentError);
    });

    test('zero is valid', () {
      expect(FwPx(0).resolveRaw(rootSize: 16), 0);
    });
  });

  group('FwRem', () {
    test('scales with root size', () {
      expect(FwRem(1).resolveRaw(rootSize: 16), 16);
      expect(FwRem(1).resolveRaw(rootSize: 18), 18);
      expect(FwRem(1).resolveRaw(rootSize: 20), 20);
    });

    test('fractional rems from the spec table', () {
      expect(FwRem(0.25).resolveRaw(rootSize: 16), 4);
      expect(FwRem(0.25).resolveRaw(rootSize: 18), 4.5);
      expect(FwRem(1.5).resolveRaw(rootSize: 16), 24);
      expect(FwRem(1.25).resolveRaw(rootSize: 16), 20);
    });

    test('rejects invalid values', () {
      expect(() => FwRem(-0.5), throwsArgumentError);
      expect(() => FwRem(double.nan), throwsArgumentError);
      expect(() => FwRem(double.infinity), throwsArgumentError);
    });
  });

  group('FwEm', () {
    test('multiplies the declared typography size', () {
      expect(FwEm(2).resolveRaw(rootSize: 16, emSize: 14), 28);
      expect(FwEm(1).resolveRaw(rootSize: 20, emSize: 14), 14);
    });

    test('requires an em size', () {
      expect(
        () => FwEm(1).resolveRaw(rootSize: 16),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects invalid values', () {
      expect(() => FwEm(-1), throwsArgumentError);
      expect(() => FwEm(double.nan), throwsArgumentError);
    });
  });

  group('FwSpaceRef', () {
    test('resolves token ratios against the root', () {
      expect(FwSpaceRef(FwSpace.s4).resolveRaw(rootSize: 16), 16);
      expect(FwSpaceRef(FwSpace.s4).resolveRaw(rootSize: 18), 18);
      expect(FwSpaceRef(FwSpace.s1).resolveRaw(rootSize: 16), 4);
      expect(FwSpaceRef(FwSpace.s1).resolveRaw(rootSize: 18), 4.5);
      expect(FwSpaceRef(FwSpace.s0).resolveRaw(rootSize: 16), 0);
    });

    test('matches the legacy pixel scale at root 16', () {
      const legacy = FwSpacing();
      for (final token in FwSpace.values) {
        expect(
          FwSpaceRef(token).resolveRaw(rootSize: 16),
          legacy.of(token),
          reason: 'token $token must keep root-16 numeric parity',
        );
      }
    });
  });

  group('FwFluid', () {
    FwFluid heading() => FwFluid(
      min: FwRem(1.75),
      max: FwRem(2.5),
      fromWidth: FwPx(360),
      toWidth: FwPx(1200),
    );

    test('resolves endpoints from the spec example', () {
      // At root 16: 28 at 360, 34 at 780, 40 at 1200.
      expect(heading().resolveRaw(rootSize: 16, explicitWidth: 360), 28);
      expect(heading().resolveRaw(rootSize: 16, explicitWidth: 780), 34);
      expect(heading().resolveRaw(rootSize: 16, explicitWidth: 1200), 40);
    });

    test('scales with root size', () {
      // At root 18: 31.5, 38.25, 45.
      expect(heading().resolveRaw(rootSize: 18, explicitWidth: 360), 31.5);
      expect(heading().resolveRaw(rootSize: 18, explicitWidth: 780), 38.25);
      expect(heading().resolveRaw(rootSize: 18, explicitWidth: 1200), 45);
    });

    test('clamps outside the interval and never grows unbounded', () {
      expect(heading().resolveRaw(rootSize: 16, explicitWidth: 200), 28);
      expect(heading().resolveRaw(rootSize: 16, explicitWidth: 0), 28);
      expect(heading().resolveRaw(rootSize: 16, explicitWidth: 4000), 40);
    });

    test('unknown width resolves to the minimum', () {
      expect(heading().resolveRaw(rootSize: 16), 28);
    });

    test('rejects reversed or equal bounds', () {
      expect(
        () => FwFluid(
          min: FwRem(1),
          max: FwRem(2),
          fromWidth: FwPx(1200),
          toWidth: FwPx(360),
        ),
        throwsArgumentError,
      );
      expect(
        () => FwFluid(
          min: FwRem(1),
          max: FwRem(2),
          fromWidth: FwPx(600),
          toWidth: FwPx(600),
        ),
        throwsArgumentError,
      );
    });

    test('rejects nested fluid endpoints', () {
      expect(
        () => FwFluid(
          min: FwFluid(
            min: FwRem(1),
            max: FwRem(2),
            fromWidth: FwPx(100),
            toWidth: FwPx(200),
          ),
          max: FwRem(2),
          fromWidth: FwPx(360),
          toWidth: FwPx(1200),
        ),
        throwsArgumentError,
      );
    });
  });

  group('FwResponsiveLength', () {
    FwResponsiveLength length() =>
        FwResponsiveLength(Responsive(base: FwRem(1), lg: FwRem(1.5)));

    test('uses base below the override threshold', () {
      expect(length().resolveRaw(rootSize: 16, explicitWidth: 800), 16);
      expect(length().resolveRaw(rootSize: 16, explicitWidth: 991.9), 16);
    });

    test('activates overrides at exact thresholds', () {
      expect(length().resolveRaw(rootSize: 16, explicitWidth: 992), 24);
      expect(length().resolveRaw(rootSize: 16, explicitWidth: 1400), 24);
    });

    test('unknown width resolves base', () {
      expect(length().resolveRaw(rootSize: 16), 16);
    });

    test('larger overrides inherit downward', () {
      final l = FwResponsiveLength(
        Responsive(base: FwRem(1), md: FwRem(1.25), xxl: FwRem(2)),
      );
      expect(l.resolveRaw(rootSize: 16, explicitWidth: 800), 20); // md
      expect(l.resolveRaw(rootSize: 16, explicitWidth: 1000), 20); // md→lg
      expect(l.resolveRaw(rootSize: 16, explicitWidth: 1400), 32); // xxl
    });
  });

  group('value equality', () {
    test('lengths compare by value', () {
      expect(FwPx(4), FwPx(4));
      expect(FwPx(4), isNot(FwPx(5)));
      expect(FwRem(1), FwRem(1));
      expect(FwSpaceRef(FwSpace.s4), FwSpaceRef(FwSpace.s4));
      expect(
        FwFluid(
          min: FwRem(1),
          max: FwRem(2),
          fromWidth: FwPx(100),
          toWidth: FwPx(200),
        ),
        FwFluid(
          min: FwRem(1),
          max: FwRem(2),
          fromWidth: FwPx(100),
          toWidth: FwPx(200),
        ),
      );
    });
  });
}
