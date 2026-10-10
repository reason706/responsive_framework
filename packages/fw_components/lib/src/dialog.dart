import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';

/// Why an overlay closed. Route dismissal returns typed result data, not
/// application effects: callers branch on [FwOverlayResult.reason].
enum FwDismissReason {
  /// Closed through [FwDialog.close] with an explicit value.
  action,

  /// Dismissed by tapping the modal barrier.
  barrier,

  /// Dismissed by the system back button or the Escape key.
  systemBack,

  /// Dismissed by a swipe gesture (sheets).
  swipe,

  /// Dismissed programmatically ([FwDialog.dismiss] or a bare
  /// `Navigator.pop`).
  programmatic,
}

/// Typed result of a dismissed overlay: the value plus why it closed.
///
/// A null [value] with reason [FwDismissReason.barrier],
/// [FwDismissReason.systemBack], [FwDismissReason.swipe], or
/// [FwDismissReason.programmatic] means the user cancelled; only
/// [FwDismissReason.action] carries a caller-supplied value.
@immutable
class FwOverlayResult<T> {
  const FwOverlayResult({this.value, required this.reason});

  final T? value;
  final FwDismissReason reason;
}

/// Dialog sizes (O01). Widths are maximums; the dialog shrinks to fit
/// narrow windows and goes fullscreen on phones at [full].
enum FwDialogSize {
  /// Compact: confirmations, small forms. Max 320dp.
  sm(320),

  /// Default: most dialogs. Max 480dp.
  md(480),

  /// Wide: rich content, tables. Max 640dp.
  lg(640),

  /// Fullscreen dialog, used for phone adaptation.
  full(double.infinity);

  const FwDialogSize(this.maxWidth);

  /// Maximum dialog width in dp.
  final double maxWidth;
}

/// Reason attribution scope, internal to the dialog/sheet route builders.
class _ReasonScope extends InheritedWidget {
  const _ReasonScope({required this.setReason, required super.child});

  final ValueSetter<FwDismissReason> setReason;

  static _ReasonScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ReasonScope>();
    assert(scope != null, 'FwDialog helpers must run inside a dialog route');
    return scope!;
  }

  @override
  bool updateShouldNotify(_ReasonScope oldWidget) => false;
}

/// Process-lifetime unlocked notifier for dialogs without a lock source.
final _unlocked = ValueNotifier<bool>(false);

