import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';
import 'package:fw_layout/fw_layout.dart';

Widget host(Widget child) => MaterialApp(
  theme: FwTheme.light().toThemeData(),
  home: Scaffold(body: FwViewportQuery(child: child)),
);

List<FwDestination> testDestinations() => const [
  FwDestination(id: 'home', label: 'Home', icon: Icon(Icons.home_outlined)),
  FwDestination(
    id: 'search',
    label: 'Search',
    icon: Icon(Icons.search_outlined),
  ),
  FwDestination(
    id: 'settings',
    label: 'Settings',
    icon: Icon(Icons.settings_outlined),
  ),
];

Map<String, Widget> testBodies() => {
  'home': const Center(child: Text('Home body')),
  'search': const Center(child: Text('Search body')),
  'settings': const Center(child: Text('Settings body')),
};

void main() {
  group('FwScrollArea', () {
    testWidgets('scrolls with a caller-owned controller', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          FwScrollArea(
            controller: controller,
            child: Column(
              children: [for (var i = 0; i < 50; i++) Text('Item $i')],
            ),
          ),
        ),
      );
      expect(controller.offset, 0);
      controller.jumpTo(100);
      await tester.pump();
      expect(controller.offset, 100);
    });

    testWidgets('hides the scrollbar on request', (tester) async {
      await tester.pumpWidget(
        host(const FwScrollArea(showScrollbar: false, child: Text('content'))),
      );
      expect(find.byType(Scrollbar), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });
  });

  group('FwAdaptiveScaffold', () {
    Future<void> pumpScaffold(
      WidgetTester tester, {
      required double width,
      String selectedId = 'home',
      ValueChanged<String>? onSelected,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var current = selectedId;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwAdaptiveScaffold(
              destinations: testDestinations(),
              selectedId: current,
              onDestinationSelected: (id) {
                setState(() => current = id);
                onSelected?.call(id);
              },
              bodies: testBodies(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('compact width uses bottom navigation', (tester) async {
      await pumpScaffold(tester, width: 400);
      expect(find.byType(FwBottomNavigation), findsOneWidget);
      expect(find.byType(FwNavigationRail), findsNothing);
      expect(find.byType(FwSidebar), findsNothing);
      expect(find.text('Home body'), findsOneWidget);
    });

    testWidgets('medium width uses the navigation rail', (tester) async {
      await pumpScaffold(tester, width: 800);
      expect(find.byType(FwNavigationRail), findsOneWidget);
      expect(find.byType(FwBottomNavigation), findsNothing);
      expect(find.byType(FwSidebar), findsNothing);
    });

    testWidgets('expanded width uses the sidebar', (tester) async {
      await pumpScaffold(tester, width: 1300);
      expect(find.byType(FwSidebar), findsOneWidget);
      expect(find.byType(FwBottomNavigation), findsNothing);
      expect(find.byType(FwNavigationRail), findsNothing);
    });

    testWidgets('selection is shared across surfaces', (tester) async {
      var selected = 'home';
      await pumpScaffold(tester, width: 400, onSelected: (id) => selected = id);
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(selected, 'search');
      expect(find.text('Search body'), findsOneWidget);
    });

    testWidgets('body state survives a width transition', (tester) async {
      const fieldKey = ValueKey('name-field');
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final bodies = {
        'home': Center(
          child: TextField(key: fieldKey, controller: controller),
        ),
        'search': const Center(child: Text('Search body')),
        'settings': const Center(child: Text('Settings body')),
      };
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        host(
          FwAdaptiveScaffold(
            destinations: testDestinations(),
            selectedId: 'home',
            onDestinationSelected: (_) {},
            bodies: bodies,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(fieldKey), 'typed');
      // Transition to expanded width.
      tester.view.physicalSize = const Size(1300, 800);
      await tester.pumpAndSettle();
      expect(find.byType(FwSidebar), findsOneWidget);
      expect(controller.text, 'typed');
    });
  });

  group('FwMasterDetail', () {
    Future<void> pumpMasterDetail(
      WidgetTester tester, {
      required double width,
      String? selectedId,
      ValueChanged<String?>? onSelected,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var current = selectedId;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FwMasterDetail(
              master: ListView(
                children: [
                  for (var i = 0; i < 5; i++)
                    ListTile(
                      title: Text('Item $i'),
                      onTap: () {
                        setState(() => current = 'item-$i');
                        onSelected?.call('item-$i');
                      },
                    ),
                ],
              ),
              detail: Center(child: Text('Detail: $current')),
              selectedId: current,
              onSelected: (id) {
                setState(() => current = id);
                onSelected?.call(id);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('wide shows master and detail side by side', (tester) async {
      await pumpMasterDetail(tester, width: 1000, selectedId: 'item-1');
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Detail: item-1'), findsOneWidget);
    });

    testWidgets('narrow shows detail full-screen; back returns', (
      tester,
    ) async {
      String? selected = 'item-2';
      await pumpMasterDetail(
        tester,
        width: 400,
        selectedId: selected,
        onSelected: (id) => selected = id,
      );
      expect(find.text('Detail: item-2'), findsOneWidget);
      expect(find.text('Item 0'), findsNothing);
      // System back pops to the master.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('narrow master tap opens the detail', (tester) async {
      await pumpMasterDetail(tester, width: 400);
      expect(find.text('Item 0'), findsOneWidget);
      await tester.tap(find.text('Item 3'));
      await tester.pumpAndSettle();
      expect(find.text('Detail: item-3'), findsOneWidget);
    });
  });

  group('FwSliverSection', () {
    testWidgets('list and grid modes render in a CustomScrollView', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          CustomScrollView(
            slivers: [
              const FwStickyHeader(child: Text('Section')),
              FwSliverSection(
                children: [for (var i = 0; i < 3; i++) Text('Row $i')],
              ),
              FwSliverSection(
                columns: 2,
                children: [for (var i = 0; i < 4; i++) Text('Cell $i')],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Section'), findsOneWidget);
      expect(find.text('Row 0'), findsOneWidget);
      expect(find.text('Cell 0'), findsOneWidget);
    });
  });
}
