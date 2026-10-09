import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';

/// One page in [FwOnboardingFlow].
@immutable
class FwOnboardingPage {
  const FwOnboardingPage({
    required this.title,
    required this.body,
    this.illustration,
    this.primaryActionLabel,
  });

  final String title;
  final String body;

  /// Optional illustration slot (icon, image, or branded art).
  final Widget? illustration;

  /// Per-page primary action label override; defaults to Next/Get started.
  final String? primaryActionLabel;
}

/// Onboarding / intro flow scaffold (+R01).
///
/// A controlled [PageView] with page indicators, Skip, and Next/Get started
/// actions. The application owns completion (persisting the "seen" flag is
/// app work); [onDone] and [onSkip] are the route-neutral contracts. The
/// current page is announced to screen readers on change.
class FwOnboardingFlow extends StatefulWidget {
  const FwOnboardingFlow({
    super.key,
    required this.pages,
    required this.onDone,
    this.onSkip,
    this.controller,
    this.showSkip = true,
    this.skipLabel = 'Skip',
    this.nextLabel = 'Next',
    this.doneLabel = 'Get started',
    this.allowSwipe = true,
  }) : assert(pages.length > 0);

  final List<FwOnboardingPage> pages;
  final VoidCallback onDone;
  final VoidCallback? onSkip;

  /// Caller-owned controller; created internally when null.
  final PageController? controller;
  final bool showSkip;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;
  final bool allowSwipe;

  @override
  State<FwOnboardingFlow> createState() => _FwOnboardingFlowState();
}

class _FwOnboardingFlowState extends State<FwOnboardingFlow> {
  late PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PageController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: context.fwTheme.motion.durationFor(
        context,
        FwMotionSpeed.medium,
      ),
      curve: context.fwTheme.motion.curveFor(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final last = _index == widget.pages.length - 1;
    final pageInset = theme.spaceScale.resolveAlias(
      FwSpaceAlias.pageInset,
      context,
    );
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: widget.showSkip && widget.onSkip != null && !last
                ? TextButton(
                    onPressed: widget.onSkip,
                    child: Text(widget.skipLabel),
                  )
                : const SizedBox(height: 48),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              physics: widget.allowSwipe
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.pages.length,
              itemBuilder: (context, i) {
                final page = widget.pages[i];
                return Semantics(
                  liveRegion: i == _index,
                  label:
                      '${page.title}, page ${i + 1} of ${widget.pages.length}',
                  // Centers short content; scrolls instead of overflowing
                  // at large text scales.
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(pageInset),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (page.illustration != null) ...[
                                page.illustration!,
                                SizedBox(
                                  height: theme.spaceScale.of(
                                    FwSpace.s6,
                                    context,
                                  ),
                                ),
                              ],
                              Text(
                                page.title,
                                style: theme.typeScale.resolve(
                                  FwTextRole.h2,
                                  context,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: theme.spaceScale.of(
                                  FwSpace.s3,
                                  context,
                                ),
                              ),
                              Text(
                                page.body,
                                style: theme.typeScale.resolve(
                                  FwTextRole.body,
                                  context,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Page ${_index + 1} of ${widget.pages.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.pages.length; i++)
                  AnimatedContainer(
                    duration: theme.motion.durationFor(
                      context,
                      FwMotionSpeed.fast,
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal: theme.spaceScale.of(FwSpace.s1, context),
                    ),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? theme.colors.of(FwColorRole.primary)
                          : theme.colors.of(FwColorRole.border),
                      borderRadius: BorderRadius.circular(theme.radii.md),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s4, context)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pageInset),
            child: FwButton(
              label: last
                  ? widget.doneLabel
                  : (widget.pages[_index].primaryActionLabel ??
                        widget.nextLabel),
              onPressed: last ? widget.onDone : () => _goTo(_index + 1),
            ),
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s4, context)),
        ],
      ),
    );
  }
}
