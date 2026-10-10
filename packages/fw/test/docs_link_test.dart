/// Docs link-check: every `Fw*` API referenced in docs/ must exist in the
/// public Dart API. Run via `dart run melos run check` (package `fw`).
///
/// Forward-looking docs (migration guide, upgrade tables) name APIs from
/// planned releases; they are checked for well-formedness only.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Docs that describe a future version; existence is not required.
const forwardLooking = {
  'docs/migration.md',
  'docs/reference/component-matrix.md',
};

final _decl = RegExp(
  r'\b(?:class|enum|typedef|mixin|extension)\s+(Fw[A-Z][A-Za-z0-9]*)',
);
final _ref = RegExp(r'`(Fw[A-Z][A-Za-z0-9]*)`');

Set<String> _declaredApis() {
  final apis = <String>{};
  for (final pkg in [
    'fw_core',
    'fw_layout',
    'fw_utilities',
    'fw_components',
    'fw',
  ]) {
    final lib = Directory('../$pkg/lib');
    if (!lib.existsSync()) continue;
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      apis.addAll(
        _decl.allMatches(f.readAsStringSync()).map((m) => m.group(1)!),
      );
    }
  }
  return apis;
}

void main() {
  test('docs reference only APIs that exist', () {
    final apis = _declaredApis();
    expect(
      apis,
      isNotEmpty,
      reason: 'no Fw APIs found — wrong working directory?',
    );
    final missing = <String, List<String>>{};
    final docs = Directory('../../docs');
    for (final f in docs.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.md')) continue;
      // Normalize to a docs/-relative path regardless of how we got here.
      final idx = f.path.indexOf('/docs/');
      final rel = idx < 0 ? f.path : 'docs/${f.path.substring(idx + 6)}';
      if (rel.startsWith('docs/planning/'))
        continue; // historical plans, not API docs
      if (forwardLooking.contains(rel)) continue;
      final refs = _ref
          .allMatches(f.readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();
      final bad = refs.where((r) => !apis.contains(r)).toList()..sort();
      if (bad.isNotEmpty) missing[rel] = bad;
    }
    expect(
      missing,
      isEmpty,
      reason: 'docs reference unknown Fw APIs: $missing',
    );
  });

  test('forward-looking docs use well-formed Fw names', () {
    for (final rel in forwardLooking) {
      final f = File('../../$rel');
      if (!f.existsSync()) continue;
      final refs = _ref
          .allMatches(f.readAsStringSync())
          .map((m) => m.group(1)!);
      for (final r in refs) {
        expect(
          r,
          matches(RegExp(r'^Fw[A-Z][A-Za-z0-9]*$')),
          reason: '$rel: $r',
        );
      }
    }
  });
}
