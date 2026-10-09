import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';
import 'icon_button.dart';
import 'menu.dart';

/// One item in an [FwButtonGroup].
@immutable
class FwButtonGroupItem {
  const FwButtonGroupItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.intent = FwIntent.primary,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final FwIntent intent;
  final String? tooltip;
}

/// Button group (A04): related actions composed with shared shape and
/// border rules.
///
/// [attached] draws one shared outer border with 1px dividers instead of
/// doubled seams; [attached] false spaces plain [FwButton]s with a token
/// gap. On narrow widths ([wrapToStackBreakpoint], horizontal axis only)
/// the group stacks vertically so labels never overflow.
class FwButtonGroup extends StatelessWidget {
  const FwButtonGroup({
    super.key,
    required this.items,
    this.axis = Axis.horizontal,
    this.attached = false,
    this.variant = FwButtonVariant.outline,
    this.size = FwButtonSize.md,
  }) : assert(items.length > 0, 'FwButtonGroup needs at least one item');

  final List<FwButtonGroupItem> items;
  final Axis axis;

  /// When true, items share one outer border (no doubled seams).
  final bool attached;
  final FwButtonVariant variant;
  final FwButtonSize size;

  /// Below this width a horizontal group stacks vertically.
  static const double wrapToStackBreakpoint = 480;

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      return attached
          ? _attached(context, Axis.vertical)
          : _spaced(context, Axis.vertical);
    }
    // Horizontal groups stack vertically below the breakpoint so labels
    // never overflow — attached groups included.
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < wrapToStackBreakpoint &&
            constraints.maxWidth != double.infinity;
        final effectiveAxis = narrow ? Axis.vertical : Axis.horizontal;
        return attached
            ? _attached(context, effectiveAxis)
            : _spaced(context, effectiveAxis);
      },
    );
  }

  Widget _spaced(BuildContext context, Axis effectiveAxis) {
    final gap = context.fwTheme.spaceScale.of(FwSpace.s2, context);
    final buttons = [
      for (final item in items)
        FwButton(
          label: item.label,
          onPressed: item.onPressed,
          variant: variant,
          intent: item.intent,
          size: size,
          leading: item.icon,
        ),
    ];
    if (effectiveAxis == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            buttons[i],
          ],
        ],
      );
    }
    return FwWrapH(spaced: buttons, gap: gap);
  }

  /// Attached rendering: one outer border, 1px dividers, outer corners only.
  /// Colors resolve through the layer-3 [FwButtonColors] table so the group
  /// matches [FwButton] visuals.
  Widget _attached(BuildContext context, Axis effectiveAxis) {
    final theme = context.fwTheme;
    final radius = theme.radii.md;
    final colorSetFor =
        (Theme.of(context).extension<FwButtonColors>() ??
                FwButtonColors.fromColors(theme.colors))
            .setFor(
              filled: variant == FwButtonVariant.solid,
              intent: FwIntent.primary,
            );
    final borderColor = colorSetFor.foreground;
    final divider = Container(
      width: effectiveAxis == Axis.horizontal ? 1 : double.infinity,
      height: effectiveAxis == Axis.horizontal ? double.infinity : 1,
      color: borderColor,
    );

    BorderRadiusDirectional itemRadius(int index) {
      final first = index == 0;
      final last = index == items.length - 1;
      if (effectiveAxis == Axis.horizontal) {
        return BorderRadiusDirectional.only(
          topStart: first ? Radius.circular(radius) : Radius.zero,
          bottomStart: first ? Radius.circular(radius) : Radius.zero,
          topEnd: last ? Radius.circular(radius) : Radius.zero,
          bottomEnd: last ? Radius.circular(radius) : Radius.zero,
        );
      }
      return BorderRadiusDirectional.only(
        topStart: first ? Radius.circular(radius) : Radius.zero,
        topEnd: first ? Radius.circular(radius) : Radius.zero,
        bottomStart: last ? Radius.circular(radius) : Radius.zero,
        bottomEnd: last ? Radius.circular(radius) : Radius.zero,
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) children.add(divider);
      children.add(
        _AttachedButton(
          item: items[i],
          radius: itemRadius(i),
          size: size,
          variant: variant,
        ),
      );
    }
    final row = effectiveAxis == Axis.horizontal
        ? IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        : IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: row,
      ),
    );
  }
}

