import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'menu.dart';

// ---------------------------------------------------------------------------
// Hover card (P4): hover/focus-triggered info card.
// ---------------------------------------------------------------------------

/// Hover card (P4): supplementary information revealed when the pointer
/// hovers [anchor] or [anchor] takes keyboard focus.
///
/// Unlike [FwTooltip] (plain text, system-styled) this renders rich
/// [content] in a framework card; unlike [FwPopover] it needs no tap and
/// no controller — hover and focus drive it. Follows WCAG 1.4.13
/// (content on hover or focus): the card is *dismissible* (pointer leaves
/// or focus moves on), *hoverable* (moving onto the card itself keeps it
/// open), and *persistent* (it stays while hovered or focused).
///
/// No hover-only content: everything in [content] must be supplementary —
/// keyboard users reach it via focus, touch users via long-press is *not*
/// provided, so never put the only path to an action here.
///
/// Demand note: retrospective §12 deferral ("hover card").
class FwHoverCard extends StatefulWidget {
  const FwHoverCard({
    super.key,
    required this.anchor,
    required this.content,
    this.focusNode,
    this.placement = FwPopoverPlacement.bottom,
    this.gap = FwSpace.s2,
    this.showDelay = const Duration(milliseconds: 300),
    this.hideDelay = const Duration(milliseconds: 150),
    this.contentMaxWidth = 320,
    this.elevation = 3,
    this.tonal = true,
  }) : assert(
         elevation >= 0 && elevation <= 5,
         'elevation must be an FwElevation level 0–5',
       );

  /// The widget hover/focus is observed on.
  final Widget anchor;

  /// Rich card content. Keep it supplementary, never the only path to
  /// an action.
  final Widget content;

  /// Optional focus node for the anchor. Provide one to drive or observe
  /// keyboard focus programmatically; otherwise an internal node is used.
  final FocusNode? focusNode;

  /// Preferred placement; logical (RTL flips start/end).
  final FwPopoverPlacement placement;

  /// Token gap between anchor and card.
  final FwSpace gap;

  /// Delay before the card appears on hover (avoids flicker on pass-over).
  final Duration showDelay;

  /// Delay before the card hides after pointer/focus leaves.
  final Duration hideDelay;

  /// Maximum card width.
  final double contentMaxWidth;

  /// Elevation level 0–5. M3-correct default is 3.
  final int elevation;

  /// Whether the M3 surface tint applies at [elevation].
  final bool tonal;

  @override
  State<FwHoverCard> createState() => _FwHoverCardState();
}

class _FwHoverCardState extends State<FwHoverCard> {
  final _link = LayerLink();
  final _portalController = OverlayPortalController();
  Timer? _showTimer;
  Timer? _hideTimer;
  bool _showing = false;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_showing) return;
    _showTimer?.cancel();
    if (widget.showDelay == Duration.zero) {
      _showNow();
    } else {
      _showTimer = Timer(widget.showDelay, _showNow);
    }
  }

  void _showNow() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_showing || !mounted) return;
    setState(() => _showing = true);
    _portalController.show();
  }

  void _hide() {
    _showTimer?.cancel();
    _showTimer = null;
    if (!_showing) return;
    _hideTimer?.cancel();
    if (widget.hideDelay == Duration.zero) {
      _hideNow();
    } else {
      _hideTimer = Timer(widget.hideDelay, _hideNow);
    }
  }

  void _hideNow() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!_showing || !mounted) return;
    setState(() => _showing = false);
    _portalController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final s = theme.spaceScale;
    final dir = Directionality.of(context);
    final gap = s.of(widget.gap, context);

    final (
      Alignment targetAnchor,
      Alignment followerAnchor,
      Offset offset,
    ) = switch (widget.placement) {
      FwPopoverPlacement.bottom => (
        Alignment.bottomCenter,
        Alignment.topCenter,
        Offset(0, gap),
      ),
      FwPopoverPlacement.top => (
        Alignment.topCenter,
        Alignment.bottomCenter,
        Offset(0, -gap),
      ),
      FwPopoverPlacement.end =>
        dir == TextDirection.ltr
            ? (Alignment.centerRight, Alignment.centerLeft, Offset(gap, 0))
            : (Alignment.centerLeft, Alignment.centerRight, Offset(-gap, 0)),
      FwPopoverPlacement.start =>
        dir == TextDirection.ltr
            ? (Alignment.centerLeft, Alignment.centerRight, Offset(-gap, 0))
            : (Alignment.centerRight, Alignment.centerLeft, Offset(gap, 0)),
    };

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (context) => Stack(
        children: [
          CompositedTransformFollower(
            link: _link,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: offset,
            child: MouseRegion(
              // WCAG 1.4.13 "hoverable": moving onto the card keeps it.
              onEnter: (_) => _showNow(),
              onExit: (_) => _hide(),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.contentMaxWidth),
                child: Container(
                  padding: EdgeInsets.all(
                    s.resolveAlias(FwSpaceAlias.cardInset, context),
                  ),
                  decoration: const FwElevation()
                      .decoration(
                        context,
                        widget.elevation,
                        tonal: widget.tonal,
                        color: colors.of(FwColorRole.surface),
                      )
                      .copyWith(
                        borderRadius: BorderRadius.circular(
                          theme.radii.of(FwRadius.md),
                        ),
                      ),
                  child: widget.content,
                ),
              ),
            ),
          ),
        ],
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) => _show(),
          onExit: (_) => _hide(),
          child: Focus(
            focusNode: widget.focusNode,
            onFocusChange: (focused) {
              if (focused) {
                _showNow();
              } else {
                _hideNow();
              }
            },
            child: widget.anchor,
          ),
        ),
      ),
    );
  }
}
