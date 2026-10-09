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

List<FwDestination> testDestinations() => const [
  FwDestination(id: 'home', label: 'Home', icon: Icon(Icons.home_outlined)),
  FwDestination(
    id: 'search',
    label: 'Search',
    icon: Icon(Icons.search_outlined),
    badgeLabel: '3',
  ),
  FwDestination(
    id: 'settings',
    label: 'Settings',
    icon: Icon(Icons.settings_outlined),
    disabled: true,
  ),
];

void main() {
  group('FwTabs', () {
    List<FwTabItem> tabItems() => const [
      FwTabItem(label: 'Overview'),
      FwTabItem(label: 'Details', icon: Icon(Icons.info_outline, size: 18)),
      FwTabItem(label: 'Activity', badgeLabel: '5'),
    ];

    testWidgets('tapping a tab reports the index', (tester) async {
      var index = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwTabs(
              items: tabItems(),
              selectedIndex: index,
              onChanged: (i) => setState(() => index = i),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(index, 2);
    });

    testWidgets('external index change animates the indicator', (tester) async {
      await tester.pumpWidget(
        host(FwTabs(items: tabItems(), selectedIndex: 0, onChanged: (_) {})),
      );
      await tester.pumpWidget(
        host(FwTabs(items: tabItems(), selectedIndex: 2, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.controller!.index, 2);
    });

    testWidgets('contained variant renders a pill indicator', (tester) async {
      await tester.pumpWidget(
        host(
          FwTabs(
            items: tabItems(),
            selectedIndex: 0,
            onChanged: (_) {},
            variant: FwTabVariant.contained,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicator, isA<BoxDecoration>());
    });
  });

  group('FwTabPanels', () {
    testWidgets('keepAlive retains panel state across switches', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FwTabPanels(
            selectedIndex: 0,
            children: [
              TextField(key: ValueKey('field')),
              Text('panel two'),
            ],
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('field')), 'hello');
      await tester.pumpWidget(
        host(
          const FwTabPanels(
            selectedIndex: 1,
            children: [
              TextField(key: ValueKey('field')),
              Text('panel two'),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          const FwTabPanels(
            selectedIndex: 0,
            children: [
              TextField(key: ValueKey('field')),
              Text('panel two'),
            ],
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('lazy panels discard state on switch', (tester) async {
      await tester.pumpWidget(
        host(
          const FwTabPanels(
            selectedIndex: 0,
            keepAlive: false,
            children: [
              TextField(key: ValueKey('field')),
              Text('panel two'),
            ],
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('field')), 'hello');
      await tester.pumpWidget(
        host(
          const FwTabPanels(
            selectedIndex: 1,
            keepAlive: false,
            children: [
              TextField(key: ValueKey('field')),
              Text('panel two'),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          const FwTabPanels(
            selectedIndex: 0,
            keepAlive: false,
            children: [
              TextField(key: ValueKey('field')),
              Text('panel two'),
            ],
          ),
        ),
      );
      expect(find.text('hello'), findsNothing);
    });
  });

  group('FwNavbar', () {
    testWidgets('menu trigger invokes callback; actions render', (
      tester,
    ) async {
      var menuPressed = 0;
      await tester.pumpWidget(
        host(
          FwNavbar(
            title: 'Dashboard',
            onMenuPressed: () => menuPressed++,
            actions: [
              FwIconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('Dashboard'), findsOneWidget);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump();
      expect(menuPressed, 1);
    });

    testWidgets('narrow width swaps in compact actions', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: FwNavbar(
              title: 'Dashboard',
              actions: [
                FwIconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
                FwIconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Help',
                  onPressed: () {},
                ),
              ],
              compactActions: [
                FwIconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byTooltip('More'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsNothing);
    });
  });

  group('FwSidebar', () {
    testWidgets('selecting a destination reports its id', (tester) async {
      var selected = 'home';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              height: 600,
              child: FwSidebar(
                destinations: testDestinations(),
                selectedId: selected,
                onDestinationSelected: (id) => setState(() => selected = id),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(selected, 'search');
      // Disabled destination does not select.
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(selected, 'search');
    });

    testWidgets('collapsed sidebar labels icons with tooltips', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 600,
            child: FwSidebar(
              destinations: testDestinations(),
              selectedId: 'home',
              onDestinationSelected: (_) {},
              expanded: false,
            ),
          ),
        ),
      );
      // Labels hidden, tooltips present.
      expect(find.text('Home'), findsNothing);
      expect(find.byTooltip('Home'), findsWidgets);
    });

    testWidgets('selected destination exposes selected semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 600,
            child: FwSidebar(
              destinations: testDestinations(),
              selectedId: 'search',
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      // The Semantics node wrapping the selected tile carries isSelected.
      final selectedNode = find.ancestor(
        of: find.text('Search'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false),
        ),
      );
      expect(selectedNode, findsOneWidget);
      // A non-selected tile is not marked selected.
      final otherNode = find.ancestor(
        of: find.text('Home'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false),
        ),
      );
      expect(otherNode, findsNothing);
    });

    testWidgets('nested destinations expand inline', (tester) async {
      const nested = FwDestination(
        id: 'reports',
        label: 'Reports',
        icon: Icon(Icons.bar_chart_outlined),
        children: [
          FwDestination(
            id: 'weekly',
            label: 'Weekly',
            icon: Icon(Icons.calendar_view_week_outlined),
          ),
        ],
      );
      var selected = '';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              height: 600,
              child: FwSidebar(
                destinations: const [nested],
                selectedId: selected,
                onDestinationSelected: (id) => setState(() => selected = id),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Weekly'), findsOneWidget);
      await tester.tap(find.text('Weekly'));
      await tester.pump();
      expect(selected, 'weekly');
    });
  });

  group('FwBreadcrumb', () {
    List<FwBreadcrumbItem> crumbs({void Function()? onTap}) => [
      FwBreadcrumbItem(label: 'Home', onTap: onTap),
      FwBreadcrumbItem(label: 'Projects', onTap: onTap),
      const FwBreadcrumbItem(label: 'Apollo'),
    ];

    testWidgets('tapping a crumb navigates; current page is marked', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(FwBreadcrumb(items: crumbs(onTap: () => taps++))),
        );
        await tester.tap(find.text('Projects'));
        await tester.pump();
        expect(taps, 1);
        final semantics = tester.getSemantics(find.text('Apollo'));
        expect(semantics.label, contains('current page'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('narrow width collapses ancestors into a menu', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: FwBreadcrumb(
              items: const [
                FwBreadcrumbItem(label: 'Home'),
                FwBreadcrumbItem(label: 'Projects'),
                FwBreadcrumbItem(label: 'Team'),
                FwBreadcrumbItem(label: 'Apollo'),
              ],
            ),
          ),
        ),
      );
      // Only the middle ancestor collapses; the last two crumbs stay visible.
      expect(find.text('Projects'), findsNothing);
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('Apollo'), findsOneWidget);
      await tester.tap(find.byTooltip('Show collapsed pages'));
      await tester.pumpAndSettle();
      expect(find.text('Projects'), findsOneWidget);
    });
  });

  group('FwNavigationState', () {
    test('select notifies once per change', () {
      final state = FwNavigationState(selectedId: 'a');
      var notifications = 0;
      state.addListener(() => notifications++);
      state.select('b');
      expect(state.selectedId, 'b');
      expect(notifications, 1);
      state.select('b');
      expect(notifications, 1, reason: 'same id does not notify');
    });
  });
  _navigationCompletionTests();
}

void _navigationCompletionTests() {
  group('FwPagination', () {
    testWidgets('page buttons report the page; nav respects bounds', (
      tester,
    ) async {
      var page = 1;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwPagination(
              page: page,
              pageCount: 10,
              onPageChanged: (p) => setState(() => page = p),
            ),
          ),
        ),
      );
      // Previous/First disabled on page 1.
      final prev = find.widgetWithIcon(FwIconButton, Icons.chevron_left);
      expect(tester.widget<FwIconButton>(prev).onPressed, isNull);
      await tester.tap(find.widgetWithIcon(FwIconButton, Icons.chevron_right));
      await tester.pump();
      expect(page, 2);
      // Ellipsis appears for 10 pages.
      expect(find.text('…'), findsOneWidget);
    });

    testWidgets('first/last jump to the ends', (tester) async {
      var page = 5;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwPagination(
              page: page,
              pageCount: 10,
              onPageChanged: (p) => setState(() => page = p),
            ),
          ),
        ),
      );
      await tester.tap(find.widgetWithIcon(FwIconButton, Icons.last_page));
      await tester.pump();
      expect(page, 10);
      await tester.tap(find.widgetWithIcon(FwIconButton, Icons.first_page));
      await tester.pump();
      expect(page, 1);
    });
  });

  group('FwStepper', () {
    List<FwStepData> steps() => const [
      FwStepData(label: 'Account'),
      FwStepData(label: 'Profile', optional: true),
      FwStepData(label: 'Review'),
    ];

    testWidgets('continue advances; back retreats; skip skips optional', (
      tester,
    ) async {
      var step = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwStepper(
              steps: steps(),
              currentStep: step,
              onStepChanged: (i) => setState(() => step = i),
            ),
          ),
        ),
      );
      // Step 0 (Account) is required: no Skip. Advance to the optional step.
      expect(find.text('Skip'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(step, 1);
      // Optional step shows Skip.
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(step, 2);
      // Last step shows Finish, no Skip.
      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(step, 1);
    });

    testWidgets('validation gate blocks continue', (tester) async {
      var step = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwStepper(
              steps: steps(),
              currentStep: step,
              onStepChanged: (i) => setState(() => step = i),
              onStepContinue: (_) async => false,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(step, 0, reason: 'gate returned false');
    });

    testWidgets('tapping a step header jumps directly', (tester) async {
      var step = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwStepper(
              steps: steps(),
              currentStep: step,
              onStepChanged: (i) => setState(() => step = i),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pump();
      expect(step, 2);
    });
  });

  group('FwBottomNavigation', () {
    testWidgets('selects destination; badge shows; disabled ignored', (
      tester,
    ) async {
      var selected = 'home';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwBottomNavigation(
              destinations: testDestinations(),
              selectedId: selected,
              onDestinationSelected: (id) => setState(() => selected = id),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget); // badge
      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(selected, 'search');
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(selected, 'search', reason: 'disabled not selectable');
    });

    testWidgets('selected item exposes selected semantics', (tester) async {
      await tester.pumpWidget(
        host(
          FwBottomNavigation(
            destinations: testDestinations(),
            selectedId: 'home',
            onDestinationSelected: (_) {},
          ),
        ),
      );
      final node = find.ancestor(
        of: find.text('Home'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false),
        ),
      );
      expect(node, findsOneWidget);
    });
  });

  group('FwNavigationRail', () {
    testWidgets('selects destination; labels toggle to tooltips', (
      tester,
    ) async {
      var selected = 'home';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              height: 600,
              child: FwNavigationRail(
                destinations: testDestinations(),
                selectedId: selected,
                onDestinationSelected: (id) => setState(() => selected = id),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(selected, 'search');
    });

    testWidgets('hidden labels surface as tooltips', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 600,
            child: FwNavigationRail(
              destinations: testDestinations(),
              selectedId: 'home',
              onDestinationSelected: (_) {},
              showLabels: false,
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsNothing);
      expect(find.byTooltip('Home'), findsOneWidget);
    });
  });
}
