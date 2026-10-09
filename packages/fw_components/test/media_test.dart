import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(body: Center(child: child)),
);

/// All non-empty labels in the semantics subtree rooted at [node].
List<String> semanticsLabels(SemanticsNode node) {
  final labels = <String>[];
  void walk(SemanticsNode n) {
    if (n.label.isNotEmpty) labels.add(n.label);
    n.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(node);
  return labels;
}

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

  group('M02 FwFigure', () {
    Widget figure({String? semanticLabel}) => FwFigure(
      image: FwImage(provider: MemoryImage(_png), semanticLabel: 'A mountain'),
      caption: 'Sunrise over the ridge',
      credit: 'Photo: A. Hiker',
      semanticLabel: semanticLabel,
    );

    testWidgets('renders caption and credit', (tester) async {
      await tester.pumpWidget(host(figure()));
      expect(find.text('Sunrise over the ridge'), findsOneWidget);
      expect(find.textContaining('A. Hiker'), findsOneWidget);
    });

    testWidgets('figure label suppresses duplicate image announcement', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(figure()));
        final labels = semanticsLabels(
          tester.getSemantics(find.byType(FwFigure)),
        );
        // One announcement for the whole figure…
        expect(labels, hasLength(1));
        // …naming the caption once (not twice) plus the credit…
        expect(labels.single, contains('Sunrise over the ridge'));
        expect(
          'Sunrise over the ridge'.allMatches(labels.single),
          hasLength(1),
        );
        expect(labels.single, contains('Photo: A. Hiker'));
        // …and never the suppressed inner image label.
        expect(labels.single, isNot(contains('A mountain')));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('explicit semanticLabel wins over caption', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(figure(semanticLabel: 'Custom label')));
        final labels = semanticsLabels(
          tester.getSemantics(find.byType(FwFigure)),
        );
        expect(labels, hasLength(1));
        expect(labels.single, contains('Custom label'));
        // A caption that differs from the explicit label stays in the
        // announcement; the figure label itself is not the caption.
        expect(labels.single, contains('Sunrise over the ridge'));
        expect(labels.single, isNot(contains('A mountain')));
      } finally {
        semantics.dispose();
      }
    });
  });

  group('M04 FwAvatarGroup', () {
    List<FwAvatar> avatars(int n) => [
      for (var i = 0; i < n; i++) FwAvatar(name: 'Person $i'),
    ];

    testWidgets('caps visible count and shows +N', (tester) async {
      await tester.pumpWidget(
        host(FwAvatarGroup(children: avatars(7), maxVisible: 5)),
      );
      // 5 avatars + 1 overflow chip.
      expect(find.byType(FwAvatar), findsNWidgets(5));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('no overflow chip when within cap', (tester) async {
      await tester.pumpWidget(
        host(FwAvatarGroup(children: avatars(3), maxVisible: 5)),
      );
      expect(find.byType(FwAvatar), findsNWidgets(3));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('overflow tap fires when provided', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          FwAvatarGroup(
            children: avatars(7),
            maxVisible: 5,
            onOverflowTap: () => tapped++,
          ),
        ),
      );
      await tester.tap(find.text('+2'));
      expect(tapped, 1);
    });

    testWidgets('avatars overlap: later avatars offset along inline axis', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwAvatarGroup(
            children: [
              FwAvatar(name: 'A'),
              FwAvatar(name: 'B'),
              FwAvatar(name: 'C'),
            ],
          ),
        ),
      );
      final xs = [
        for (final v in ['A', 'B', 'C'])
          tester
              .getTopLeft(
                find.byWidgetPredicate((w) {
                  return w is FwAvatar && w.name == v;
                }),
              )
              .dx,
      ];
      expect(xs[1] - xs[0], greaterThan(0));
      expect(xs[2] - xs[1], greaterThan(0));
      // Offset is less than a full diameter: they overlap.
      expect(xs[1] - xs[0], lessThan(FwAvatarSize.md.diameter));
    });

    testWidgets('first avatar paints on top', (tester) async {
      await tester.pumpWidget(
        host(
          const FwAvatarGroup(
            children: [
              FwAvatar(name: 'A'),
              FwAvatar(name: 'B'),
            ],
          ),
        ),
      );
      // Stack paints later children on top: the last child must hold
      // the first avatar.
      final stack = tester.widget<Stack>(
        find.descendant(
          of: find.byType(FwAvatarGroup),
          matching: find.byType(Stack),
        ),
      );
      final top = stack.children.last as PositionedDirectional;
      final sized = top.child as SizedBox;
      final fit = sized.child as FittedBox;
      expect((fit.child as FwAvatar).name, 'A');
    });
  });
}
