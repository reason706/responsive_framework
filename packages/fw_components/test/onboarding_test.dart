import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(body: FwViewportQuery(child: child)),
);

List<FwOnboardingPage> testPages() => const [
  FwOnboardingPage(title: 'Welcome', body: 'First page body.'),
  FwOnboardingPage(title: 'Features', body: 'Second page body.'),
  FwOnboardingPage(title: 'Ready', body: 'Third page body.'),
];

void main() {
  group('FwOnboardingFlow', () {
    testWidgets('next advances; last page shows done', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        host(FwOnboardingFlow(pages: testPages(), onDone: () => done++)),
      );
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Features'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      await tester.pump();
      expect(done, 1);
    });

    testWidgets('skip invokes the callback', (tester) async {
      var skipped = 0;
      await tester.pumpWidget(
        host(
          FwOnboardingFlow(
            pages: testPages(),
            onDone: () {},
            onSkip: () => skipped++,
          ),
        ),
      );
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(skipped, 1);
    });

    testWidgets('skip hidden on the last page', (tester) async {
      await tester.pumpWidget(
        host(FwOnboardingFlow(pages: testPages(), onDone: () {})),
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('page indicator announces position', (tester) async {
      await tester.pumpWidget(
        host(FwOnboardingFlow(pages: testPages(), onDone: () {})),
      );
      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
    });

    testWidgets('swipe disabled when allowSwipe is false', (tester) async {
      await tester.pumpWidget(
        host(
          FwOnboardingFlow(
            pages: testPages(),
            onDone: () {},
            allowSwipe: false,
          ),
        ),
      );
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
