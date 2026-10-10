import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

// ---------------------------------------------------------------------------
// Drawer (O03, drawer part).
// ---------------------------------------------------------------------------

/// Navigation drawer (O03): start/end drawer content for a [Scaffold].
///
/// Place in `Scaffold.drawer` (start side) or `Scaffold.endDrawer` (end
/// side); open with `Scaffold.of(context).openDrawer()/openEndDrawer()`.
/// Native drawer behavior applies: scrim tap and the back button close it,
/// edge swipe opens it, and focus returns to the trigger on close. The
/// [header]/[content]/[footer] slots keep navigation chrome separate from
/// the item list, which stays caller-owned (use [FwListTile]).
class FwDrawer extends StatelessWidget {
  const FwDrawer({
    super.key,
    this.header,
    required this.content,
    this.footer,
    this.width = 320,
  });

  /// Optional header: brand, account, or search slot.
  final Widget? header;

  /// The navigation items, typically [FwListTile]s.
  final Widget content;

  /// Optional footer: settings, sign-out, version.
  final Widget? footer;

  /// Drawer width. Defaults to 320dp.
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final s = theme.spaceScale;
    return Drawer(
      width: width,
      backgroundColor: colors.of(FwColorRole.surfaceContainerLow),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(theme.radii.of(FwRadius.lg)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Padding(
                padding: EdgeInsetsDirectional.all(s.of(FwSpace.s4, context)),
                child: header!,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: s.of(FwSpace.s2, context),
                ),
                child: content,
              ),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsetsDirectional.all(s.of(FwSpace.s4, context)),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popover (O04).
// ---------------------------------------------------------------------------

/// Popover placement, in logical (RTL-aware) terms.
enum FwPopoverPlacement {
  /// Below the anchor.
  bottom,

  /// Above the anchor.
  top,

  /// At the inline start side (left in LTR, right in RTL).
  start,

  /// At the inline end side (right in LTR, left in RTL).
  end;

  /// The opposite placement, used for collision flip.
  FwPopoverPlacement get opposite => switch (this) {
    FwPopoverPlacement.bottom => FwPopoverPlacement.top,
    FwPopoverPlacement.top => FwPopoverPlacement.bottom,
    FwPopoverPlacement.start => FwPopoverPlacement.end,
    FwPopoverPlacement.end => FwPopoverPlacement.start,
  };
}

/// Controller for an [FwPopover]: show/hide/toggle the anchored content.
class FwPopoverController extends ChangeNotifier {
  bool _showing = false;

  /// Whether the popover content is currently shown.
  bool get isShowing => _showing;

  /// Shows the popover. No-op if already showing.
  void show() {
    if (!_showing) {
      _showing = true;
      notifyListeners();
    }
  }

  /// Hides the popover. No-op if already hidden.
  void hide() {
    if (_showing) {
      _showing = false;
      notifyListeners();
    }
  }

  /// Toggles visibility.
  void toggle() {
    if (_showing) {
      hide();
    } else {
      show();
    }
  }
}

/// Popover (O04): anchored, interactive content with placement and flip.
///
/// Unlike a tooltip, a popover holds *interactive* content (filters,
/// pickers, rich previews) and stays open until dismissed. The anchor is
/// caller-built and owns its toggle gesture; [content] appears in an
/// [OverlayPortal] positioned by a [CompositedTransformFollower].
///
/// Placement is logical: [FwPopoverPlacement.start]/[end] resolve against
/// [Directionality] (RTL flips sides). When the content would overflow the
/// window on the placement axis, it flips once to the opposite placement.
/// Tap-outside (via [TapRegion], so the anchor itself stays tappable) and
/// Escape dismiss; there is no modal barrier — content behind stays
/// visible and interactive.
///
/// This is *not* a dialog: it has no scrim, traps no focus, and announces
/// as a plain container, not a route.
class FwPopover extends StatefulWidget {
  const FwPopover({
    super.key,
    required this.controller,
    required this.anchor,
    required this.content,
    this.placement = FwPopoverPlacement.bottom,
    this.gap = FwSpace.s2,
    this.dismissOnTapOutside = true,
    this.autofocusContent = true,
    this.contentMaxWidth = 320,
  });

  /// Controller driving visibility.
  final FwPopoverController controller;

  /// The anchor widget, positioned in normal layout. The caller wires its
  /// gesture (usually `onPressed: controller.toggle`).
  final Widget anchor;

  /// The popover content card.
  final Widget content;

  /// Preferred placement; flips once on collision.
  final FwPopoverPlacement placement;

  /// Token gap between anchor and content.
  final FwSpace gap;

  /// Whether tapping outside dismisses.
  final bool dismissOnTapOutside;

  /// Whether the content takes focus when shown. Disable when the anchor
  /// must keep focus (e.g. a combobox text field).
  final bool autofocusContent;

  /// Maximum content width.
  final double contentMaxWidth;

  @override
  State<FwPopover> createState() => _FwPopoverState();
}

class _FwPopoverState extends State<FwPopover> {
  final _link = LayerLink();
  final _portalController = OverlayPortalController();
  final _followerKey = GlobalKey();
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(FwPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (widget.controller.isShowing) {
      _portalController.show();
      if (_flipped) setState(() => _flipped = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFlip());
    } else {
      _portalController.hide();
    }
  }

  /// Flips placement once when the content overflows the window.
  void _maybeFlip() {
    if (!mounted || _flipped || !widget.controller.isShowing) return;
    final renderObject = _followerKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final screen = MediaQuery.sizeOf(context);
    final dir = Directionality.of(context);
    final overflows = switch (widget.placement) {
      FwPopoverPlacement.bottom => rect.bottom > screen.height,
      FwPopoverPlacement.top => rect.top < 0,
      FwPopoverPlacement.end =>
        dir == TextDirection.ltr ? rect.right > screen.width : rect.left < 0,
      FwPopoverPlacement.start =>
        dir == TextDirection.ltr ? rect.left < 0 : rect.right > screen.width,
    };
    if (overflows) setState(() => _flipped = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final s = theme.spaceScale;
    final dir = Directionality.of(context);
    final gap = s.of(widget.gap, context);
    final placement = _flipped ? widget.placement.opposite : widget.placement;

    final (
      Alignment targetAnchor,
      Alignment followerAnchor,
      Offset offset,
    ) = switch (placement) {
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

    // TapRegion group: taps on the anchor do not count as "outside", so the
    // anchor stays tappable while the popover is open.
    const groupId = 'fw-popover';
    return OverlayPortal(
      controller: _portalController,
      // Stack: lets the follower size to its content instead of filling
      // the overlay (a bare follower expands to the overlay constraints,
      // which breaks the flip measurement).
      overlayChildBuilder: (context) => Stack(
        children: [
          CompositedTransformFollower(
            link: _link,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: offset,
            child: KeyedSubtree(
              key: _followerKey,
              child: TapRegion(
                groupId: groupId,
                onTapOutside: widget.dismissOnTapOutside
                    ? (event) => widget.controller.hide()
                    : null,
                child: Focus(
                  autofocus: widget.autofocusContent,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.escape) {
                      widget.controller.hide();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Semantics(
                    container: true,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: widget.contentMaxWidth,
                      ),
                      child: Container(
                        decoration: const FwElevation()
                            .decoration(context, 3)
                            .copyWith(
                              color: colors.of(
                                FwColorRole.surfaceContainerHigh,
                              ),
                              borderRadius: BorderRadius.circular(
                                theme.radii.of(FwRadius.md),
                              ),
                            ),
                        padding: EdgeInsetsDirectional.all(
                          s.of(FwSpace.s4, context),
                        ),
                        child: widget.content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: TapRegion(
        groupId: groupId,
        child: CompositedTransformTarget(link: _link, child: widget.anchor),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu (O06).
// ---------------------------------------------------------------------------

/// One entry in an [FwMenu].
sealed class FwMenuEntry<T> {
  const FwMenuEntry();
}

/// A selectable menu action.
class FwMenuAction<T> extends FwMenuEntry<T> {
  const FwMenuAction({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.checked = false,
  });

  /// Typed value delivered to [FwMenu.onSelected].
  final T value;
  final String label;
  final Widget? icon;
  final bool enabled;

  /// When true, a check mark leads the item (toggle-menu pattern).
  final bool checked;
}

/// A visual separator between menu items.
class FwMenuSeparator<T> extends FwMenuEntry<T> {
  const FwMenuSeparator();
}

/// A non-interactive group label inside the menu.
class FwMenuLabel<T> extends FwMenuEntry<T> {
  const FwMenuLabel(this.text);

  final String text;
}

/// A nested submenu. Native [SubmenuButton] behavior: hover/keyboard opens,
/// Escape steps back out, focus restores to the parent item on close.
class FwMenuSubmenu<T> extends FwMenuEntry<T> {
  const FwMenuSubmenu({required this.label, this.icon, required this.children});

  final String label;
  final Widget? icon;
  final List<FwMenuEntry<T>> children;
}

/// Dropdown menu (O06): action groups, separators, labels, checked items,
/// and submenus over a shared typed entry model.
///
/// Built on native [MenuAnchor]: Arrow/Home/End/Enter/Escape keyboard
/// behavior and focus restoration come from the platform widget; this
/// facade adds token styling and the typed entry model. The [trigger]
/// builds the anchor control and receives the [MenuController] to open,
/// close, or toggle the menu.
class FwMenu<T> extends StatefulWidget {
  const FwMenu({
    super.key,
    required this.entries,
    required this.onSelected,
    required this.trigger,
    this.controller,
  });

  /// Menu entries in display order.
  final List<FwMenuEntry<T>> entries;

  /// Called with the selected action's typed value.
  final ValueChanged<T> onSelected;

  /// Builds the trigger; call `controller.open()` from its gesture.
  final Widget Function(BuildContext context, MenuController controller)
  trigger;

  /// Optional external controller.
  final MenuController? controller;

  @override
  State<FwMenu<T>> createState() => _FwMenuState<T>();
}

class _FwMenuState<T> extends State<FwMenu<T>> {
  MenuController? _internalController;
  final _triggerKey = GlobalKey();
  bool _menuHadFocus = false;

  MenuController get _effectiveController =>
      widget.controller ?? (_internalController ??= MenuController());

  /// Finds the first focusable node inside the trigger subtree (e.g. the
  /// trigger button's own focus node) using only public APIs.
  FocusNode? _findTriggerNode() {
    final triggerElement = _triggerKey.currentContext as Element?;
    if (triggerElement == null) return null;
    FocusNode? found;
    bool underTrigger(Element element) {
      var under = false;
      element.visitAncestorElements((ancestor) {
        if (ancestor == triggerElement) {
          under = true;
          return false;
        }
        return true;
      });
      return under;
    }

    void visit(FocusNode node) {
      if (found != null) return;
      final context = node.context;
      if (context is Element &&
          context != triggerElement &&
          underTrigger(context) &&
          node.canRequestFocus) {
        found = node;
        return;
      }
      for (final child in node.children) {
        visit(child);
        if (found != null) return;
      }
    }

    visit(FocusManager.instance.rootScope);
    return found;
  }

  /// Restores trigger focus when the menu closes, but only if the menu
  /// had focus — a pointer user who never left the trigger keeps their
  /// context untouched.
  void _handleClose() {
    if (!_menuHadFocus) return;
    _menuHadFocus = false;
    final restoreTarget = _findTriggerNode();
    if (restoreTarget == null) return;
    // Defer past the close's layout pass: focus requests issued during
    // dispose do not stick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || restoreTarget.context == null) return;
      restoreTarget.requestFocus();
    });
  }

  MenuStyle _style(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final s = theme.spaceScale;
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(
        colors.of(FwColorRole.surfaceContainerHigh),
      ),
      // Level-2-ish material elevation; the token shadow scale owns
      // BoxShadow construction, native Material owns this double.
      elevation: const WidgetStatePropertyAll(3),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
        ),
      ),
      padding: WidgetStatePropertyAll(
        // P3.2: menu container padding compacts with density.
        EdgeInsets.all(s.ofScaled(FwSpace.s2, context)),
      ),
    );
  }

  List<Widget> _children(
    BuildContext context,
    MenuController controller,
    List<FwMenuEntry<T>> entries,
  ) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    return [
      for (final entry in entries)
        switch (entry) {
          FwMenuAction<T>(
            value: final value,
            label: final label,
            icon: final icon,
            enabled: final enabled,
            checked: final checked,
          ) =>
            MenuItemButton(
              onPressed: enabled
                  ? () {
                      controller.close();
                      widget.onSelected(value);
                    }
                  : null,
              leadingIcon: checked ? const Icon(Icons.check, size: 20) : icon,
              child: Text(label),
            ),
          FwMenuSeparator<T>() => const Divider(height: 8, thickness: 1),
          FwMenuLabel<T>(text: final text) => Padding(
            // P3.2: was raw 12/12/8/4 literals — now density-scaled aliases.
            padding: EdgeInsetsDirectional.only(
              start: theme.spaceScale.resolveAlias(
                FwSpaceAlias.controlInline,
                context,
              ),
              end: theme.spaceScale.resolveAlias(
                FwSpaceAlias.controlInline,
                context,
              ),
              top: theme.spaceScale.resolveAlias(
                FwSpaceAlias.controlBlock,
                context,
              ),
              bottom: theme.spaceScale.ofScaled(FwSpace.s1, context),
            ),
            child: Text(
              text,
              style: typeScale.resolve(FwTextRole.caption, context),
            ),
          ),
          FwMenuSubmenu<T>(
            label: final label,
            icon: final icon,
            children: final children,
          ) =>
            SubmenuButton(
              leadingIcon: icon,
              menuChildren: _children(context, controller, children),
              child: Text(label),
            ),
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = _effectiveController;
    return MenuAnchor(
      controller: controller,
      style: _style(context),
      builder: (context, _, _) => Focus(
        key: _triggerKey,
        onFocusChange: (hasFocus) {
          if (hasFocus) _menuHadFocus = false;
        },
        child: widget.trigger(context, controller),
      ),
      menuChildren: [
        _VisibilityDetector(
          onClose: _handleClose,
          child: Focus(
            descendantsAreFocusable: true,
            onFocusChange: (hasFocus) {
              if (hasFocus) _menuHadFocus = true;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _children(context, controller, widget.entries),
            ),
          ),
        ),
      ],
    );
  }
}

/// Detects menu close: the panel mounts its children on open and unmounts
/// them on dismiss.
class _VisibilityDetector extends StatefulWidget {
  const _VisibilityDetector({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  State<_VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<_VisibilityDetector> {
  @override
  void dispose() {
    widget.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ---------------------------------------------------------------------------
// Context menu (O07).
// ---------------------------------------------------------------------------

/// Context menu region (O07): secondary-click, keyboard, and long-press
/// invocation of a menu over [child].
///
/// - Desktop/web: secondary click opens the menu at the pointer.
/// - Keyboard: the Menu key or Shift+F10 opens it centered on the region.
/// - Touch: long-press opens it at the press position.
///
/// [FwMenuSubmenu] entries are rejected with an assertion — nested menus
/// need the anchored [FwMenu]; context menus stay one level deep.
/// Always pair with a discoverable non-right-click alternative (e.g. a
/// visible overflow button opening the same entries via [FwMenu]).
class FwContextMenuRegion<T> extends StatefulWidget {
  FwContextMenuRegion({
    super.key,
    required this.entries,
    required this.onSelected,
    required this.child,
  }) : assert(
         !entries.any((e) => e is FwMenuSubmenu<T>),
         'Context menus do not support submenus; use FwMenu.',
       );

  /// Menu entries (actions, separators, labels — no submenus).
  final List<FwMenuEntry<T>> entries;

  /// Called with the selected action's typed value.
  final ValueChanged<T> onSelected;

  /// The content the menu acts on.
  final Widget child;

  @override
  State<FwContextMenuRegion<T>> createState() => _FwContextMenuRegionState<T>();
}

class _FwContextMenuRegionState<T> extends State<FwContextMenuRegion<T>> {
  final _regionKey = GlobalKey();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<PopupMenuEntry<T>> _popupEntries(BuildContext context) => [
    for (final entry in widget.entries)
      switch (entry) {
        FwMenuAction<T>(
          value: final value,
          label: final label,
          icon: final icon,
          enabled: final enabled,
          checked: final checked,
        ) =>
          PopupMenuItem<T>(
            value: value,
            enabled: enabled,
            child: Row(
              children: [
                if (checked)
                  Padding(
                    // P3.2: icon-to-label gap compacts with density.
                    padding: EdgeInsetsDirectional.only(
                      end: context.fwTheme.spaceScale.ofScaled(
                        FwSpace.s2,
                        context,
                      ),
                    ),
                    child: const Icon(Icons.check, size: 20),
                  )
                else if (icon != null)
                  Padding(
                    // P3.2: icon-to-label gap compacts with density.
                    padding: EdgeInsetsDirectional.only(
                      end: context.fwTheme.spaceScale.ofScaled(
                        FwSpace.s2,
                        context,
                      ),
                    ),
                    child: icon,
                  ),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        FwMenuSeparator<T>() => const PopupMenuDivider(),
        FwMenuLabel<T>(text: final text) => PopupMenuItem<T>(
          enabled: false,
          child: Text(text),
        ),
        FwMenuSubmenu<T>() => throw StateError(
          'Context menus do not support submenus.',
        ),
      },
  ];

  Future<void> _showAt(Offset globalPosition) async {
    final size = MediaQuery.sizeOf(context);
    final value = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        size.width - globalPosition.dx,
        size.height - globalPosition.dy,
      ),
      items: _popupEntries(context),
    );
    if (value != null && mounted) widget.onSelected(value);
  }

  void _showCentered() {
    final box = _regionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    _showAt(box.localToGlobal(box.size.center(Offset.zero)));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isMenuKey =
        event.logicalKey == LogicalKeyboardKey.contextMenu ||
        (event.logicalKey == LogicalKeyboardKey.f10 &&
            HardwareKeyboard.instance.isShiftPressed);
    if (isMenuKey) {
      _showCentered();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        key: _regionKey,
        onSecondaryTapDown: (details) => _showAt(details.globalPosition),
        onLongPressStart: (details) => _showAt(details.globalPosition),
        // Tap still focuses the region so keyboard invocation works.
        onTap: _focusNode.requestFocus,
        child: widget.child,
      ),
    );
  }
}
