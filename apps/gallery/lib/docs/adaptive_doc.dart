import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

import '../component_doc.dart';

/// Doc board for the adaptive (Cupertino) component family.
///
/// Registration (parent adds to catalog.dart — this file is deliberately
/// not wired in here so the catalog edit stays a separate reviewable step):
///
/// ```dart
/// import 'docs/adaptive_doc.dart';
/// // inside the catalog children list, e.g. under Molecules:
/// adaptiveDoc(),
/// ```
Widget adaptiveDoc() => const ComponentDoc(
  id: 'ADP',
  name: 'Adaptive (Cupertino) components',
  tier: 'Molecules',
  summary:
      'The adaptive pattern: FwPlatformOverride selects iOS vs Material '
      'rendering for a subtree, and FwAdaptive* widgets render Cupertino '
      'widgets on iOS and the framework components elsewhere. This is the '
      'down-payment on per-component iOS variants — the six highest-demand '
      'components ship here; the full 2.x roadmap is in docs/roadmap.md. '
      'Toggle the platform below to see both renderings live.',
  notFor:
      'pixel-perfect iOS clones of every component (2.x), or branching on '
      'defaultTargetPlatform directly in app code',
  anatomy: [
    AnatomyPart(
      'FwPlatformOverride',
      'InheritedWidget forcing iOS / android / system. The test driver.',
    ),
    AnatomyPart(
      'FwAdaptiveButton',
      'CupertinoButton(.filled) on iOS; FwButton solid/ghost elsewhere.',
    ),
    AnatomyPart(
      'FwAdaptiveSwitch',
      'CupertinoSwitch + label column on iOS; FwSwitch elsewhere.',
    ),
    AnatomyPart(
      'FwAdaptiveIndicator',
      'CupertinoActivityIndicator on iOS (always indeterminate); '
          'FwCircularProgress elsewhere.',
    ),
    AnatomyPart(
      'FwAdaptiveSlider',
      'CupertinoSlider with a rendered label on iOS; FwSlider elsewhere.',
    ),
    AnatomyPart(
      'FwAdaptiveDatePicker',
      'CupertinoDatePicker wheels (216dp) on iOS; FwCalendar grid elsewhere.',
    ),
    AnatomyPart(
      'FwAdaptiveDialog',
      'CupertinoAlertDialog / CupertinoActionSheet on iOS; FwDialog '
          'elsewhere. Futures complete with the tapped action value.',
    ),
  ],
  properties: _AdaptiveDemo(),
  layoutSpecs: [
    LayoutSpec('Date picker', 'iOS wheels need a fixed 216dp height.'),
    LayoutSpec('Indicator', 'diameter via size (default 36).'),
    LayoutSpec('Switch', 'label column expands; switch stays trailing.'),
    LayoutSpec('Dialogs', 'same action model both platforms; values typed.'),
  ],
  dos: [
    'Drive platform choice with FwPlatformOverride — never branch on '
        'defaultTargetPlatform in app code.',
    'Use FwPlatformOverride in widget tests to cover both renderings.',
    'Document every deliberate divergence (see each widget\'s docs).',
    'Prefer the adaptive widget when both platforms matter; use the '
        'framework widget directly when only Material matters.',
  ],
  donts: [
    'Don\'t assume Cupertino covers the whole app — this family covers '
        'six components; the rest is 2.x.',
    'Don\'t pass raw colors to match iOS — Cupertino widgets resolve '
        'their own semantic colors.',
  ],
  a11y: [
    'Labels stay visible on both platforms; switch access is unaffected '
        '(buttons remain ordinary tappable buttons).',
    'Dialogs announce titles; destructive actions keep their semantics.',
    'Long-press repeat and other pointer behaviors are iOS-independent.',
  ],
);

/// Live demo: platform toggle driving the adaptive family.
class _AdaptiveDemo extends StatefulWidget {
  const _AdaptiveDemo();

  @override
  State<_AdaptiveDemo> createState() => _AdaptiveDemoState();
}

class _AdaptiveDemoState extends State<_AdaptiveDemo> {
  FwPlatform _platform = FwPlatform.iOS;
  bool _switchValue = true;
  double _sliderValue = 0.4;
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return FwPlatformOverride(
      platform: _platform,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Platform:'),
              for (final platform in FwPlatform.values)
                ChoiceChip(
                  label: Text(platform.name),
                  selected: _platform == platform,
                  onSelected: (_) => setState(() => _platform = platform),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FwAdaptiveButton(
                label: 'Tapped $_taps',
                onPressed: () => setState(() => _taps++),
              ),
              const FwAdaptiveIndicator(),
              SizedBox(
                width: 220,
                child: FwAdaptiveSlider(
                  label: 'Volume',
                  value: _sliderValue,
                  onChanged: (v) => setState(() => _sliderValue = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            child: FwAdaptiveSwitch(
              label: 'Notifications',
              description: 'Push alerts',
              value: _switchValue,
              onChanged: (v) => setState(() => _switchValue = v),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FwAdaptiveButton(
                label: 'Show dialog',
                filled: false,
                onPressed: () => FwAdaptiveDialog.show<String>(
                  context: context,
                  title: 'Delete?',
                  content: const Text('This cannot be undone.'),
                  actions: const [
                    FwAdaptiveDialogAction(label: 'Cancel', value: 'cancel'),
                    FwAdaptiveDialogAction(
                      label: 'Delete',
                      value: 'delete',
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              FwAdaptiveButton(
                label: 'Show action sheet',
                filled: false,
                onPressed: () => FwAdaptiveDialog.showActionSheet<String>(
                  context: context,
                  title: 'Share',
                  actions: const [
                    FwAdaptiveDialogAction(label: 'Copy link', value: 'copy'),
                  ],
                  cancelLabel: 'Cancel',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FwAdaptiveDatePicker(
            selectedDate: DateTime(2026, 10, 10),
            onDateSelected: (_) {},
          ),
        ],
      ),
    );
  }
}
