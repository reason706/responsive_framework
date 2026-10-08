import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

void main() => runApp(const FwGallery());

/// Interactive foundation example; no persistence or backend is required.
class FwGallery extends StatefulWidget {
  const FwGallery({super.key});

  @override
  State<FwGallery> createState() => _FwGalleryState();
}

class _FwGalleryState extends State<FwGallery> {
  bool dark = false;
  bool rtl = false;
  bool ocean = false;
  double previewWidth = 960;
  double textScale = 1;
  int actions = 0;

  @override
  Widget build(BuildContext context) {
    final seed = ocean ? const Color(0xFF006A80) : const Color(0xFF6750A4);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Framework foundation gallery',
      theme: FwTheme.light(seed: seed).toThemeData(),
      darkTheme: FwTheme.dark(seed: seed).toThemeData(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Framework foundation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Shared tokens. Responsive layouts. Accessible controls.',
              ),
              const SizedBox(height: 16),
              FwCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const ValueKey('dark-toggle'),
                      title: const Text('Dark theme'),
                      value: dark,
                      onChanged: (value) => setState(() => dark = value),
                    ),
                    SwitchListTile(
                      key: const ValueKey('rtl-toggle'),
                      title: const Text('Right-to-left layout'),
                      value: rtl,
                      onChanged: (value) => setState(() => rtl = value),
                    ),
                    SwitchListTile(
                      key: const ValueKey('brand-toggle'),
                      title: const Text('Ocean brand'),
                      value: ocean,
                      onChanged: (value) => setState(() => ocean = value),
                    ),
                    Text('Requested preview width: ${previewWidth.round()}'),
                    Slider(
                      key: const ValueKey('width-slider'),
                      value: previewWidth,
                      min: 320,
                      max: 1440,
                      divisions: 56,
                      label: '${previewWidth.round()} logical pixels',
                      onChanged: (value) =>
                          setState(() => previewWidth = value),
                    ),
                    Text('Text scale: ${textScale.toStringAsFixed(1)}×'),
                    Slider(
                      key: const ValueKey('text-slider'),
                      value: textScale,
                      min: 1,
                      max: 2,
                      divisions: 10,
                      label: '${textScale.toStringAsFixed(1)}×',
                      onChanged: (value) => setState(() => textScale = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(previewWidth, constraints.maxWidth);
                  return Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: SizedBox(
                      width: width,
                      child: FwContainerQuery(
                        child: Builder(
                          builder: (context) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Actual width: ${width.round()} · '
                                'breakpoint: ${context.fwBreakpoint.name}',
                                key: const ValueKey('breakpoint-label'),
                              ),
                              const SizedBox(height: 16),
                              FwRow(
                                children: [
                                  for (final variant in FwButtonVariant.values)
                                    FwCol(
                                      key: ValueKey('column-${variant.name}'),
                                      span: const Responsive(
                                        base: 12,
                                        md: 6,
                                        lg: 4,
                                      ),
                                      child: FwCard(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              '${variant.name} button',
                                              style: context
                                                  .fwTheme
                                                  .typography
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'This card responds to its parent '
                                              'width and shares the active theme.',
                                            ),
                                            const SizedBox(height: 16),
                                            FwButton(
                                              key: ValueKey(
                                                'action-${variant.name}',
                                              ),
                                              label: 'Try ${variant.name}',
                                              variant: variant,
                                              onPressed: () =>
                                                  setState(() => actions++),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Actions completed: $actions',
                                key: const ValueKey('action-count'),
                              ),
                              const SizedBox(height: 16),
                              const FwButton(
                                label: 'Disabled button',
                                onPressed: null,
                              ),
                              const SizedBox(height: 8),
                              const FwButton(
                                label: 'Save',
                                loading: true,
                                loadingLabel: 'Saving…',
                                onPressed: null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
