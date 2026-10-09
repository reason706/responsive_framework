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
  _toastTests();
  _notificationTests();
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

// ---------------------------------------------------------------------------
// B02 — toast service.
// ---------------------------------------------------------------------------

Widget _toastWrap(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(
    body: FwToastHost(child: FwViewportQuery(child: child)),
  ),
);

void _toastTests() {
  group('FwToast', () {
    testWidgets('show renders severity, message, and action', (tester) async {
      await tester.pumpWidget(_toastWrap(const SizedBox()));
      var actioned = false;
      final future = FwToast.show(
        FwToast(
          message: 'File deleted',
          severity: FwToastSeverity.error,
          actionLabel: 'Undo',
          onAction: () => actioned = true,
        ),
      );
      await tester.pump();
      expect(find.text('File deleted'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(actioned, isTrue);
      expect(find.text('File deleted'), findsNothing);
      final result = await future;
      expect(result.dismissal, FwToastDismissal.action);
    });

    testWidgets('queue shows toasts in order', (tester) async {
      await tester.pumpWidget(_toastWrap(const SizedBox()));
      final first = FwToast.show(const FwToast(message: 'First'));
      final second = FwToast.show(const FwToast(message: 'Second'));
      await tester.pump();
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      await tester.pump();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect((await first).dismissal, FwToastDismissal.manual);
      FwToast.dismissCurrent();
      await tester.pump();
      await second;
    });

    testWidgets('dedup replaces instead of queueing', (tester) async {
      await tester.pumpWidget(_toastWrap(const SizedBox()));
      final first = FwToast.show(
        const FwToast(message: 'Saving…', dedupKey: 'save'),
      );
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      final second = FwToast.show(
        const FwToast(message: 'Saved', dedupKey: 'save'),
      );
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Saving…'), findsNothing);
      expect((await first).dismissal, FwToastDismissal.manual);
      FwToast.dismissCurrent();
      await tester.pump();
      await second;
    });

    testWidgets('auto-dismiss fires after the duration', (tester) async {
      await tester.pumpWidget(_toastWrap(const SizedBox()));
      FwToastResult? result;
      FwToast.show(
        const FwToast(message: 'Ephemeral', duration: Duration(seconds: 4)),
      ).then((r) => result = r);
      await tester.pump();
      expect(find.text('Ephemeral'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Ephemeral'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Ephemeral'), findsNothing);
      expect(result?.dismissal, FwToastDismissal.timeout);
    });

    testWidgets('persistent toast never auto-dismisses', (tester) async {
      await tester.pumpWidget(_toastWrap(const SizedBox()));
      FwToast.show(const FwToast(message: 'Working…', persistent: true));
      await tester.pump();
      expect(find.text('Working…'), findsOneWidget);
      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Working…'), findsOneWidget);
      FwToast.dismissCurrent();
      await tester.pump();
      expect(find.text('Working…'), findsNothing);
    });

    testWidgets('swipe dismisses the toast', (tester) async {
      await tester.pumpWidget(_toastWrap(const SizedBox()));
      FwToastResult? result;
      FwToast.show(const FwToast(message: 'Swipe me')).then((r) => result = r);
      await tester.pump();
      await tester.drag(find.text('Swipe me'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Swipe me'), findsNothing);
      expect(result?.dismissal, FwToastDismissal.swipe);
    });
  });

  group('FwTaskList', () {
    testWidgets('renders per-item status, progress, and actions', (
      tester,
    ) async {
      String? cancelled;
      String? retried;
      String? dismissed;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: FwTaskList(
              tasks: const [
                FwTask(
                  id: 'a',
                  label: 'upload.png',
                  status: FwTaskStatus.running,
                  progress: 0.5,
                  detail: '4 MB of 8 MB',
                ),
                FwTask(
                  id: 'b',
                  label: 'photo.jpg',
                  status: FwTaskStatus.failed,
                  detail: 'Network error',
                ),
                FwTask(
                  id: 'c',
                  label: 'doc.pdf',
                  status: FwTaskStatus.succeeded,
                ),
              ],
              onCancel: (id) => cancelled = id,
              onRetry: (id) => retried = id,
              onDismiss: (id) => dismissed = id,
            ),
          ),
        ),
      );
      expect(find.text('upload.png'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('4 MB of 8 MB'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancel upload.png'));
      expect(cancelled, 'a');
      await tester.tap(find.byTooltip('Retry photo.jpg'));
      expect(retried, 'b');
      await tester.tap(find.byTooltip('Dismiss doc.pdf'));
      expect(dismissed, 'c');
    });

    testWidgets('indeterminate progress when totals unknown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: const Scaffold(
            body: FwTaskList(
              tasks: [
                FwTask(
                  id: 'a',
                  label: 'streaming',
                  status: FwTaskStatus.running,
                ),
              ],
            ),
          ),
        ),
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);
    });

    testWidgets('empty list shows the empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: const Scaffold(
            body: FwTaskList(tasks: [], emptyText: 'All clear'),
          ),
        ),
      );
      expect(find.text('All clear'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// B11 — notification center.
// ---------------------------------------------------------------------------

void _notificationTests() {
  group('FwNotificationCenter', () {
    List<FwNotification> notifications() => [
      FwNotification(
        id: '1',
        title: 'Mentioned you',
        body: 'Ada mentioned you in #general',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        group: 'Mentions',
      ),
      FwNotification(
        id: '2',
        title: 'Build passed',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        read: true,
        group: 'CI',
      ),
      const FwNotification(
        id: '3',
        title: 'Welcome',
        body: 'Thanks for joining',
        read: true,
      ),
    ];

    Widget host(
      List<FwNotification> items, {
      void Function(String)? onMarkRead,
    }) => MaterialApp(
      theme: FwTheme.light().toThemeData(),
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: FwNotificationCenter(
            notifications: items,
            onMarkRead: onMarkRead,
            onMarkAllRead: () {},
            onClearAll: () {},
            onDismiss: (_) {},
          ),
        ),
      ),
    );

    testWidgets('groups, unread count, and relative time render', (
      tester,
    ) async {
      await tester.pumpWidget(host(notifications()));
      await tester.pump();
      expect(find.text('Mentions'), findsOneWidget);
      expect(find.text('CI'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('1 unread'), findsOneWidget);
      expect(find.text('5m ago'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('unread dot marks read via callback', (tester) async {
      String? marked;
      await tester.pumpWidget(
        host(notifications(), onMarkRead: (id) => marked = id),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Mark read'));
      await tester.pump();
      expect(marked, '1');
    });

    testWidgets('tap reports the notification for app-owned deep links', (
      tester,
    ) async {
      FwNotification? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: FwNotificationCenter(
                notifications: notifications(),
                onNotificationTap: (n) => tapped = n,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Mentioned you'));
      await tester.pump();
      expect(tapped?.id, '1');
    });

    testWidgets('empty state shows the illustration slot', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: const Scaffold(
            body: FwNotificationCenter(
              notifications: [],
              emptyIllustration: const Icon(Icons.inbox, size: 48),
              emptyTitle: 'All clear',
              emptyBody: 'Nothing to see here',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('All clear'), findsOneWidget);
      expect(find.text('Nothing to see here'), findsOneWidget);
    });
  });

  group('FwUnreadBadge', () {
    testWidgets('hides at zero, caps above max', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FwTheme.light().toThemeData(),
          home: const Scaffold(
            body: Column(
              children: [
                FwUnreadBadge(count: 0, child: Icon(Icons.notifications)),
                FwUnreadBadge(count: 150),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      // Zero: icon without a badge.
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('0'), findsNothing);
      // Capped.
      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('B10 FwRefreshableList', () {
    Widget list({
      Future<void> Function()? onRefresh,
      Future<void> Function()? onLoadMore,
      bool hasMore = false,
      bool isLoadingMore = false,
      int count = 20,
    }) => MaterialApp(
      theme: FwTheme.light().toThemeData(),
      home: Scaffold(
        body: FwRefreshableList(
          onRefresh: onRefresh ?? () async {},
          onLoadMore: onLoadMore,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          itemCount: count,
          itemBuilder: (context, i) => ListTile(title: Text('Item $i')),
        ),
      ),
    );

    testWidgets('renders items', (tester) async {
      await tester.pumpWidget(list());
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('pull-to-refresh calls onRefresh', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(list(onRefresh: () async => refreshed = true));
      // Drag down from the top to overscroll.
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(refreshed, isTrue);
    });

    testWidgets('scrolling near the end calls onLoadMore', (tester) async {
      var loadMoreCalls = 0;
      await tester.pumpWidget(
        list(hasMore: true, onLoadMore: () async => loadMoreCalls++),
      );
      // Jump to the end.
      final controller = tester
          .widget<Scrollable>(find.byType(Scrollable).first)
          .controller;
      // Scroll via drags to the bottom.
      for (var i = 0; i < 10; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(loadMoreCalls, greaterThan(0));
      expect(controller, isNotNull);
    });

    testWidgets('isLoadingMore appends an indicator', (tester) async {
      await tester.pumpWidget(list(isLoadingMore: true));
      // Scroll to the end to reveal the appended indicator.
      await tester.dragUntilVisible(
        find.byType(CircularProgressIndicator),
        find.byType(ListView),
        const Offset(0, -500),
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('no onLoadMore means no end calls', (tester) async {
      await tester.pumpWidget(list(hasMore: true));
      for (var i = 0; i < 10; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      // No crash, no indicator without isLoadingMore.
      expect(find.text('Item 0'), findsNothing); // scrolled away
    });
  });
}
