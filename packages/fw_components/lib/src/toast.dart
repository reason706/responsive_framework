/// Phase 4 feedback: toast/snackbar service (B02).
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';

// ---------------------------------------------------------------------------
// Toast/snackbar (B02).
// ---------------------------------------------------------------------------

/// Severity of a toast; drives the leading icon and accent.
enum FwToastSeverity { info, success, warning, error }

/// Where the toast host positions toasts.
enum FwToastPlacement { top, bottom }

/// How a toast was dismissed.
enum FwToastDismissal { timeout, action, swipe, manual }

/// Result of [FwToast.show]: how the toast left the screen.
class FwToastResult {
  const FwToastResult(this.dismissal);

  final FwToastDismissal dismissal;
}

/// A toast/snackbar request.
///
/// Severity picks the icon and accent; [actionLabel]/[onAction] add an
/// action button (e.g. Undo). [duration] is the auto-dismiss timeout —
/// ignored when [persistent] is true. [dedupKey] collapses repeats: a new
/// toast with the same key replaces the showing/queued one instead of
/// queueing behind it.
class FwToast {
  const FwToast({
    required this.message,
    this.title,
    this.severity = FwToastSeverity.info,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
    this.persistent = false,
    this.dedupKey,
    this.placement,
  }) : assert(
         actionLabel == null || onAction != null,
         'actionLabel requires onAction.',
       );

  final String message;
  final String? title;
  final FwToastSeverity severity;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final bool persistent;
  final String? dedupKey;

  /// Overrides the host placement for this toast.
  final FwToastPlacement? placement;

  /// Context-free show: enqueues on the nearest mounted [FwToastHost].
  ///
  /// The returned future completes with how the toast was dismissed.
  static Future<FwToastResult> show(FwToast toast) {
    final host = _host;
    assert(
      host != null,
      'FwToast.show() called with no FwToastHost mounted. '
      'Wrap your app (e.g. in MaterialApp.builder) with FwToastHost.',
    );
    return host!.enqueue(toast);
  }

  /// Dismisses the currently showing toast, if any.
  static void dismissCurrent() =>
      _host?._dismissCurrent(FwToastDismissal.manual);

  static FwToastHostState? _host;
}

/// Host for [FwToast.show]: renders one toast at a time, queues the rest.
///
/// Place once, high in the tree — e.g. in [MaterialApp.builder]:
/// ```dart
/// MaterialApp(builder: (context, child) => FwToastHost(child: child!))
/// ```
/// Toasts never take focus; they announce via a live region.
class FwToastHost extends StatefulWidget {
  const FwToastHost({
    super.key,
    required this.child,
    this.placement = FwToastPlacement.bottom,
  });

  final Widget child;
  final FwToastPlacement placement;

  @override
  State<FwToastHost> createState() => FwToastHostState();
}

class _ToastEntry {
  _ToastEntry(this.toast) : completer = Completer<FwToastResult>();

  final FwToast toast;
  final Completer<FwToastResult> completer;
}

