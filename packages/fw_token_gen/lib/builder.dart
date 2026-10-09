import 'dart:convert';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

/// Build_runner factory (see package build.yaml).
Builder tokenBuilder(BuilderOptions options) => _TokenBuilder();

/// Reads `tokens.yaml` and emits `tokens.g.dart` (typed Dart constants) and
/// `tokens.json` (W3C Design Tokens, DTCG 2025.10 structure) next to it.
/// Other `.yaml` files are ignored.
class _TokenBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.yaml': ['.g.dart', '.json'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    if (!inputId.path.endsWith('/tokens.yaml')) return;
    final doc = loadYaml(await buildStep.readAsString(inputId)) as YamlMap;
    final tokens = (doc['tokens'] as YamlList).cast<YamlMap>();
    await buildStep.writeAsString(
      inputId.changeExtension('.g.dart'),
      _renderDart(tokens),
    );
    await buildStep.writeAsString(
      inputId.changeExtension('.json'),
      _renderJson(tokens),
    );
  }
}

class _Token {
  _Token(this.name, this.type, this.value, this.unit, this.description);

  final String name;
  final String type;
  final Object? value;
  final String? unit;
  final String description;
}

List<_Token> _parse(List<YamlMap> maps) => [
  for (final m in maps)
    _Token(
      m['name'] as String,
      m['type'] as String,
      m['value'],
      m['unit'] as String?,
      m['description'] as String,
    ),
];

/// `color.seed.default` -> `colorSeedDefault`.
String _dartBaseName(String dotted) {
  final buffer = StringBuffer();
  var first = true;
  for (final part in dotted.split('.')) {
    for (final segment in part.split('-')) {
      if (segment.isEmpty) continue;
      if (first) {
        buffer.write(segment);
        first = false;
      } else {
        buffer
          ..write(segment[0].toUpperCase())
          ..write(segment.substring(1));
      }
    }
  }
  return buffer.toString();
}

String _renderDart(List<YamlMap> maps) {
  final tokens = _parse(maps);
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Generated from tokens.yaml by package:fw_token_gen.')
    ..writeln('// Regenerate with `dart run build_runner build` in fw_core.')
    ..writeln()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln()
    ..writeln('/// Generated token values; the single source is tokens.yaml.')
    ..writeln('///')
    ..writeln('/// Prefer the semantic token classes ([FwColorPrimitives],')
    ..writeln('/// [FwSpaceScale], [FwRadii], [FwMotion], [FwElevation]) over')
    ..writeln('/// referencing these values directly.')
    ..writeln('abstract final class FwTokenValues {');
  for (final token in tokens) {
    final base = _dartBaseName(token.name);
    buffer.writeln('  /// ${token.description}');
    switch (token.type) {
      case 'color':
        final hex = (token.value as String).replaceFirst('#', '');
        final argb = hex.length == 6 ? 'FF$hex' : hex;
        buffer.writeln(
          '  static const Color $base = Color(0x${argb.toUpperCase()});',
        );
      case 'dimension':
        final suffix = token.unit == 'rem' ? 'Rem' : 'Px';
        buffer.writeln('  static const double $base$suffix = ${token.value};');
      case 'duration':
        buffer.writeln('  static const int ${base}Ms = ${token.value};');
      case 'number':
        buffer.writeln('  static const double $base = ${token.value};');
      default:
        throw StateError('Unknown token type: ${token.type}');
    }
  }
  buffer.writeln('}');
  return buffer.toString();
}

String _renderJson(List<YamlMap> maps) {
  final root = <String, Object?>{};
  for (final token in _parse(maps)) {
    final value = switch (token.type) {
      'color' => token.value as String,
      'dimension' => '${token.value}${token.unit}',
      'duration' => '${token.value}${token.unit}',
      'number' => token.value,
      _ => throw StateError('Unknown token type: ${token.type}'),
    };
    final leaf = <String, Object?>{
      r'$value': value,
      r'$type': token.type,
      r'$description': token.description,
    };
    var node = root;
    final parts = token.name.split('.');
    for (var i = 0; i < parts.length - 1; i++) {
      node = (node[parts[i]] ??= <String, Object?>{}) as Map<String, Object?>;
    }
    node[parts.last] = leaf;
  }
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert(root)}\n';
}
