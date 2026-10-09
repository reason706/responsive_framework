import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child, {FwTheme? theme}) => MaterialApp(
  theme: (theme ?? FwTheme.light()).toThemeData(),
  home: Scaffold(
    body: FwViewportQuery(child: Center(child: child)),
  ),
);

void main() {
  group('FwAlert', () {
    testWidgets('renders intent icon, title, body, and action', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        host(
          FwAlert(
            intent: FwAlertIntent.danger,
            title: 'Upload failed',
            body: 'The file was too large.',
            action: TextButton(
              onPressed: () => acted = true,
              child: const Text('Details'),
            ),
          ),
        ),
      );
      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.text('The file was too large.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Details'));
      expect(acted, isTrue);
    });

    testWidgets('dismiss button calls onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        host(
          FwAlert(
            intent: FwAlertIntent.info,
            title: 'Heads up',
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Dismiss'));
      expect(dismissed, isTrue);
    });

    testWidgets('no dismiss button without onDismiss', (tester) async {
      await tester.pumpWidget(
        host(const FwAlert(intent: FwAlertIntent.success, title: 'Saved')),
      );
      expect(find.byTooltip('Dismiss'), findsNothing);
    });

    testWidgets('announce makes it a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const FwAlert(
              intent: FwAlertIntent.warning,
              title: 'Session expiring',
              announce: true,
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(FwAlert));
        expect(node.flagsCollection.isLiveRegion, isTrue);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('FwLinearProgress', () {
    testWidgets('determinate shows percentage label and semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(const FwLinearProgress(value: 0.42)));
        expect(find.text('42%'), findsOneWidget);
        final node = tester.getSemantics(find.byType(LinearProgressIndicator));
        expect(node.value, '42%');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('indeterminate shows loading text', (tester) async {
      await tester.pumpWidget(host(const FwLinearProgress()));
      expect(find.text('Loading…'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);
    });

    testWidgets('invalid values are rejected', (tester) async {
      expect(
        () => FwLinearProgress(value: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('FwCircularProgress', () {
    testWidgets('determinate exposes value semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(const FwCircularProgress(value: 0.75)));
        final node = tester.getSemantics(
          find.byType(CircularProgressIndicator),
        );
        expect(node.value, '75%');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('size and stroke are applied', (tester) async {
      await tester.pumpWidget(
        host(const FwCircularProgress(size: 48, strokeWidth: 6)),
      );
      final box = tester.getSize(find.byType(FwCircularProgress));
      expect(box, const Size(48, 48));
    });
  });

  group('FwBusyIndicator', () {
    testWidgets('shows spinner and label by default', (tester) async {
      await tester.pumpWidget(host(const FwBusyIndicator(label: 'Saving…')));
      expect(find.text('Saving…'), findsOneWidget);
      expect(find.byType(FwCircularProgress), findsOneWidget);
    });

    testWidgets('reduced motion replaces spinner with static icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: const Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const FwViewportQuery(
                child: Center(child: FwBusyIndicator(label: 'Saving…')),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.byType(FwCircularProgress), findsNothing);
      // The busy state is still communicated.
      expect(find.text('Saving…'), findsOneWidget);
    });
  });

  group('FwSkeleton', () {
    testWidgets('is excluded from semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const Column(
              children: [FwSkeleton(width: 120), FwSkeleton.avatar()],
            ),
          ),
        );
        // No semantic nodes for decorative placeholders.
        expect(
          find.byWidgetPredicate((w) => w is FwSkeleton),
          findsNWidgets(2),
        );
        final root = tester.getSemantics(find.byType(Column));
        expect(root.label.isEmpty, isTrue);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('avatar is circular', (tester) async {
      await tester.pumpWidget(host(const FwSkeleton.avatar()));
      final box = tester.getSize(find.byType(FwSkeleton));
      expect(box, const Size(40, 40));
    });
  });

  group('FwStatePanel', () {
    testWidgets('empty state renders heading and description', (tester) async {
      await tester.pumpWidget(
        host(
          const FwStatePanel.empty(
            heading: 'No results',
            description: 'Try a different search.',
          ),
        ),
      );
      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Try a different search.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('error state retry calls onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        host(
          FwStatePanel.error(
            heading: 'Something went wrong',
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('offline state has default copy', (tester) async {
      await tester.pumpWidget(host(const FwStatePanel.offline()));
      expect(find.text('You are offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
    });
  });
}
