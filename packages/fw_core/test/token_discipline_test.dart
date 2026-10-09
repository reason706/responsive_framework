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
