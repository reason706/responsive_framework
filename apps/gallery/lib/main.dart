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
  double rootSize = 16;
  int actions = 0;

  @override
  Widget build(BuildContext context) {
    final seed = ocean ? const Color(0xFF006A80) : const Color(0xFF6750A4);
    final metrics = FwMetrics(rootSize: rootSize);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Framework foundation gallery',
      theme: FwTheme.fromSeed(
        seed: seed,
        brightness: Brightness.light,
        metrics: metrics,
      ).toThemeData(),
      darkTheme: FwTheme.fromSeed(
        seed: seed,
        brightness: Brightness.dark,
        metrics: metrics,
      ).toThemeData(),
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
                    Text('Root size: ${rootSize.round()} logical pixels'),
                    Slider(
                      key: const ValueKey('root-slider'),
                      value: rootSize,
                      min: 16,
                      max: 20,
                      divisions: 4,
                      label: '${rootSize.round()}',
                      onChanged: (value) => setState(() => rootSize = value),
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
                              const SizedBox(height: 24),
                              _DesignSystemCard(rootSize: rootSize),
                              const SizedBox(height: 24),
                              const _ScopeDemoCard(),
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

/// Design-system proof section for DS-01 through DS-05.
///
/// Shows typed root-relative lengths, responsive/fluid resolution, the
/// typography scale, and declared (unscaled) font sizes. The ambient
/// [TextScaler] — controlled by the text-scale slider — applies exactly
/// once at render time; spacing never multiplies by it.
class _DesignSystemCard extends StatelessWidget {
  const _DesignSystemCard({required this.rootSize});

  final double rootSize;

  @override
  Widget build(BuildContext context) {
    final typeScale = context.fwTheme.typeScale;
    const scale = FwSpaceScale();
    TextStyle role(FwTextRole r) => typeScale.resolve(r, context);
    Widget specimen(FwTextRole r) {
      final style = role(r);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '${r.name} · declared ${style.fontSize!.toStringAsFixed(1)}px',
          style: style,
        ),
      );
    }

    return FwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Design system · root ${rootSize.round()}px',
            style: role(FwTextRole.h2),
          ),
          const SizedBox(height: 8),
          specimen(FwTextRole.displaySm),
          specimen(FwTextRole.h1),
          specimen(FwTextRole.h3),
          specimen(FwTextRole.lead),
          specimen(FwTextRole.body),
          specimen(FwTextRole.bodySm),
          specimen(FwTextRole.caption),
          specimen(FwTextRole.label),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final s1 = scale.of(FwSpace.s1, context);
              final s4 = scale.of(FwSpace.s4, context);
              final s8 = scale.of(FwSpace.s8, context);
              final page = scale.resolveAlias(FwSpaceAlias.pageInset, context);
              final section = scale.resolveAlias(
                FwSpaceAlias.sectionGap,
                context,
              );
              return Text(
                'Spacing at root ${rootSize.round()}: '
                's1=${s1.toStringAsFixed(1)} '
                's4=${s4.toStringAsFixed(1)} '
                's8=${s8.toStringAsFixed(1)} · '
                'page inset=${page.toStringAsFixed(1)} '
                'section gap=${section.toStringAsFixed(1)}',
                style: role(FwTextRole.bodySm),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Font sizes above are declared values. The text-scale slider '
            'applies the system scaler once at render; spacing is unaffected.',
            style: role(FwTextRole.caption),
          ),
        ],
      ),
    );
  }
}

/// DS-08/DS-09 proof: a locally scoped (inverse) theme that propagates its
/// Material adapter to native primitives, plus shadow token specimens.
///
/// The scope changes colors only — root metrics are inherited, so `rem`
/// sizing inside the card matches the outer page.
class _ScopeDemoCard extends StatelessWidget {
  const _ScopeDemoCard();

  @override
  Widget build(BuildContext context) {
    return FwThemeScope(
      theme: context.fwTheme.copyWith(
        colors: FwColors(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF006A80),
            brightness: Brightness.dark,
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          final theme = context.fwTheme;
          final typeScale = theme.typeScale;
          Widget shadowBox(String label, List<BoxShadow> shadows) {
            return Expanded(
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.colors.scheme.surface,
                  borderRadius: BorderRadius.circular(
                    theme.radii.of(FwRadius.md),
                  ),
                  boxShadow: shadows,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: typeScale.resolve(FwTextRole.caption, context),
                ),
              ),
            );
          }

          return FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Scoped inverse surface',
                  style: typeScale.resolve(FwTextRole.h3, context),
                ),
                const SizedBox(height: 4),
                Text(
                  'This card lives in an FwThemeScope with dark colors. '
                  'Native Material widgets inside it use the scoped adapter, '
                  'and rem sizing is inherited unchanged '
                  '(card inset ${theme.borders.resolveHairline(context).toStringAsFixed(0)}px hairline).',
                  style: typeScale.resolve(FwTextRole.bodySm, context),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    shadowBox('sm', theme.shadows.sm),
                    shadowBox('md', theme.shadows.md),
                    shadowBox('lg', theme.shadows.lg),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Motion: ${theme.motion.medium.inMilliseconds}ms medium '
                  '(collapses under reduced motion).',
                  style: typeScale.resolve(FwTextRole.caption, context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
