import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

/// Layer-3 proof: FwButton reads a registered FwButtonColors override, and
/// renders identically to the semantic-role fallback when none is present.
void main() {
  testWidgets('button prefers a registered FwButtonColors override', (
    tester,
  ) async {
    const customBackground = Color(0xFF123456);
    const customForeground = Color(0xFFFEDCBA);
    final theme = FwTheme.light();
    final override = FwButtonColors(
      solid: {
        for (final intent in FwIntent.values)
          intent: const FwButtonColorSet(
            background: customBackground,
            foreground: customForeground,
          ),
      },
      tonal: {
        for (final intent in FwIntent.values)
          intent: const FwButtonColorSet(
            background: customBackground,
            foreground: customForeground,
          ),
      },
      textTreatment: {
        for (final intent in FwIntent.values)
          intent: const FwButtonColorSet(foreground: customForeground),
      },
    );
    final data = theme.toThemeData().copyWith(extensions: [theme, override]);
    await tester.pumpWidget(
      MaterialApp(
        theme: data,
        home: Scaffold(
          body: FwButton(label: 'Go', onPressed: () {}),
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style!.backgroundColor!.resolve({}), customBackground);
    expect(button.style!.foregroundColor!.resolve({}), customForeground);
    expect(tester.takeException(), isNull);
  });

  testWidgets('button falls back to semantic roles without an override', (
    tester,
  ) async {
    final theme = FwTheme.forest();
    // Deliberately no FwButtonColors extension: exercises the
    // fromColors(colors) fallback inside FwButton.
    final data = ThemeData(
      useMaterial3: true,
      colorScheme: theme.colors.scheme,
      extensions: [theme],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: data,
        home: Scaffold(
          body: FwButton(label: 'Go', onPressed: () {}),
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      button.style!.backgroundColor!.resolve({}),
      theme.colors.of(FwColorRole.primary),
    );
    expect(tester.takeException(), isNull);
  });
}
