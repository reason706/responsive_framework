import 'package:flutter/material.dart';

void main() {
  runApp(const ResponsiveApp());
}

class ResponsiveApp extends StatelessWidget {
  const ResponsiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive Framework',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Responsive Framework')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 32 : 16),
                child: Flex(
                  key: const ValueKey('welcome-content'),
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices,
                      size: isWide ? 96 : 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(
                      width: isWide ? 32 : 0,
                      height: isWide ? 0 : 24,
                    ),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isWide
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome to Flutter',
                            textAlign: isWide
                                ? TextAlign.start
                                : TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'A simple app that adapts to your screen.',
                            textAlign: isWide
                                ? TextAlign.start
                                : TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
