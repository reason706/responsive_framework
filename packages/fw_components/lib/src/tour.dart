import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';

/// One stop on a guided tour.
class FwTourStep {
  const FwTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
  });

  /// Key on the widget this step points at.
  final GlobalKey targetKey;

  /// Card title.
  final String title;

  /// Card body.
  final String description;
}

/// State machine for [FwTour]: idle → stepping → done.
///
/// [index] is -1 while idle. [next] on the last step finishes the tour.
class FwTourController extends ChangeNotifier {
  FwTourController({required this.steps})
    : assert(steps.isNotEmpty, 'a tour needs at least one step');

  final List<FwTourStep> steps;

  int _index = -1;

  /// Whether a tour is running.
  bool get isActive => _index >= 0;

  /// Current step index (-1 while idle).
  int get index => _index;

  /// Current step, or null while idle.
  FwTourStep? get currentStep => isActive ? steps[_index] : null;

  /// Whether the current step is the last one.
  bool get isLast => isActive && _index == steps.length - 1;

  void start() {
    _index = 0;
    notifyListeners();
  }

  void next() {
    if (!isActive) return;
    if (isLast) {
      stop();
    } else {
      _index++;
      notifyListeners();
    }
  }

  void previous() {
    if (isActive && _index > 0) {
      _index--;
      notifyListeners();
    }
  }

  void stop() {
    if (isActive) {
      _index = -1;
      notifyListeners();
    }
  }
}

/// Guided tour / walkthrough overlay.
///
/// Wraps the app (or a subtree); when [controller] is active it dims the
/// screen with a spotlight cutout around the current step's target and shows
/// an anchored card with title, description, step dots, and Back/Next/Skip.
/// Tapping the scrim ends the tour.
///
/// The spotlight is instant (no animation), so reduced-motion needs no
/// special case. If a step's target is not laid out, the card centers on
/// screen instead of anchoring.
class FwTour extends StatefulWidget {
  const FwTour({
    super.key,
    required this.controller,
    required this.child,
    this.scrimOpacity = 0.6,
  });

  final FwTourController controller;
  final Widget child;
  final double scrimOpacity;

  @override
  State<FwTour> createState() => _FwTourState();
}

class _FwTourState extends State<FwTour> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTourChanged);
  }

  @override
  void didUpdateWidget(FwTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTourChanged);
      widget.controller.addListener(_onTourChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTourChanged);
    super.dispose();
  }

  void _onTourChanged() => setState(() {});

  /// Target bounds in this widget's local coordinates, or null.
  Rect? _targetRect() {
    final step = widget.controller.currentStep;
    if (step == null) return null;
    final targetContext = step.targetKey.currentContext;
    if (targetContext == null) return null;
    final box = targetContext.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.attached) return null;
    final topLeft = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
    return (topLeft & box.size).inflate(8);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.controller.isActive)
          _TourOverlay(
            controller: widget.controller,
            targetRect: _targetRect(),
            scrimOpacity: widget.scrimOpacity,
          ),
      ],
    );
  }
}

class _TourOverlay extends StatelessWidget {
  const _TourOverlay({
    required this.controller,
    required this.targetRect,
    required this.scrimOpacity,
  });

  final FwTourController controller;
  final Rect? targetRect;
  final double scrimOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final size = MediaQuery.sizeOf(context);
    final step = controller.currentStep!;

    final scrim = Color.fromRGBO(0, 0, 0, scrimOpacity);

    // Spotlight: four scrim rects leaving a hole around the target.
    List<Widget> scrimWidgets;
    if (targetRect == null) {
      scrimWidgets = [
        Positioned.fill(
          child: GestureDetector(
            onTap: controller.stop,
            child: Container(color: scrim),
          ),
        ),
      ];
    } else {
      final r = targetRect!;
      scrimWidgets = [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: r.top,
          child: _scrimTap(scrim, controller.stop),
        ),
        Positioned(
          left: 0,
          top: r.bottom,
          right: 0,
          bottom: 0,
          child: _scrimTap(scrim, controller.stop),
        ),
        Positioned(
          left: 0,
          top: r.top,
          width: r.left,
          height: r.height,
          child: _scrimTap(scrim, controller.stop),
        ),
        Positioned(
          left: r.right,
          top: r.top,
          right: 0,
          height: r.height,
          child: _scrimTap(scrim, controller.stop),
        ),
        // Highlight ring around the target.
        Positioned.fromRect(
          rect: r,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.of(FwColorRole.primary),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(
                  theme.radii.of(FwRadius.sm),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    // Card placement: below the target when it fits, else above, else
    // centered when there is no target.
    const cardWidth = 300.0;
    const cardMargin = 16.0;
    const gap = 12.0;
    final left = targetRect == null
        ? (size.width - cardWidth) / 2
        : (targetRect!.left).clamp(
            cardMargin,
            size.width - cardWidth - cardMargin,
          );
    Widget card = _TourCard(controller: controller, step: step);
    if (targetRect == null) {
      card = Positioned(
        left: left,
        top: (size.height - 220) / 2,
        width: cardWidth,
        child: card,
      );
    } else if (targetRect!.bottom + gap + 220 < size.height) {
      card = Positioned(
        left: left,
        top: targetRect!.bottom + gap,
        width: cardWidth,
        child: card,
      );
    } else {
      card = Positioned(
        left: left,
        bottom: size.height - targetRect!.top + gap,
        width: cardWidth,
        child: card,
      );
    }

    return Stack(children: [...scrimWidgets, card]);
  }

  Widget _scrimTap(Color scrim, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(color: scrim),
  );
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.controller, required this.step});

  final FwTourController controller;
  final FwTourStep step;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Tour step ${controller.index + 1} of ${controller.steps.length}',
      child: Container(
        decoration: BoxDecoration(
          color: colors.of(FwColorRole.surface),
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
          border: Border.all(color: colors.of(FwColorRole.border)),
          boxShadow: theme.shadows.lg,
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s4, context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: theme.typeScale.resolve(FwTextRole.h6, context),
              ),
              SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
              Text(
                step.description,
                style: theme.typeScale.resolve(FwTextRole.body, context),
              ),
              SizedBox(height: theme.spaceScale.of(FwSpace.s3, context)),
              // Step dots on their own row; actions wrap instead of
              // overflowing on narrow cards.
              Row(
                children: [
                  for (var i = 0; i < controller.steps.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsetsDirectional.only(
                        end: theme.spaceScale.resolveAlias(
                          FwSpaceAlias.hairlineGap,
                          context,
                        ),
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == controller.index
                            ? colors.of(FwColorRole.primary)
                            : colors.of(FwColorRole.border),
                      ),
                    ),
                ],
              ),
              SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: theme.spaceScale.of(FwSpace.s1, context),
                children: [
                  FwButton(
                    label: 'Skip',
                    variant: FwButtonVariant.ghost,
                    size: FwSize.sm,
                    onPressed: controller.stop,
                  ),
                  if (controller.index > 0)
                    FwButton(
                      label: 'Back',
                      variant: FwButtonVariant.ghost,
                      size: FwSize.sm,
                      onPressed: controller.previous,
                    ),
                  FwButton(
                    label: controller.isLast ? 'Done' : 'Next',
                    size: FwSize.sm,
                    onPressed: controller.next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
