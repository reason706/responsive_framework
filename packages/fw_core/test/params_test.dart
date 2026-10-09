import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

/// E1: shared parameter vocabulary + API color discipline.
///
/// - [FwSize] has five ordered values with a monotonic scale factor and
///   md == 1.0 as the reference.
/// - [FwShape] and [FwIconPosition] keep size/shape/placement orthogonal;
///   icon placement uses logical directions only (never left/right).
/// - Public component APIs never declare raw [Color] members: color is
///   expressed as [FwIntent]/[FwColorRole] resolved through the theme.
///   Reviewed exemptions are documented in [_isExempt].
void main() {
  group('FwSize', () {
    test('has five ordered values xs..xl', () {
      expect(FwSize.values, [
        FwSize.xs,
        FwSize.sm,
        FwSize.md,
        FwSize.lg,
        FwSize.xl,
      ]);
    });

    test('scaleFactor is monotonic with md as the 1.0 reference', () {
      expect(FwSize.md.scaleFactor, 1.0);
      final factors = FwSize.values.map((s) => s.scaleFactor).toList();
      for (var i = 1; i < factors.length; i++) {
        expect(factors[i], greaterThan(factors[i - 1]));
      }
    });
  });

  group('FwShape', () {
    test('shape family is independent of size', () {
      expect(FwShape.values, [FwShape.stadium, FwShape.rounded, FwShape.sharp]);
    });
  });

  group('FwIconPosition', () {
    test('uses logical directions only, plus stacked and icon-only', () {
      expect(FwIconPosition.values, [
        FwIconPosition.start,
        FwIconPosition.end,
        FwIconPosition.top,
        FwIconPosition.bottom,
        FwIconPosition.only,
      ]);
    });

    test('inline/stacked predicates partition the placements', () {
      expect(FwIconPosition.start.isInline, isTrue);
      expect(FwIconPosition.end.isInline, isTrue);
      expect(FwIconPosition.top.isStacked, isTrue);
      expect(FwIconPosition.bottom.isStacked, isTrue);
      expect(FwIconPosition.only.isInline, isFalse);
      expect(FwIconPosition.only.isStacked, isFalse);
      // No placement is both inline and stacked.
      for (final p in FwIconPosition.values) {
        expect(p.isInline && p.isStacked, isFalse);
      }
    });
  });

  group('FwLoadingPosition', () {
    test('start/end/center indicator placement', () {
      expect(FwLoadingPosition.values, [
        FwLoadingPosition.start,
        FwLoadingPosition.end,
        FwLoadingPosition.center,
      ]);
    });
  });

  test('no raw Color declarations in public component APIs', () {
    expect(
      _scanColorDeclarations(),
      isEmpty,
      reason:
          'Raw Color-typed members in public component APIs — express color '
          'as FwIntent/FwColorRole resolved through the theme, or document '
          'a reviewed exemption in _isExempt.',
    );
  });
}

/// Lines that declare a Color-typed member or parameter:
/// `Color name`, `Color? name`, `final Color name`, at line start.
final _colorDecl = RegExp(
  r'^\s*(final\s+)?Color\??\s+[a-zA-Z_][a-zA-Z0-9_]*\s*[,;=)]',
);

/// Finds the nearest declaration (`class X`, `X(`, `Type name(`) above
/// [index], used to attribute a Color declaration to its owner.
///
/// Implemented as a linear scan (no nested-quantifier regexes) so long
/// doc-comment lines cannot cause catastrophic backtracking.
String _enclosingName(List<String> lines, int index) {
  final classDecl = RegExp(
    r'^(?:abstract\s+|final\s+|base\s+|sealed\s+|mixin\s+)?class\s+(\w+)',
  );
  final word = RegExp(r'^\w+$');
  for (var i = index - 1; i >= 0 && i > index - 40; i--) {
    final line = lines[i].trim();
    if (line.startsWith('//')) continue; // skip doc/line comments
    final classMatch = classDecl.firstMatch(line);
    if (classMatch != null) return classMatch.group(1)!;
    final paren = line.indexOf('(');
    if (paren > 0) {
      final before = line.substring(0, paren).trim();
      if (before.isEmpty) continue;
      final name = before.split(RegExp(r'\s+')).last.split('.').last;
      if (word.hasMatch(name)) return name;
    }
  }
  return '';
}

/// Reviewed exemptions to the no-raw-Color rule.
///
/// - `src/tokens/`: the primitive token layer owns raw colors
///   ([FwColorPrimitives], [FwShadows]).
/// - `theme/component_colors.dart`: the component-token layer stores
///   resolved colors internally; widgets consume it, never raw Colors.
/// - `Color seed =`: theme factory seed inputs are documented theme-axis
///   inputs, not token keys.
/// - `styleFrom`: a local style helper inside FwButton.build that resolves
///   token colors into a Material ButtonStyle; not a public parameter.
/// - `_`-prefixed owners: private painters/delegates plumbing resolved
///   colors internally (e.g. `_RingPainter`).
/// - Paint-level classes (subclasses of [CustomPainter],
///   [SliderComponentShape], and similar paint delegates): they receive
///   already-resolved colors from the widget, which owns the token
///   lookup. The component API takes tokens; the painter takes paint.
bool _isExempt(
  String path,
  String owner,
  String line,
  Set<String> paintOwners,
) {
  if (path.contains('packages/fw_core/lib/src/tokens/')) return true;
  if (path.endsWith('theme/component_colors.dart')) return true;
  if (line.contains('Color seed =')) return true;
  if (owner == 'styleFrom') return true;
  if (owner.startsWith('_')) return true;
  if (paintOwners.contains(owner)) return true;
  return false;
}

/// Class names in [lines] that extend a paint delegate type.
Set<String> _paintOwners(List<String> lines) {
  final owners = <String>{};
  final decl = RegExp(
    r'class\s+(\w+)\s+extends\s+(CustomPainter|SliderComponentShape|'
    r'SliderTrackShape|SliderTickMarkShape|RangeSliderThumbShape|'
    r'CustomClipper)\b',
  );
  for (final line in lines) {
    final m = decl.firstMatch(line.split('//').first);
    if (m != null) owners.add(m.group(1)!);
  }
  return owners;
}

List<String> _scanColorDeclarations() {
  final root = _repoRoot();
  final violations = <String>[];
  for (final package in [
    'fw',
    'fw_components',
    'fw_core',
    'fw_layout',
    'fw_utilities',
  ]) {
    final lib = Directory('${root.path}/packages/$package/lib');
    if (!lib.existsSync()) continue;
    final files = lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      final paintOwners = _paintOwners(lines);
      for (var i = 0; i < lines.length; i++) {
        // Strip line comments so documentation mentioning Color is ignored.
        final code = lines[i].split('//').first;
        if (!_colorDecl.hasMatch(code)) continue;
        final owner = _enclosingName(lines, i);
        if (_isExempt(file.path, owner, code, paintOwners)) continue;
        violations.add('${file.path}:${i + 1} [$owner]: ${code.trim()}');
      }
    }
  }
  return violations;
}

Directory _repoRoot() {
  var dir = Directory.current;
  bool isRoot(Directory d) =>
      File('${d.path}/pubspec.yaml').existsSync() &&
      Directory('${d.path}/packages').existsSync();
  while (!isRoot(dir)) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Repository root not found above ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir;
}