/// One button inside an attached [FwButtonGroup]: borderless, with outer
/// corners only; the group draws the shared border.
class _AttachedButton extends StatelessWidget {
  const _AttachedButton({
    required this.item,
    required this.radius,
    required this.size,
    required this.variant,
  });

  final FwButtonGroupItem item;
  final BorderRadiusDirectional radius;
  final FwButtonSize size;
  final FwButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final set =
        (Theme.of(context).extension<FwButtonColors>() ??
                FwButtonColors.fromColors(theme.colors))
            .setFor(
              filled: variant == FwButtonVariant.solid,
              intent: item.intent,
            );
    final filled = variant == FwButtonVariant.solid;
    final sizeFactor = switch (size) {
      FwButtonSize.sm => 0.75,
      FwButtonSize.md => 1,
      FwButtonSize.lg => 1.5,
    };
    final button = TextButton(
      onPressed: item.onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          filled ? set.background : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return theme.colors.of(FwColorRole.onSurfaceMuted);
          }
          return set.foreground;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: radius),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsetsDirectional.symmetric(
            horizontal:
                theme.spaceScale.resolveAlias(
                  FwSpaceAlias.controlInline,
                  context,
                ) *
                sizeFactor,
            vertical:
                theme.spaceScale.resolveAlias(
                  FwSpaceAlias.controlBlock,
                  context,
                ) *
                sizeFactor,
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            item.icon!,
            SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
          ],
          Text(item.label),
        ],
      ),
    );
    if (item.tooltip != null) {
      return Tooltip(message: item.tooltip!, child: button);
    }
    return button;
  }
}

/// Horizontal wrap helper with a fixed token gap.
class FwWrapH extends StatelessWidget {
  const FwWrapH({super.key, required this.spaced, required this.gap});

  final List<Widget> spaced;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: gap, runSpacing: gap, children: spaced);
  }
}

/// One choice in an [FwSegmentedGroup].
@immutable
class FwSegmentedItem<T> {
  const FwSegmentedItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.tooltip,
  });

  final T value;
  final String label;
  final Widget? icon;
  final bool enabled;
  final String? tooltip;
}

/// Toggle / segmented group (A05): single- or multiple-choice control with
/// typed values and controlled selection.
///
/// Arrow keys move focus and selection (automatic activation, like a native
/// radio group); disabled items are skipped. [emptySelectionAllowed] false
/// makes the selection required: the last selected item cannot be
/// deselected in single-select mode.
class FwSegmentedGroup<T> extends StatefulWidget {
  const FwSegmentedGroup({
    super.key,
    required this.items,
    required this.selection,
    required this.onSelectionChanged,
    this.multiSelect = false,
    this.emptySelectionAllowed = true,
    this.intent = FwIntent.primary,
    this.size = FwButtonSize.md,
    this.axis = Axis.horizontal,
  });

  final List<FwSegmentedItem<T>> items;

  /// Controlled selection. Single mode: empty or one value. Multi mode: set.
  final Set<T> selection;
  final ValueChanged<Set<T>> onSelectionChanged;
  final bool multiSelect;
  final bool emptySelectionAllowed;
  final FwIntent intent;
  final FwButtonSize size;
  final Axis axis;

  @override
  State<FwSegmentedGroup<T>> createState() => _FwSegmentedGroupState<T>();
}