/// Dialog (O01): modal dialog with title/content/actions slots.
///
/// Built on `showDialog`, so focus is contained in the route, the barrier
/// blocks pointer interaction behind it, and the route is labelled for
/// screen readers. Dismissal always returns an [FwOverlayResult] naming
/// the [FwDismissReason]; the barrier is drawn by the framework (not the
/// native one) so barrier taps are attributable.
///
/// Sizes: [FwDialogSize.sm]/[md]/[lg] cap the width; [FwDialogSize.full]
/// fills the window on phones. Content scrolls when [scrollable] and the
/// window is short. Actions lay out in a wrapping row that never
/// overflows narrow widths.
class FwDialog extends StatelessWidget {
  const FwDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.size = FwDialogSize.md,
    this.scrollable = true,
    this.elevation = 3,
    this.tonal = true,
  }) : assert(
         elevation >= 0 && elevation <= 5,
         'elevation must be an FwElevation level 0–5',
       );

  /// Optional title, announced as the dialog heading.
  final Widget? title;

  /// Main content.
  final Widget content;

  /// Action row. Use [FwButton]s; close them with
  /// `FwDialog.close(context, value)`.
  final List<Widget>? actions;

  final FwDialogSize size;
  final bool scrollable;

  /// Elevation level 0–5. M3-correct default is 3.
  final int elevation;

  /// Whether the M3 surface tint applies at [elevation].
  final bool tonal;

  /// Shows a dialog and completes with a typed [FwOverlayResult].
  ///
  /// [barrierDismissible] draws a tappable barrier that dismisses with
  /// reason [FwDismissReason.barrier]. The Escape key and system back
  /// dismiss with [FwDismissReason.systemBack] unless [dismissLocked] is
  /// true (used by busy confirmation dialogs). Pass [theme] to scope a
  /// local theme to the dialog.
  static Future<FwOverlayResult<T>> show<T>({
    required BuildContext context,
    Widget? title,
    required Widget content,
    List<Widget>? actions,
    FwDialogSize size = FwDialogSize.md,
    bool scrollable = true,
    bool barrierDismissible = true,
    ValueListenable<bool>? dismissLocked,
    FwTheme? theme,
    String? barrierLabel,
    RouteSettings? routeSettings,
    int elevation = 3,
    bool tonal = true,
  }) {
    final locked = dismissLocked ?? _unlocked;
    return showDialog<FwOverlayResult<T>>(
      context: context,
      // The native barrier is disabled: the framework draws its own so
      // barrier taps are attributable to FwDismissReason.barrier.
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: barrierLabel ?? 'Dismiss',
      routeSettings: routeSettings,
      builder: (dialogContext) {
        // Overlays are new routes: they cannot see the page's responsive
        // scope, so the framework propagates a viewport-based one. Theme
        // propagates through the app's inherited theme as usual.
        Widget route = FwViewportQuery(
          child: _ReasonScope(
            setReason: (_) {},
            child: _DialogRoute<T>(
              title: title,
              content: content,
              actions: actions,
              size: size,
              scrollable: scrollable,
              barrierDismissible: barrierDismissible,
              dismissLocked: locked,
              elevation: elevation,
              tonal: tonal,
            ),
          ),
        );
        if (theme != null) {
          route = FwThemeScope(theme: theme, child: route);
        }
        return route;
      },
    ).then(
      (result) =>
          result ?? FwOverlayResult<T>(reason: FwDismissReason.systemBack),
    );
  }

  /// Closes the dialog with [value] and reason [FwDismissReason.action].
  static void close<T>(BuildContext context, [T? value]) {
    _ReasonScope.of(context).setReason(FwDismissReason.action);
    Navigator.of(
      context,
    ).pop(FwOverlayResult<T>(value: value, reason: FwDismissReason.action));
  }

  /// Dismisses the dialog without a value ([FwDismissReason.programmatic]).
  static void dismiss(BuildContext context) {
    _ReasonScope.of(context).setReason(FwDismissReason.programmatic);
    Navigator.of(
      context,
    ).pop(const FwOverlayResult(reason: FwDismissReason.programmatic));
  }

  @override
  Widget build(BuildContext context) {
    // FwDialog is a configuration host; the route builder does the work.
    // A bare widget still renders the card for embedding/testing.
    return _DialogCard(
      title: title,
      content: content,
      actions: actions,
      size: size,
      scrollable: scrollable,
      elevation: elevation,
      tonal: tonal,
    );
  }
}

/// Internal route content: barrier, Escape handling, pop attribution, card.
class _DialogRoute<T> extends StatelessWidget {
  const _DialogRoute({
    required this.title,
    required this.content,
    required this.actions,
    required this.size,
    required this.scrollable,
    required this.barrierDismissible,
    required this.dismissLocked,
    required this.elevation,
    required this.tonal,
  });

  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final FwDialogSize size;
  final bool scrollable;
  final bool barrierDismissible;
  final ValueListenable<bool> dismissLocked;
  final int elevation;
  final bool tonal;

  void _barrierTap(BuildContext context) {
    if (!dismissLocked.value) {
      _ReasonScope.of(context).setReason(FwDismissReason.barrier);
      Navigator.of(
        context,
      ).pop(FwOverlayResult<T>(reason: FwDismissReason.barrier));
    }
  }

