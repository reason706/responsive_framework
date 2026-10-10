import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';

/// Phase of the [FwAsyncButton] state machine.
enum _Phase { idle, loading, success, error }

/// Button that runs an async action with a full state machine:
///
/// `idle → loading → success | error → (timed revert) → idle`.
///
/// The caller supplies the async [onPressed]; the button owns the
/// busy/success/error presentation. [successDuration] and [errorDuration]
/// control the timed revert back to idle; under reduced motion the revert
/// is instant. Haptic confirmation/error signals fire when [enableFeedback]
/// is true (skipped under accessible navigation, like all [FwHaptics]).
///
/// Success and error are announced through a live region. The button never
/// updates state after disposal.
class FwAsyncButton extends StatefulWidget {
  const FwAsyncButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FwButtonVariant.solid,
    this.intent = FwIntent.primary,
    this.size = FwSize.md,
    this.shape = FwShape.rounded,
    this.icon,
    this.iconPosition = FwIconPosition.start,
    this.iconGap,
    this.successDuration = const Duration(milliseconds: 1200),
    this.errorDuration = const Duration(milliseconds: 2000),
    this.successIcon,
    this.errorIcon,
    this.successLabel,
    this.errorLabel,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;

  /// The async action. Null disables the button.
  final Future<void> Function()? onPressed;

  final FwButtonVariant variant;
  final FwIntent intent;
  final FwSize size;
  final FwShape shape;
  final Widget? icon;
  final FwIconPosition iconPosition;
  final double? iconGap;

  /// How long the success/error presentation shows before reverting to
  /// idle. Zero disables the timed presentation (revert immediately).
  final Duration successDuration;
  final Duration errorDuration;

  /// Icons shown during the success/error phases. Defaults: check / error.
  final Widget? successIcon;
  final Widget? errorIcon;

  /// Labels shown during the success/error phases. Defaults to [label].
  final String? successLabel;
  final String? errorLabel;

  final bool enableFeedback;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<FwAsyncButton> createState() => _FwAsyncButtonState();
}

class _FwAsyncButtonState extends State<FwAsyncButton> {
  _Phase _phase = _Phase.idle;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  Duration _effective(Duration d, BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

  Future<void> _run() async {
    final action = widget.onPressed;
    if (action == null || _phase == _Phase.loading) return;
    _revertTimer?.cancel();
    setState(() => _phase = _Phase.loading);
    try {
      await action();
      if (!mounted) return;
      if (widget.enableFeedback) {
        context.fwTheme.haptics.confirm(context);
      }
      setState(() => _phase = _Phase.success);
      _scheduleRevert(_effective(widget.successDuration, context));
    } catch (_) {
      if (!mounted) return;
      if (widget.enableFeedback) {
        context.fwTheme.haptics.error(context);
      }
      setState(() => _phase = _Phase.error);
      _scheduleRevert(_effective(widget.errorDuration, context));
    }
  }

  void _scheduleRevert(Duration after) {
    _revertTimer?.cancel();
    if (after == Duration.zero) {
      if (mounted) setState(() => _phase = _Phase.idle);
      return;
    }
    _revertTimer = Timer(after, () {
      if (mounted) setState(() => _phase = _Phase.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget? phaseIcon = switch (_phase) {
      _Phase.success => widget.successIcon ?? const Icon(Icons.check),
      _Phase.error => widget.errorIcon ?? const Icon(Icons.error_outline),
      _ => widget.icon,
    };
    final String phaseLabel = switch (_phase) {
      _Phase.success => widget.successLabel ?? widget.label,
      _Phase.error => widget.errorLabel ?? widget.label,
      _ => widget.label,
    };
    final String? announcement = switch (_phase) {
      _Phase.loading => '${widget.label}, loading',
      _Phase.success => '${widget.successLabel ?? widget.label}, succeeded',
      _Phase.error => '${widget.errorLabel ?? widget.label}, failed',
      _Phase.idle => null,
    };

    return Semantics(
      liveRegion: true,
      label: announcement,
      child: FwButton(
        label: phaseLabel,
        onPressed: widget.onPressed == null ? null : _run,
        variant: widget.variant,
        intent: widget.intent,
        size: widget.size,
        shape: widget.shape,
        icon: phaseIcon,
        iconPosition: phaseIcon == null
            ? FwIconPosition.start
            : widget.iconPosition,
        iconGap: widget.iconGap,
        loading: _phase == _Phase.loading,
        loadingLabel: widget.label,
        enableFeedback: false, // haptics are phase-aware here
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
      ),
    );
  }
}
