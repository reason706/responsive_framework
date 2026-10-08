import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/main.dart';

void main() {
  testWidgets('shows the responsive welcome screen', (tester) async {
    await tester.pumpWidget(const ResponsiveApp());

    expect(find.text('Responsive Framework'), findsOneWidget);
    expect(find.text('Welcome to Flutter'), findsOneWidget);
    expect(
      find.text('A simple app that adapts to your screen.'),
      findsOneWidget,
    );
  });

  testWidgets('switches layout for wide screens', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(const ResponsiveApp());
    var content = tester.widget<Flex>(
      find.byKey(const ValueKey('welcome-content')),
    );
    expect(content.direction, Axis.vertical);

    await tester.binding.setSurfaceSize(const Size(900, 800));
    await tester.pump();
    content = tester.widget<Flex>(
      find.byKey(const ValueKey('welcome-content')),
    );
    expect(content.direction, Axis.horizontal);
  });
}