  KeyEventResult _handleKey(BuildContext context, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        !dismissLocked.value) {
      _ReasonScope.of(context).setReason(FwDismissReason.systemBack);
      Navigator.of(
        context,
      ).pop(FwOverlayResult<T>(reason: FwDismissReason.systemBack));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    return ValueListenableBuilder<bool>(
      valueListenable: dismissLocked,
      builder: (context, locked, _) => PopScope(
        // While locked (busy confirmation), back/Escape cannot dismiss.
        canPop: !locked,
        onPopInvokedWithResult: (didPop, result) {
          // A pop the helpers did not attribute is the system back button.
          if (didPop && result == null) {
            _ReasonScope.of(context).setReason(FwDismissReason.systemBack);
          }
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleKey(context, event),
          child: Stack(
            children: [
              // Attributable barrier.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: barrierDismissible ? () => _barrierTap(context) : null,
                  child: ColoredBox(
                    color: colors.of(FwColorRole.scrim).withValues(alpha: 0.32),
                  ),
                ),
              ),
              // Screen-reader labelled route.
              Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                child: _DialogCard(
                  title: title,
                  content: content,
                  actions: actions,
                  size: size,
                  scrollable: scrollable,
                  elevation: elevation,
                  tonal: tonal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dialog card: elevation, shape, title/content/actions layout.
class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.title,
    required this.content,
    required this.actions,
    required this.size,
    required this.scrollable,
    required this.elevation,
    required this.tonal,
  });

  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final FwDialogSize size;
  final bool scrollable;
  final int elevation;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final s = theme.spaceScale;
    final full = size == FwDialogSize.full;

    final card = Container(
      constraints: BoxConstraints(
        maxWidth: full ? double.infinity : size.maxWidth,
        maxHeight: full
            ? double.infinity
            : MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const FwElevation()
          .decoration(
            context,
            elevation,
            tonal: tonal,
            color: colors.of(FwColorRole.surfaceContainerHigh),
          )
          .copyWith(
            borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.lg)),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                s.of(FwSpace.s6, context),
                s.of(FwSpace.s6, context),
                s.of(FwSpace.s6, context),
                s.of(FwSpace.s2, context),
              ),
              child: Semantics(
                header: true,
                child: DefaultTextStyle(
                  style: typeScale.resolve(FwTextRole.h4, context),
                  child: title!,
                ),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              physics: scrollable
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              padding: EdgeInsetsDirectional.only(
                start: s.of(FwSpace.s6, context),
                end: s.of(FwSpace.s6, context),
                bottom: actions == null
                    ? s.of(FwSpace.s6, context)
                    : s.of(FwSpace.s2, context),
              ),
              child: DefaultTextStyle(
                style: typeScale.resolve(FwTextRole.body, context),
                child: content,
              ),
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.all(s.of(FwSpace.s4, context)),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: s.of(FwSpace.s2, context),
                runSpacing: s.of(FwSpace.s2, context),
                children: actions!,
              ),
            ),
        ],
      ),
    );

    if (full) {
      return SafeArea(child: card);
    }
    // Centered with the Dialog insets; the card scrolls internally.
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(s.of(FwSpace.s6, context)),
        child: card,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirmation dialog (O02).
// ---------------------------------------------------------------------------