class FwToastHostState extends State<FwToastHost> {
  final Queue<_ToastEntry> _queue = Queue<_ToastEntry>();
  _ToastEntry? _current;
  Timer? _timer;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    assert(
      FwToast._host == null,
      'Only one FwToastHost may be mounted at a time.',
    );
    FwToast._host = this;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (FwToast._host == this) FwToast._host = null;
    // Complete any outstanding futures instead of stranding them.
    _current?.completer.complete(const FwToastResult(FwToastDismissal.manual));
    for (final entry in _queue) {
      entry.completer.complete(const FwToastResult(FwToastDismissal.manual));
    }
    _queue.clear();
    super.dispose();
  }

  /// Enqueues a toast. Returns a future completing on dismissal.
  Future<FwToastResult> enqueue(FwToast toast) {
    final entry = _ToastEntry(toast);
    // Dedup: replace the showing or queued entry with the same key.
    if (toast.dedupKey != null) {
      if (_current?.toast.dedupKey == toast.dedupKey) {
        _replaceCurrent(entry);
        return entry.completer.future;
      }
      final existing = _queue
          .where((e) => e.toast.dedupKey == toast.dedupKey)
          .toList();
      for (final e in existing) {
        _queue.remove(e);
        e.completer.complete(const FwToastResult(FwToastDismissal.manual));
      }
    }
    _queue.add(entry);
    _pumpQueue();
    return entry.completer.future;
  }

  void _replaceCurrent(_ToastEntry entry) {
    _timer?.cancel();
    _current?.completer.complete(const FwToastResult(FwToastDismissal.manual));
    _current = entry;
    _armTimer();
    setState(() {});
  }

  void _pumpQueue() {
    if (_current != null || _queue.isEmpty) return;
    _current = _queue.removeFirst();
    _armTimer();
    setState(() {});
  }

  void _armTimer() {
    _timer?.cancel();
    final toast = _current?.toast;
    if (toast == null || toast.persistent) return;
    // Under accessible navigation, give screen-reader users more time.
    final multiplier = MediaQuery.accessibleNavigationOf(context) ? 3 : 1;
    _timer = Timer(toast.duration * multiplier, () {
      if (!_hovering) _dismissCurrent(FwToastDismissal.timeout);
    });
  }

  void _dismissCurrent(FwToastDismissal dismissal) {
    final current = _current;
    if (current == null) return;
    _timer?.cancel();
    _current = null;
    setState(() {});
    current.completer.complete(FwToastResult(dismissal));
    // Show the next queued toast on the next frame so exit/enter don't
    // fight over the same layout pass.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pumpQueue());
  }

  void _onAction() {
    final toast = _current?.toast;
    if (toast?.onAction == null) return;
    toast!.onAction!();
    _dismissCurrent(FwToastDismissal.action);
  }

  @override
  Widget build(BuildContext context) {
    final entry = _current;
    final placement = entry?.toast.placement ?? widget.placement;
    return Stack(
      children: [
        // Fill: the Stack must size to its parent, not to a zero-sized child.
        Positioned.fill(child: widget.child),
        if (entry != null)
          PositionedDirectional(
            start: 16,
            end: 16,
            top: placement == FwToastPlacement.top ? 16 : null,
            bottom: placement == FwToastPlacement.bottom ? 16 : null,
            child: SafeArea(
              child: MouseRegion(
                onEnter: (_) => _hovering = true,
                onExit: (_) {
                  _hovering = false;
                  // If the timer fired while hovering, dismiss now.
                  _armTimer();
                },
                child: _ToastCard(
                  key: ValueKey(entry),
                  toast: entry.toast,
                  onAction: _onAction,
                  onSwipe: () => _dismissCurrent(FwToastDismissal.swipe),
                  onClose: () => _dismissCurrent(FwToastDismissal.manual),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The visible toast card: severity icon, message, action, close.
class _ToastCard extends StatelessWidget {
  const _ToastCard({
    super.key,
    required this.toast,
    required this.onAction,
    required this.onSwipe,
    required this.onClose,
  });

  final FwToast toast;
  final VoidCallback onAction;
  final VoidCallback onSwipe;
  final VoidCallback onClose;

  (IconData, FwColorRole) _severityStyle() => switch (toast.severity) {
    FwToastSeverity.info => (Icons.info_outline, FwColorRole.info),
    FwToastSeverity.success => (
      Icons.check_circle_outline,
      FwColorRole.success,
    ),
    FwToastSeverity.warning => (
      Icons.warning_amber_outlined,
      FwColorRole.warning,
    ),
    FwToastSeverity.error => (Icons.error_outline, FwColorRole.error),
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final (icon, role) = _severityStyle();
    // Live region: announced without stealing focus.
    return Semantics(
      liveRegion: true,
      child: Dismissible(
        key: ValueKey('dismiss-${toast.hashCode}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onSwipe(),
        child: Container(
          decoration: const FwElevation()
              .decoration(context, 3)
              .copyWith(
                color: colors.of(FwColorRole.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(
                  theme.radii.of(FwRadius.md),
                ),
              ),
          padding: EdgeInsetsDirectional.all(
            theme.spaceScale.of(FwSpace.s3, context),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.of(role)),
              SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (toast.title != null)
                      Text(
                        toast.title!,
                        style: typeScale.resolve(FwTextRole.label, context),
                      ),
                    Text(
                      toast.message,
                      style: typeScale.resolve(FwTextRole.bodySm, context),
                    ),
                  ],
                ),
              ),
              if (toast.actionLabel != null)
                FwButton(
                  label: toast.actionLabel!,
                  variant: FwButtonVariant.ghost,
                  onPressed: onAction,
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Dismiss',
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
