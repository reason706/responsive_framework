import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import '../component_doc.dart';

/// Doc board for the formatting delegates (utils backlog).
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired in here so the catalog edit stays a separate reviewable step):
///
/// ```dart
/// import 'docs/formatting_doc.dart';
/// // inside the catalog children list, e.g. under Foundations:
/// formattingDoc(),
/// ```
Widget formattingDoc() => const ComponentDoc(
  id: 'U04',
  name: 'Formatting delegates',
  tier: 'Foundations',
  summary:
      'Pure-Dart number, currency, and date formatting with zero '
      'dependencies. Separators, symbols, and month names are explicit '
      'parameters rather than locale lookups, so fw_utilities stays '
      'tree-shakable. For full CLDR locale data, use package:intl instead.',
  notFor: 'locale-aware month names or currency placement rules (use intl)',
  anatomy: const [
    AnatomyPart('FwNumberFormat', 'grouping, decimal places, separators.'),
    AnatomyPart('FwCurrencyFormat', 'symbol before/after, sign handling.'),
    AnatomyPart('FwDateFormat', 'pattern tokens; English month names.'),
  ],
  properties: const _FormattingDemo(),
  layoutSpecs: const [
    LayoutSpec('Purity', 'no BuildContext, no dependencies, const-able.'),
  ],
  dos: const [
    'Pass separators explicitly per market (de: 1.234,56).',
    'Prefer FwDateFormat.yMd() for machine-readable dates.',
  ],
  donts: const [
    'Don\u2019t expect locale data — month names are English by design.',
  ],
  a11y: const [
    'Formatted strings are plain text; screen readers read them as-is.',
    'For ambiguous dates, prefer unambiguous patterns (yyyy-MM-dd).',
  ],
);

class _FormattingDemo extends StatelessWidget {
  const _FormattingDemo();

  @override
  Widget build(BuildContext context) {
    const number = FwNumberFormat();
    const currency = FwCurrencyFormat();
    const euro = FwCurrencyFormat(symbol: '\u20ac', symbolAfter: true);
    const date = FwDateFormat('dd MMM yyyy');
    final rows = [
      ('Number', number.format(1234567.891)),
      (
        'German',
        const FwNumberFormat(
          groupSeparator: '.',
          decimalSeparator: ',',
        ).format(1234567.89),
      ),
      ('Currency', currency.format(1234.5)),
      ('Euro', euro.format(1234.5)),
      ('Date', date.format(DateTime(2026, 10, 10))),
      ('ISO', const FwDateFormat.yMd().format(DateTime(2026, 10, 10))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 90, child: Text(label)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
