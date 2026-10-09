import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_core/fw_core.dart';

/// Wave 0, M0.3: the W3C Design Tokens export.
///
/// `tokens.yaml` is the single source of truth; `tokens.g.dart` (Dart) and
/// `tokens.json` (W3C DTCG 2025.10) are generated from it. These tests pin
/// the export contract: parseable JSON, DTCG leaf shape with descriptions,
/// and key sets matching the Dart token API.
void main() {
  Map<String, Object?> loadJson() {
    final root = _repoRoot();
    final file = File(
      '${root.path}/packages/fw_core/lib/src/tokens/tokens.json',
    );
    expect(file.existsSync(), isTrue, reason: 'tokens.json is generated');
    return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  }

  /// Dotted paths of every leaf token (a map carrying `$value`).
  List<String> leafPaths(Map<String, Object?> node, [String prefix = '']) {
    final paths = <String>[];
    node.forEach((key, value) {
      final path = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, Object?> && value.containsKey(r'$value')) {
        paths.add(path);
      } else if (value is Map<String, Object?>) {
        paths.addAll(leafPaths(value, path));
      }
    });
    return paths;
  }

  Map<String, Object?> at(Map<String, Object?> json, String dotted) {
    Object? node = json;
    for (final part in dotted.split('.')) {
      node = (node as Map<String, Object?>)[part];
    }
    return node as Map<String, Object?>;
  }

  test('every leaf has \$value, \$type, and a non-empty \$description', () {
    final json = loadJson();
    final paths = leafPaths(json);
    expect(paths, isNotEmpty);
    for (final path in paths) {
      final leaf = at(json, path);
      expect(leaf[r'$value'], isNotNull, reason: path);
      expect(leaf[r'$type'], isNotNull, reason: path);
      final description = leaf[r'$description'];
      expect(
        description is String && description.isNotEmpty,
        isTrue,
        reason: '$path needs an AI-agent-readable description',
      );
    }
  });

  test('color key sets match the Dart primitives', () {
    final json = loadJson();
    final color = json['color'] as Map<String, Object?>;
    final seeds = color['seed'] as Map<String, Object?>;
    expect(seeds.keys.toSet(), {
      'default',
      'ocean',
      'forest',
      'sunset',
      'monochrome',
    });
    final status = color['status'] as Map<String, Object?>;
    expect(status.keys.toSet(), {'success', 'warning', 'info'});
    for (final entry in status.entries) {
      final variants = (entry.value as Map<String, Object?>).keys.toSet();
      expect(variants, {
        'light',
        'on-light',
        'container-light',
        'on-container-light',
        'dark',
        'on-dark',
        'container-dark',
        'on-container-dark',
      }, reason: entry.key);
    }
    // Spot-check value parity between JSON and the Dart API.
    String hex(Color c) =>
        '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    expect(
      (at(json, 'color.status.success.light')[r'$value'] as String)
          .toUpperCase(),
      hex(FwColorPrimitives.successLight),
    );
    expect(
      (at(json, 'color.seed.ocean')[r'$value'] as String).toUpperCase(),
      hex(FwColorPrimitives.oceanSeed),
    );
  });

  test('spacing key sets match FwSpace', () {
    final json = loadJson();
    final space = json['space'] as Map<String, Object?>;
    expect(space.keys.toSet(), {for (final s in FwSpace.values) s.name});
    expect(at(json, 'space.s4')[r'$value'], '1rem');
    expect(at(json, 'space.s4')[r'$type'], 'dimension');
    expect(FwSpaceScale.remRatio(FwSpace.s4), 1);
  });

  test('radius, motion, and elevation key sets match the Dart API', () {
    final json = loadJson();
    final radius = json['radius'] as Map<String, Object?>;
    expect(radius.keys.toSet(), {'sm', 'md', 'lg', 'xl'});
    expect(at(json, 'radius.md')[r'$value'], '8px');
    expect(const FwRadii().md, 8);

    final duration =
        (json['motion'] as Map<String, Object?>)['duration']
            as Map<String, Object?>;
    expect(duration.keys.toSet(), {'xs', 'fast', 'medium', 'slow', 'xl'});
    expect(at(json, 'motion.duration.medium')[r'$value'], '200ms');
    expect(const FwMotion().medium.inMilliseconds, 200);

    final tint =
        (json['elevation'] as Map<String, Object?>)['tint-alpha']
            as Map<String, Object?>;
    expect(tint.keys.toSet(), {for (var i = 0; i <= 5; i++) 'level-$i'});
    expect(
      (tint['level-3']! as Map<String, Object?>)[r'$value'],
      FwElevation.tintAlphas[3],
    );
  });

  test('token count matches the YAML source', () {
    final json = loadJson();
    // 5 seeds + 24 status + 12 spacing + 4 radii + 5 motion + 6 elevation.
    expect(leafPaths(json), hasLength(56));
  });
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
