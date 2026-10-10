import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Token-layer discipline (Wave 0).
///
/// - M0.1: raw `Color(0x…)` literals may only appear in the primitive token
///   layer (`packages/fw_core/lib/src/tokens/`): brand seeds and
///   hand-validated status pairs live in [FwColorPrimitives], shadow alphas
///   in [FwShadows]. Components and themes resolve semantic roles
///   ([FwColorRole]) or component tokens ([FwButtonColors]) — never raw hex.
/// - M0.2: raw `BoxShadow(…)` constructors may only appear in [FwShadows].
///   Overlays, dialogs, and raised surfaces consume [FwElevation] levels.
/// - P1.3 (improvement-plan-2): numeric spacing literals (`EdgeInsets`,
///   `SizedBox`, `BorderRadius`, `spacing:`) may only appear via the token
///   layer (`FwSpace`, `FwSpaceAlias`, `FwRadii`, `FwRadiusClasses`). Two
///   documented non-spacing exemptions exist (see [_spacingExemptions]).
void main() {
  test('no raw color literals outside the primitive token layer', () {
    expect(
      _scan(RegExp(r'Color\s*\(\s*0x[0-9A-Fa-f]'), allowTokensDir: true),
      isEmpty,
      reason:
          'Raw Color(0x…) literals outside src/tokens/ — move them to '
          'FwColorPrimitives or resolve a semantic role.',
    );
  });

  test('no raw BoxShadow outside FwShadows', () {
    expect(
      _scan(RegExp(r'(^|[^A-Za-z_])BoxShadow\s*\('), allowTokensDir: false),
      isEmpty,
      reason:
          'Raw BoxShadow(…) outside FwShadows — consume FwElevation levels '
          'instead.',
    );
  });

  test('no hardcoded spacing literals outside the token layer', () {
    expect(
      _scanSpacing(),
      isEmpty,
      reason:
          'Numeric spacing literals in lib/src — resolve FwSpace / '
          'FwSpaceAlias / FwRadii / FwRadiusClasses instead. If the literal '
          'is genuinely not spacing, add it to _spacingExemptions with a '
          'reason.',
    );
  });
}

List<String> _scan(RegExp pattern, {required bool allowTokensDir}) {
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
      // The primitive layer owns raw color literals (including codegen'd
      // tokens.g.dart in M0.3); nothing owns raw BoxShadows except
      // FwShadows itself.
      if (allowTokensDir &&
          file.path.contains('packages/fw_core/lib/src/tokens/')) {
        continue;
      }
      if (!allowTokensDir &&
          file.path.endsWith('packages/fw_core/lib/src/tokens/shadows.dart')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
  }
  return violations;
}

Directory _repoRoot() {
  // Melos configuration lives in the root pubspec.yaml (no melos.yaml).
  var dir = Directory.current;
  bool isRoot(Directory d) =>
      File('${d.path}/pubspec.yaml').existsSync() &&
      Directory('${d.path}/packages').existsSync();
  while (!isRoot(dir)) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail(
        'Repository root (pubspec.yaml + packages/) not found above '
        '${Directory.current.path}',
      );
    }
    dir = parent;
  }
  return dir;
}

/// Documented non-spacing exemptions for the spacing-literal scan.
///
/// A literal stays only when it is genuinely not spacing: control heights
/// and paint-level geometry. Everything else resolves a token.
const _spacingExemptions = [
  (
    file: 'packages/fw_components/lib/src/calendar.dart',
    snippet: 'SizedBox(height: 44',
    reason: 'day-cell control height, not spacing',
  ),
  (
    file: 'packages/fw_components/lib/src/color_picker.dart',
    snippet: 'Radius.circular(10)',
    reason: 'paint-level radius inside _HuePainter (E3 precedent)',
  ),
];

/// Flags numeric `EdgeInsets` / `SizedBox(width:/height:)` /
/// `BorderRadius.circular` / `spacing:` / `runSpacing:` literals in every
/// package's `lib/src`, minus generated code and [_spacingExemptions].
List<String> _scanSpacing() {
  final patterns = [
    // Digits must sit in argument position (direct or named); nested calls
    // like EdgeInsets.all(theme.spaceScale.of(FwSpace.s6)) and computed
    // values like `gap / 2` are not literals.
    RegExp(r'EdgeInsets\.\w+\(\s*\d'),
    RegExp(r'EdgeInsets\.\w+\([^()]*:\s*\d'),
    RegExp(r'EdgeInsetsDirectional\.\w+\(\s*\d'),
    RegExp(r'EdgeInsetsDirectional\.\w+\([^()]*:\s*\d'),
    RegExp(r'SizedBox\(\s*(width|height)\s*:\s*\d'),
    RegExp(r'BorderRadius\.circular\s*\(\s*\d'),
    RegExp(r'(^|[^A-Za-z_.])(spacing|runSpacing)\s*:\s*\d'),
  ];
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
      if (file.path.endsWith('tokens.g.dart')) continue; // generated
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!patterns.any((p) => p.hasMatch(line))) continue;
        final exempted = _spacingExemptions.any(
          (e) => file.path.endsWith(e.file) && line.contains(e.snippet),
        );
        if (!exempted) {
          violations.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
  }
  return violations;
}