/// Confirmation dialog (O02): [FwDialog] composition for confirm/cancel.
///
/// The caller performs the operation; this widget only collects the
/// decision. While [busy], the confirm action shows a loading state and
/// barrier/back/Escape dismissal is locked — the caller must resolve the
/// operation and close explicitly. Destructive confirmations get
/// [FwIntent.danger] styling and initial focus stays on the safe action.
class FwConfirmDialog extends StatelessWidget {
  const FwConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.busy = false,
    this.initialFocusConfirm = false,
  });

  /// Shows the confirmation and completes with the typed result.
  ///
  /// Returns `true` for confirm, `false` for cancel, null when dismissed
  /// without a decision (barrier/back — never while [busy]).
  static Future<FwOverlayResult<bool>> show({
    required BuildContext context,
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    ValueListenable<bool>? busy,
    bool barrierDismissible = true,
    FwTheme? theme,
  }) {
    final busyListenable = busy ?? ValueNotifier<bool>(false);
    return FwDialog.show<bool>(
      context: context,
      size: FwDialogSize.sm,
      barrierDismissible: barrierDismissible,
      dismissLocked: busyListenable,
      theme: theme,
      title: Text(title),
      content: ValueListenableBuilder<bool>(
        valueListenable: busyListenable,
        builder: (context, isBusy, _) => FwConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: destructive,
          busy: isBusy,
        ),
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: busyListenable,
          builder: (context, isBusy, _) => FwButton(
            label: cancelLabel,
            variant: FwButtonVariant.ghost,
            onPressed: isBusy ? null : () => FwDialog.close(context, false),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: busyListenable,
          builder: (context, isBusy, _) => FwButton(
            label: confirmLabel,
            intent: destructive ? FwIntent.danger : FwIntent.primary,
            loading: isBusy,
            autofocus: !destructive,
            onPressed: () => FwDialog.close(context, true),
          ),
        ),
      ],
    );
  }

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final bool busy;
  final bool initialFocusConfirm;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Text(message!);
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet (O03, sheet part).
// ---------------------------------------------------------------------------

/// Bottom sheet (O03): modal or persistent sheet with drag handle and snap
/// points.
///
/// Modal sheets dismiss with [FwDismissReason.barrier] (barrier tap),
/// [FwDismissReason.swipe] (drag down), or [FwDismissReason.systemBack].
/// [snapPoints] are fractions of the window height; the sheet opens at the
/// first point and snaps between them while dragging. Content gets safe-area
/// padding and keyboard insets.
class FwSheet extends StatelessWidget {
  const FwSheet({
    super.key,
    required this.content,
    this.title,
    this.showDragHandle = true,
    this.snapPoints = const [0.5],
    this.initialSnap = 0,
    this.elevation = 1,
    this.tonal = true,
  }) : assert(snapPoints.length > 0, 'snapPoints must not be empty'),
       assert(
         initialSnap >= 0 && initialSnap < snapPoints.length,
         'initialSnap must index snapPoints',
       );

  /// Shows a modal bottom sheet, completing with a typed result.
  static Future<FwOverlayResult<T>> showModal<T>({
    required BuildContext context,
    required Widget content,
    Widget? title,
    bool showDragHandle = true,
    List<double> snapPoints = const [0.5],
    int initialSnap = 0,
    bool isDismissible = true,
    bool enableDrag = true,
    FwTheme? theme,
    RouteSettings? routeSettings,
    int elevation = 1,
    bool tonal = true,
  }) {
    FwDismissReason? attributed;
    return showModalBottomSheet<FwOverlayResult<T>>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      routeSettings: routeSettings,
      backgroundColor: Colors.transparent,
      barrierLabel: 'Dismiss',
      builder: (sheetContext) {
        // Same route-scope propagation as dialogs: viewport metrics.
        Widget sheet = FwViewportQuery(
          child: _ReasonScope(
            setReason: (r) => attributed = r,
            child: _SheetContent<T>(
              content: content,
              title: title,
              showDragHandle: showDragHandle,
              snapPoints: snapPoints,
              initialSnap: initialSnap,
              enableDrag: enableDrag,
              elevation: elevation,
              tonal: tonal,
            ),
          ),
        );
        if (theme != null) {
          sheet = FwThemeScope(theme: theme, child: sheet);
        }
        return sheet;
      },
    ).then(
      (result) =>
          result ??
          FwOverlayResult<T>(reason: attributed ?? FwDismissReason.barrier),
    );
  }

  /// Shows a persistent (modeless) sheet in the nearest Scaffold.
  static PersistentBottomSheetController showPersistent({
    required BuildContext context,
    required Widget content,
    Widget? title,
    bool showDragHandle = true,
    FwTheme? theme,
    int elevation = 1,
    bool tonal = true,
  }) {
    Widget sheet = _ReasonScope(
      setReason: (_) {},
      child: _SheetContent<void>(
        content: content,
        title: title,
        showDragHandle: showDragHandle,
        snapPoints: const [0.5],
        initialSnap: 0,
        enableDrag: false,
        persistent: true,
        elevation: elevation,
        tonal: tonal,
      ),
    );
    if (theme != null) {
      sheet = FwThemeScope(theme: theme, child: sheet);
    }
    return Scaffold.of(context).showBottomSheet((_) => sheet);
  }

  final Widget content;
  final Widget? title;
  final bool showDragHandle;
  final List<double> snapPoints;
  final int initialSnap;

  /// Elevation level 0–5. M3-correct default is 1.
  ///
  /// P3.1 (improvement-plan-2): sheets previously rendered at level 3;
  /// the M3 default is 1 — a visual change, noted in the changelog.
  final int elevation;

  /// Whether the M3 surface tint applies at [elevation].
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    // Configuration host; showModal/showPersistent do the work.
    return _SheetContent<void>(
      content: content,
      title: title,
      showDragHandle: showDragHandle,
      snapPoints: snapPoints,
      initialSnap: initialSnap,
      enableDrag: true,
      persistent: true,
      elevation: elevation,
      tonal: tonal,
    );
  }
}