class _FwSegmentedGroupState<T> extends State<FwSegmentedGroup<T>> {
  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = [for (final _ in widget.items) FocusNode()];
  }

  @override
  void didUpdateWidget(FwSegmentedGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = [for (final _ in widget.items) FocusNode()];
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    final item = widget.items[index];
    if (!item.enabled) return;
    // Keep key events on the group's roving focus node after pointer use.
    _nodes[index].requestFocus();
    final current = Set<T>.of(widget.selection);
    if (widget.multiSelect) {
      if (current.contains(item.value)) {
        if (!widget.emptySelectionAllowed && current.length == 1) return;
        current.remove(item.value);
      } else {
        current.add(item.value);
      }
    } else {
      if (current.contains(item.value)) {
        if (!widget.emptySelectionAllowed) return;
        current.clear();
      } else {
        current
          ..clear()
          ..add(item.value);
      }
    }
    widget.onSelectionChanged(current);
    context.fwTheme.haptics.selection(context);
  }

  /// Arrow-key navigation: move focus to the next enabled item in [delta]
  /// direction and select it. Roving focus: only the selected (or first)
  /// item is in the tab order.
  void _move(int fromIndex, int delta) {
    var index = fromIndex;
    for (var i = 0; i < widget.items.length; i++) {
      index = (index + delta + widget.items.length) % widget.items.length;
      if (widget.items[index].enabled) {
        _nodes[index].requestFocus();
        _select(index);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final radius = theme.radii.md;
    final colors =
        Theme.of(context).extension<FwButtonColors>() ??
        FwButtonColors.fromColors(theme.colors);
    final selectedSet = colors.setFor(filled: true, intent: widget.intent);
    final borderColor = theme.colors.of(FwColorRole.outline);

    final selectedIndex = widget.items.indexWhere(
      (item) => widget.selection.contains(item.value),
    );
    final tabIndex = selectedIndex >= 0 ? selectedIndex : 0;

    List<Widget> children = [];
    final segmentButtons = <Widget>[];
    final segmentDividers = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final selected = widget.selection.contains(item.value);
      if (i > 0) {
        final divider = Container(
          width: widget.axis == Axis.horizontal ? 1 : double.infinity,
          height: widget.axis == Axis.horizontal ? double.infinity : 1,
          color: borderColor,
        );
        children.add(divider);
        segmentDividers.add(divider);
      }
      final isFirst = i == 0;
      final isLast = i == widget.items.length - 1;
      final itemRadius = widget.axis == Axis.horizontal
          ? BorderRadiusDirectional.only(
              topStart: isFirst ? Radius.circular(radius) : Radius.zero,
              bottomStart: isFirst ? Radius.circular(radius) : Radius.zero,
              topEnd: isLast ? Radius.circular(radius) : Radius.zero,
              bottomEnd: isLast ? Radius.circular(radius) : Radius.zero,
            )
          : BorderRadiusDirectional.only(
              topStart: isFirst ? Radius.circular(radius) : Radius.zero,
              topEnd: isFirst ? Radius.circular(radius) : Radius.zero,
              bottomStart: isLast ? Radius.circular(radius) : Radius.zero,
              bottomEnd: isLast ? Radius.circular(radius) : Radius.zero,
            );
      final sizeFactor = switch (widget.size) {
        FwButtonSize.sm => 0.75,
        FwButtonSize.md => 1,
        FwButtonSize.lg => 1.5,
      };
      final button = Focus(
        focusNode: _nodes[i],
        skipTraversal: i != tabIndex,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final forward = widget.axis == Axis.horizontal
              ? event.logicalKey == LogicalKeyboardKey.arrowRight
              : event.logicalKey == LogicalKeyboardKey.arrowDown;
          final backward = widget.axis == Axis.horizontal
              ? event.logicalKey == LogicalKeyboardKey.arrowLeft
              : event.logicalKey == LogicalKeyboardKey.arrowUp;
          if (forward) {
            _move(i, 1);
            return KeyEventResult.handled;
          }
          if (backward) {
            _move(i, -1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return TextButton(
              onPressed: item.enabled ? () => _select(i) : null,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  selected ? selectedSet.background : Colors.transparent,
                ),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return theme.colors.of(FwColorRole.onSurfaceMuted);
                  }
                  return selected
                      ? selectedSet.foreground
                      : theme.colors.of(FwColorRole.onSurface);
                }),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: itemRadius),
                ),
                side: focused
                    ? WidgetStatePropertyAll(
                        BorderSide(
                          color: theme.colors.of(FwColorRole.primary),
                          width: 2,
                        ),
                      )
                    : const WidgetStatePropertyAll(BorderSide.none),
                padding: WidgetStatePropertyAll(
                  EdgeInsetsDirectional.symmetric(
                    horizontal:
                        theme.spaceScale.resolveAlias(
                          FwSpaceAlias.controlInline,
                          context,
                        ) *
                        sizeFactor,
                    vertical:
                        theme.spaceScale.resolveAlias(
                          FwSpaceAlias.controlBlock,
                          context,
                        ) *
                        sizeFactor,
                  ),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Semantics(
                button: true,
                selected: selected,
                enabled: item.enabled,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      item.icon!,
                      SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
                    ],
                    Flexible(
                      child: Text(item.label, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      children.add(
        item.tooltip != null
            ? Tooltip(message: item.tooltip!, child: button)
            : button,
      );
      segmentButtons.add(
        item.tooltip != null
            ? Tooltip(message: item.tooltip!, child: button)
            : button,
      );
    }

    // Horizontal segments share the available width (buttons flex, dividers
    // keep their 1px) so the group never overflows at large text scales.
    List<Widget> flexedSegments() {
      final out = <Widget>[];
      for (var i = 0; i < segmentButtons.length; i++) {
        if (i > 0) out.add(segmentDividers[i - 1]);
        out.add(Flexible(child: segmentButtons[i]));
      }
      return out;
    }

    final group = widget.axis == Axis.horizontal
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: flexedSegments(),
            ),
          )
        : IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: group,
        ),
      ),
    );
  }
}

