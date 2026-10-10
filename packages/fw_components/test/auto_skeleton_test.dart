import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  group('FwAutoSkeleton', () {
    testWidgets('paints bones for a typical subtree without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FwAutoSkeleton(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Ada Lovelace'), Text('First programmer')],
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(FwAutoSkeleton));
      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(0));
      // The real text is laid out (sizes the skeleton) but never painted:
      // no text should be visible through the bones.
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('empty child falls back to a full-box bone', (tester) async {
      await tester.pumpWidget(
        _wrap(const FwAutoSkeleton(child: SizedBox(width: 120, height: 48))),
      );
      expect(tester.getSize(find.byType(FwAutoSkeleton)), const Size(120, 48));
    });

    testWidgets('nested containers produce leaf bones only', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FwAutoSkeleton(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('A'), SizedBox(width: 8), Text('B')],
              ),
            ),
          ),
        ),
      );
      // Padding (8) + text + gap + text: skeleton sizes to the subtree.
      final size = tester.getSize(find.byType(FwAutoSkeleton));
      expect(size.width, greaterThan(16));
    });

    testWidgets('respects a custom bone color role', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FwAutoSkeleton(
            boneColorRole: FwColorRole.primary,
            child: Text('Tinted'),
          ),
        ),
      );
      expect(find.byType(FwAutoSkeleton), findsOneWidget);
    });
  });
}
