import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Token-layer discipline (Wave 0, M0.1).
///
/// Raw `Color(0x…)` literals may only appear in the primitive token layer
/// (`packages/fw_core/lib/src/tokens/`): brand seeds and hand-validated
/// status pairs live in [FwColorPrimitives], shadow alphas in [FwShadows].
/// Components and themes resolve semantic roles ([FwColorRole]) or
/// component tokens ([FwButtonColors]) — never raw hex.
void main() {
  test('no raw color literals outside the primitive token layer', () {
    final root = _repoRoot();
    final pattern = RegExp(r'Color\s*\(\s*0x[0-9A-Fa-f]');
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
        // The primitive layer owns every raw literal (including codegen'd
        // tokens.g.dart in M0.3).
        if (file.path.contains('packages/fw_core/lib/src/tokens/')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) {
            violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Raw Color(0x…) literals outside src/tokens/ — move them to '
          'FwColorPrimitives or resolve a semantic role:\n'
          '${violations.join('\n')}',
    );
  });
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