/// Sheet surface: drag handle, title, snapping scrollable content.
class _SheetContent<T> extends StatelessWidget {
  const _SheetContent({
    required this.content,
    required this.title,
    required this.showDragHandle,
    required this.snapPoints,
    required this.initialSnap,
    required this.enableDrag,
    this.persistent = false,
    this.elevation = 1,
    this.tonal = true,
  });

  final Widget content;
  final Widget? title;
  final bool showDragHandle;
  final List<double> snapPoints;
  final int initialSnap;
  final bool enableDrag;
  final bool persistent;
  final int elevation;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final s = theme.spaceScale;

    final surface = Container(
      decoration: const FwElevation()
          .decoration(
            context,
            elevation,
            tonal: tonal,
            color: colors.of(FwColorRole.surfaceContainerHigh),
          )
          .copyWith(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(theme.radii.of(FwRadius.lg)),
            ),
          ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle)
              Center(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: s.of(FwSpace.s2, context),
                    bottom: s.of(FwSpace.s2, context),
                  ),
                  child: Semantics(
                    label: 'Drag handle',
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.of(FwColorRole.textMuted),
                        borderRadius: BorderRadius.circular(
                          theme.radii.of(FwRadius.pill),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (title != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  s.of(FwSpace.s6, context),
                  s.of(FwSpace.s2, context),
                  s.of(FwSpace.s6, context),
                  s.of(FwSpace.s2, context),
                ),
                child: Semantics(
                  header: true,
                  child: DefaultTextStyle(
                    style: typeScale.resolve(FwTextRole.h4, context),
                    child: title!,
                  ),
                ),
              ),
            Flexible(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: s.of(FwSpace.s6, context),
                  end: s.of(FwSpace.s6, context),
                  bottom: s.of(FwSpace.s6, context),
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );

    // Keyboard avoidance: the inset pads the sheet (or its scrollable) from
    // the outside, so fractional snap sizing measures the visible area.
    // Animated to follow the keyboard with a token duration.
    final avoidKeyboard = AnimatedPadding(
      duration: theme.motion.durationFor(context, FwMotionSpeed.fast),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: surface,
    );

    if (persistent || !enableDrag) return avoidKeyboard;

    return AnimatedPadding(
      duration: theme.motion.durationFor(context, FwMotionSpeed.fast),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: snapPoints[initialSnap],
        minChildSize: snapPoints.first * 0.5,
        // Full expansion allowed so tall content can still be reached.
        maxChildSize: 1.0,
        snap: true,
        snapSizes: snapPoints,
        expand: false,
        builder: (context, scrollController) => surface,
      ),
    );
  }
}
