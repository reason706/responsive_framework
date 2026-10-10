import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'dialog.dart';

// ---------------------------------------------------------------------------
// Side sheet (P4): side-anchored modal sheet.
// ---------------------------------------------------------------------------

/// Which edge the side sheet anchors to. Logical: [end] is the trailing
/// edge (right in LTR, left in RTL).
enum FwSideSheetSide { start, end }

/// Side sheet (P4): a modal sheet anchored to the leading or trailing
/// edge — the complement to the bottom sheet for wide layouts, detail
/// panels, and filters.
///
/// Presented with [FwSideSheet.showModal], which slides in from the side
/// (RTL-aware) over a dismissible scrim and completes with a typed
/// [FwOverlayResult]. Elevation follows P3.1 (default 1, tonal on).
///
/// Demand note: hosted-plan item (improvement-plan-2 §4 P4 slate).
class FwSideSheet {
  const FwSideSheet._();

  /// Shows a modal side sheet, completing with a typed result.
  static Future<FwOverlayResult<T>> showModal<T>({
    required BuildContext context,
    required Widget content,
    Widget? title,
    FwSideSheetSide side = FwSideSheetSide.end,
    double width = 360,
    bool isDismissible = true,
    int elevation = 1,
    bool tonal = true,
    FwTheme? theme,
    RouteSettings? routeSettings,
  }) {
    assert(width > 0, 'width must be positive');
    assert(
      elevation >= 0 && elevation <= 5,
      'elevation must be an FwElevation level 0–5',
    );
    FwDismissReason? attributed;
    return showGeneralDialog<FwOverlayResult<T>>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: 'Dismiss',
      routeSettings: routeSettings,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final dir = Directionality.of(dialogContext);
        final fromEnd = side == FwSideSheetSide.end;
        // Slide from the physical edge: end = right in LTR.
        final begin = switch ((fromEnd, dir == TextDirection.ltr)) {
          (true, true) || (false, false) => const Offset(1, 0),
          (true, false) || (false, true) => const Offset(-1, 0),
        };
        Widget sheet = SlideTransition(
          position: Tween(begin: begin, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: Align(
            alignment: switch ((fromEnd, dir == TextDirection.ltr)) {
              (true, true) || (false, false) => Alignment.centerRight,
              (true, false) || (false, true) => Alignment.centerLeft,
            },
            child: _SideSheetContent<T>(
              content: content,
              title: title,
              width: width,
              elevation: elevation,
              tonal: tonal,
              onClose: () {
                attributed = FwDismissReason.action;
                Navigator.of(
                  dialogContext,
                ).pop(FwOverlayResult<T>(reason: FwDismissReason.action));
              },
            ),
          ),
        );
        if (theme != null) {
          sheet = FwThemeScope(theme: theme, child: sheet);
        }
        // Viewport metrics propagate like the framework's other overlays.
        return FwViewportQuery(child: sheet);
      },
    ).then(
      (result) =>
          result ??
          FwOverlayResult<T>(reason: attributed ?? FwDismissReason.barrier),
    );
  }
}

class _SideSheetContent<T> extends StatelessWidget {
  const _SideSheetContent({
    required this.content,
    required this.title,
    required this.width,
    required this.elevation,
    required this.tonal,
    required this.onClose,
  });

  final Widget content;
  final Widget? title;
  final double width;
  final int elevation;
  final bool tonal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final s = theme.spaceScale;

    return Container(
      width: width,
      height: double.infinity,
      decoration: const FwElevation()
          .decoration(
            context,
            elevation,
            tonal: tonal,
            color: colors.of(FwColorRole.surface),
          )
          .copyWith(
            borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
          ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(s.of(FwSpace.s4, context)),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: DefaultTextStyle(
                        style: theme.typeScale.resolve(FwTextRole.h4, context),
                        child: title!,
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    iconSize: theme.iconSizes.of(FwIconSize.sm),
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  s.resolveAlias(FwSpaceAlias.overlayInset, context),
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
