/// Marketing pilot: a marketing/content page built ONLY on public fw exports.
///
/// Exercises: FwText roles, FwCarousel, FwCard, FwAccordion, FwButton
/// intents/variants, FwAutoGrid, FwBadge, responsive hero.
import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

void main() => runApp(const MarketingPilotApp());

class MarketingPilotApp extends StatelessWidget {
  const MarketingPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Marketing pilot',
      theme: FwTheme.light().toThemeData(),
      home: const FwViewportQuery(child: MarketingPage()),
    );
  }
}

class MarketingPage extends StatelessWidget {
  const MarketingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acme'),
        actions: [
          FwButton(label: 'Sign in', variant: FwButtonVariant.ghost, onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: FwVStack(
          gap: FwSpace.s10,
          children: [
            _hero(context),
            _logos(),
            _features(context),
            _testimonials(),
            _pricing(context),
            _faq(),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: FwInsets.token(FwSpace.s10).resolve(context),
      child: FwResponsiveBuilder(
        builder: (context, width, breakpoint) {
          final copy = FwVStack(
            gap: FwSpace.s4,
            children: [
              const FwBadge(label: 'New: 2.0 is here'),
              FwText('Ship beautiful apps faster', role: FwTextRole.displayLg, heading: true),
              FwText(
                'The responsive component system with typed tokens, '
                'theme presets, and accessibility baked in.',
                role: FwTextRole.lead,
              ),
              FwWrap(
                gap: FwSpace.s3,
                children: [
                  FwButton(label: 'Get started', intent: FwIntent.primary, onPressed: () {}),
                  FwButton(label: 'View docs', variant: FwButtonVariant.outline, onPressed: () {}),
                ],
              ),
            ],
          );
          if (width < 720) return copy;
          return FwHStack(
            gap: FwSpace.s10,
            children: [
              Expanded(child: copy),
              const Expanded(
                child: FwCard(
                  content: AspectRatio(aspectRatio: 16 / 9, child: Placeholder()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _logos() {
    return FwWrap(
      alignment: WrapAlignment.center,
      gap: FwSpace.s6,
      children: const [
        FwChip(label: 'Globex'),
        FwChip(label: 'Initech'),
        FwChip(label: 'Umbrella'),
        FwChip(label: 'Hooli'),
      ],
    );
  }

  Widget _features(BuildContext context) {
    return Padding(
      padding: FwInsets.token(FwSpace.s6).resolve(context),
      child: FwVStack(
        gap: FwSpace.s4,
        children: [
          FwText('Everything you need', role: FwTextRole.h1, heading: true),
          FwAutoGrid(
            minItemWidth: 220,
            gap: FwSpace.s4,
            children: const [
              FwCard(
                content: FwVStack(gap: FwSpace.s2, children: [
                  FwText('Typed tokens', role: FwTextRole.h3),
                  FwText('Spacing, color, type, motion — all typed.', role: FwTextRole.bodySm),
                ]),
              ),
              FwCard(
                content: FwVStack(gap: FwSpace.s2, children: [
                  FwText('Theme presets', role: FwTextRole.h3),
                  FwText('Ocean, Forest, Sunset, Monochrome.', role: FwTextRole.bodySm),
                ]),
              ),
              FwCard(
                content: FwVStack(gap: FwSpace.s2, children: [
                  FwText('Accessible', role: FwTextRole.h3),
                  FwText('Contrast floors, focus rings, semantics.', role: FwTextRole.bodySm),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _testimonials() {
    return FwCarousel(
      itemCount: 3,
      itemBuilder: (context, index) {
        const quotes = [
          'Cut our UI build time in half.',
          'The token system just clicks.',
          'Accessibility out of the box.',
        ];
        return FwCard(
          content: Center(
            child: FwText(quotes[index], role: FwTextRole.h3, textAlign: TextAlign.center),
          ),
        );
      },
    );
  }

  Widget _pricing(BuildContext context) {
    return Padding(
      padding: FwInsets.token(FwSpace.s6).resolve(context),
      child: FwVStack(
        gap: FwSpace.s4,
        children: [
          FwText('Pricing', role: FwTextRole.h1, heading: true),
          FwAutoGrid(
            minItemWidth: 220,
            gap: FwSpace.s4,
            children: [
              const FwCard(
                content: FwVStack(gap: FwSpace.s2, children: [
                  FwText('Starter', role: FwTextRole.h3),
                  FwText('\$0', role: FwTextRole.displaySm),
                  FwText('For side projects.', role: FwTextRole.bodySm),
                ]),
              ),
              FwCard(
                content: FwVStack(
                  gap: FwSpace.s2,
                  children: [
                    const FwBadge(label: 'Popular'),
                    FwText('Pro', role: FwTextRole.h3),
                    FwText('\$12/mo', role: FwTextRole.displaySm),
                    FwText('For teams shipping fast.', role: FwTextRole.bodySm),
                    FwButton(label: 'Choose Pro', intent: FwIntent.primary, onPressed: () {}),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faq() {
    return const _Faq();
  }

  Widget _footer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: FwInsets.token(FwSpace.s6).resolve(context),
      child: FwText('© 2026 Acme Corp', role: FwTextRole.caption, textAlign: TextAlign.center),
    );
  }
}

/// FAQ accordion with controlled open state.
class _Faq extends StatefulWidget {
  const _Faq();

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  Set<String> _open = {};

  @override
  Widget build(BuildContext context) {
    return FwAccordion(
      openIds: _open,
      onOpenChanged: (ids) => setState(() => _open = ids),
      items: const [
        FwAccordionItem(
          id: 'q1',
          header: Text('Is it really free for starters?'),
          body: Text('Yes — the Starter tier is free forever.'),
        ),
        FwAccordionItem(
          id: 'q2',
          header: Text('Can I theme it to my brand?'),
          body: Text('Seed presets or full token overrides — your call.'),
        ),
      ],
    );
  }
}
