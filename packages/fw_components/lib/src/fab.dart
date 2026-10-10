import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

/// FAB size. The hit area always meets [FwTheme.minTapTarget] (the small
/// size clamps to it); size changes the visual diameter otherwise.
enum FwFabSize {
  /// Compact 40dp visual (48dp hit area per the framework minimum).
  small,

  /// Standard 56dp.
  regular,

  /// Large 96dp.
  large,
}

extension on FwFabSize {
  double get diameter => switch (this) {
    FwFabSize.small => 40,
    FwFabSize.regular => 56,
    FwFabSize.large => 96,
  };
}

/// Floating action button (A08).
///
/// A non-null [label] makes it an extended FAB (icon + label). [tooltip]
/// is the accessible name. One FAB per screen; it must not cover critical
/// content — that is the scaffold's responsibility.
///
/// Elevation follows the Material FAB spec (handled by [ElevatedButton]);
/// framework-drawn surfaces consume [FwElevation] tokens instead.
class FwFab extends StatelessWidget {
  const FwFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.size = FwFabSize.regular,
    this.intent = FwIntent.primary,
    this.tooltip,
    this.enableFeedback = true,
    this.focusNode,
    this.autofocus = false,
    this.elevation = 3,
  }) : assert(
         elevation >= 0 && elevation <= 5,
         'elevation must be an FwElevation level 0–5',
       );

  final VoidCallback? onPressed;
  final Widget icon;

  /// Extended FAB label. Null renders the circular form.
  final String? label;
  final FwFabSize size;
  final FwIntent intent;
  final String? tooltip;
  final bool enableFeedback;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Elevation level 0–5, mapped onto the native button surface.
  /// M3-correct default is 3.
  final int elevation;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final (bg, fg) = intentRoles(intent);
    final colors = theme.colors;

    void handlePress() {
      if (enableFeedback) theme.haptics.tap(context);
      onPressed?.call();
    }

    // The hit area never drops below the framework minimum, even for the
    // compact M3 size.
    final minTarget = theme.minTapTarget;
    final diameter = math.max(size.diameter, minTarget);
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        label == null ? Size(diameter, diameter) : Size(minTarget, 56),
      ),
      // P3.1: the level maps onto the native button elevation double.
      elevation: WidgetStatePropertyAll(elevation.toDouble()),
      padding: WidgetStatePropertyAll(
        label == null
            ? EdgeInsets.zero
            : EdgeInsetsDirectional.symmetric(
                horizontal: theme.spaceScale.of(FwSpace.s4, context),
              ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.of(FwColorRole.disabled);
        }
        return colors.of(bg);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.of(FwColorRole.onDisabled);
        }
        return colors.of(fg);
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            theme.radii.of(label == null ? FwRadius.pill : FwRadius.lg),
          ),
        ),
      ),
    );

    final content = label == null
        ? icon
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
              Flexible(child: Text(label!)),
            ],
          );

    final button = ElevatedButton(
      onPressed: onPressed == null ? null : handlePress,
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      child: content,
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// One action in a [FwSpeedDial].
class FwSpeedDialChild {
  const FwSpeedDialChild({
    required this.icon,
    required this.label,
    required this.onTap,
    this.intent = FwIntent.neutral,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final FwIntent intent;
}

/// Expandable FAB with labeled actions (A08 speed dial).
///
/// Tapping the main FAB expands [children] above it with a scrim;
/// tapping the scrim, pressing Escape, or choosing an action closes it.
/// Focus moves into the expanded actions and is restored to the main FAB
/// on close. Animations collapse instantly under reduced motion.
class FwSpeedDial extends StatefulWidget {
  const FwSpeedDial({
    super.key,
    required this.children,
    this.icon = const Icon(Icons.add),
    this.activeIcon = const Icon(Icons.close),
    this.tooltip = 'More actions',
    this.closeTooltip = 'Close',
    this.intent = FwIntent.primary,
    this.size = FwFabSize.regular,
    this.enableFeedback = true,
  }) : assert(children.length > 0, 'speed dial needs at least one action');

  final List<FwSpeedDialChild> children;
  final Widget icon;
  final Widget activeIcon;
  final String tooltip;
  final String closeTooltip;
  final FwIntent intent;
  final FwFabSize size;
  final bool enableFeedback;

  @override
  State<FwSpeedDial> createState() => _FwSpeedDialState();
}

class _FwSpeedDialState extends State<FwSpeedDial>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final FocusNode _escapeNode = FocusNode();
  final LayerLink _link = LayerLink();
  bool _open = false;
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    // Created in initState (not as a field initializer): the ticker needs
    // a mounted state, and field initializers run before mount.
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _stagger.dispose();
    _escapeNode.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      setState(() => _open = true);
      _portal.show();
      // Take focus so Escape closes the dial.
      _escapeNode.requestFocus();
      if (!MediaQuery.disableAnimationsOf(context)) {
        _stagger.forward(from: 0);
      }
    }
  }

  void _close() {
    if (!_open) return;
    _portal.hide();
    setState(() => _open = false);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    List<Widget> actions() {
      final items = <Widget>[];
      for (var i = 0; i < widget.children.length; i++) {
        final child = widget.children[i];
        void choose() {
          _close();
          child.onTap();
        }

        Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: choose,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spaceScale.of(FwSpace.s2, context),
                  vertical: theme.spaceScale.of(FwSpace.s1, context),
                ),
                decoration: BoxDecoration(
                  color: theme.colors.of(FwColorRole.inverseSurface),
                  borderRadius: BorderRadius.circular(
                    theme.radii.of(FwRadius.sm),
                  ),
                ),
                child: Text(
                  child.label,
                  style: theme.typeScale
                      .resolve(FwTextRole.label, context)
                      .copyWith(
                        color: theme.colors.of(FwColorRole.onInverseSurface),
                      ),
                ),
              ),
            ),
            SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
            FwFab(
              onPressed: choose,
              icon: child.icon,
              size: FwFabSize.small,
              intent: child.intent,
              tooltip: child.label,
              enableFeedback: widget.enableFeedback,
            ),
          ],
        );
        if (!reducedMotion) {
          final t = CurvedAnimation(
            parent: _stagger,
            curve: Interval(
              i / widget.children.length,
              (i + 1) / widget.children.length,
              curve: Curves.easeOut,
            ),
          );
          row = FadeTransition(
            opacity: t,
            child: ScaleTransition(scale: t, child: row),
          );
        }
        items.add(
          Padding(
            padding: EdgeInsets.only(
              bottom: theme.spaceScale.of(FwSpace.s2, context),
            ),
            child: row,
          ),
        );
      }
      // Children stack bottom-up: first child nearest the FAB.
      return items.reversed.toList();
    }

    // The scrim and the actions live in the overlay ABOVE the barrier so
    // the rows stay tappable; they are anchored to the FAB via [_link]
    // so the dial works wherever the scaffold places it.
    return Focus(
      focusNode: _escapeNode,
      onKeyEvent: _onKey,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Stack(
          children: [
            ModalBarrier(
              color: theme.colors.of(FwColorRole.scrim).withValues(alpha: 0.32),
              dismissible: true,
              onDismiss: _close,
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: Offset(0, -theme.spaceScale.of(FwSpace.s2, context)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: actions(),
              ),
            ),
          ],
        ),
        child: CompositedTransformTarget(
          link: _link,
          child: Semantics(
            expanded: _open,
            child: FwFab(
              onPressed: _toggle,
              icon: _open ? widget.activeIcon : widget.icon,
              size: widget.size,
              intent: widget.intent,
              tooltip: _open ? widget.closeTooltip : widget.tooltip,
              enableFeedback: widget.enableFeedback,
            ),
          ),
        ),
      ),
    );
  }
}
