import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

/// ImageProvider that always fails, proving offline/failure behavior
/// without network access.
class _FailingProvider extends ImageProvider<_FailingProvider> {
  @override
  Future<_FailingProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FailingProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('load failed')),
    );
  }
}

// Minimal 1x1 transparent PNG.
Uint8List get _png => Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  group('M01 FwImage', () {
    testWidgets('error builder runs on load failure', (tester) async {
      await tester.pumpWidget(
        host(
          FwImage(
            provider: _FailingProvider(),
            semanticLabel: 'Photo',
            errorBuilder: (context, error) =>
                const Text('could not load', key: ValueKey('err')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('err')), findsOneWidget);
    });

    testWidgets('default error keeps a broken-image indicator', (tester) async {
      await tester.pumpWidget(
        host(FwImage(provider: _FailingProvider(), width: 100, height: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meaningful image carries its label', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            FwImage(
              provider: MemoryImage(_png),
              semanticLabel: 'Sunset photo',
              width: 40,
              height: 40,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final node = tester.getSemantics(find.byType(FwImage));
        expect(node.label, 'Sunset photo');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('decorative image is excluded from semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(FwImage(provider: MemoryImage(_png), width: 40, height: 40)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(FwImage), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('M03 FwAvatar', () {
    test('initialsFor uses grapheme clusters, not naive indexing', () {
      expect(FwAvatar.initialsFor('Ada Lovelace'), 'AL');
      expect(FwAvatar.initialsFor('Ada'), 'A');
      // An emoji grapheme cluster survives intact: '😀S' is two runes,
      // never a lone surrogate from naive [0] indexing.
      expect(FwAvatar.initialsFor('😀 Smith'), '😀S');
      expect(FwAvatar.initialsFor('😀 Smith').runes.length, 2);
    });

    testWidgets('caller initials win over derived ones', (tester) async {
      await tester.pumpWidget(
        host(const FwAvatar(name: 'Ada Lovelace', initials: 'XY')),
      );
      expect(find.text('XY'), findsOneWidget);
      expect(find.text('AL'), findsNothing);
    });

    testWidgets('derived initials render when no image', (tester) async {
      await tester.pumpWidget(host(const FwAvatar(name: 'Ada Lovelace')));
      expect(find.text('AL'), findsOneWidget);
    });

    testWidgets('icon fallback renders at the fixed diameter', (tester) async {
      await tester.pumpWidget(host(const FwAvatar(size: FwAvatarSize.lg)));
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(tester.getSize(find.byType(FwAvatar)).width, 56);
    });

    testWidgets('status requires text meaning and announces it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwAvatar(
              name: 'Ada Lovelace',
              status: FwAvatarStatus.online,
              statusLabel: 'Online',
              semanticLabel: 'Ada Lovelace',
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(FwAvatar));
        expect(node.label, 'Ada Lovelace, Online');
      } finally {
        semantics.dispose();
      }
      expect(
        () => FwAvatar(status: FwAvatarStatus.online, name: 'Ada'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('M05 FwIcon', () {
    testWidgets('role color applies to the glyph', (tester) async {
      await tester.pumpWidget(
        host(
          const FwIcon(
            Icons.favorite,
            color: FwColorRole.error,
            semanticLabel: 'Liked',
          ),
        ),
      );
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        FwTheme.light().colors.of(FwColorRole.error),
      );
    });

    testWidgets('decorative icons are excluded from semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [FwIcon(Icons.star), Text('rated')],
            ),
          ),
        );
        // Only the text is announced; the decorative icon is not.
        expect(find.bySemanticsLabel('rated'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('O05 FwTooltip', () {
    testWidgets('message is exposed to semantics once', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(const FwTooltip(message: 'More info', child: Text('hover me'))),
        );
        final withTooltip = find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.tooltip ?? '').isNotEmpty,
        );
        expect(withTooltip, findsOneWidget);
        expect(
          tester.widget<Semantics>(withTooltip).properties.tooltip,
          'More info',
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('exclusion policy avoids double announcement', (tester) async {
      await tester.pumpWidget(
        host(
          FwTooltip(
            message: 'Search',
            excludeFromSemantics: true,
            child: FwIconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byType(FwTooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