/// Split button (A06): a primary action plus an independently named menu
/// trigger.
///
/// Composes [FwButton] (A01), [FwIconButton] (A02) and [FwMenu] (O06).
/// The two are distinct touch targets and focus stops; opening the menu
/// never invokes the primary action.
class FwSplitButton<T> extends StatelessWidget {
  const FwSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.entries,
    required this.onMenuSelected,
    this.menuLabel = 'More actions',
    this.intent = FwIntent.primary,
    this.variant = FwButtonVariant.solid,
    this.size = FwButtonSize.md,
    this.leading,
  });

  /// Primary action label and callback.
  final String label;
  final VoidCallback? onPressed;

  /// Menu entries and selection callback.
  final List<FwMenuEntry<T>> entries;
  final ValueChanged<T> onMenuSelected;

  /// Accessible name of the menu trigger (never the primary label).
  final String menuLabel;
  final FwIntent intent;
  final FwButtonVariant variant;
  final FwButtonSize size;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final gap = context.fwTheme.spaceScale.of(FwSpace.s1, context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FwButton(
          label: label,
          onPressed: onPressed,
          variant: variant,
          intent: intent,
          size: size,
          leading: leading,
        ),
        SizedBox(width: gap),
        FwMenu<T>(
          entries: entries,
          onSelected: onMenuSelected,
          trigger: (context, controller) => FwIconButton(
            icon: const Icon(Icons.arrow_drop_down),
            tooltip: menuLabel,
            onPressed: controller.open,
            variant: variant == FwButtonVariant.solid
                ? FwIconButtonVariant.filled
                : FwIconButtonVariant.outline,
            intent: intent,
            iconSize: switch (size) {
              FwButtonSize.sm => 20,
              FwButtonSize.md => 24,
              FwButtonSize.lg => 28,
            },
          ),
        ),
      ],
    );
  }
}
