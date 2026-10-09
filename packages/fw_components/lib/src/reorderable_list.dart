import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Drag-to-reorder list.
///
/// A token-styled [ReorderableListView]: each item gets a drag handle,
/// [FwHaptics] fires on reorder, and the proxy (dragged item) lifts with a
/// shadow. Items are keyed by [itemKey] — stable keys are required; the
/// default uses the item itself.
///
/// Semantics: the list is a regular list; each handle is a button labelled
/// "Reorder <item label>".
class FwReorderableList<T> extends StatelessWidget {
  const FwReorderableList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.itemKey,
    this.handleSemanticLabel,
  });

  /// Items in current order.
  final List<T> items;

  /// Builds the tile content for [item]. Do not key it; the list keys
  /// the wrapper.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Fires with (oldIndex, newIndex) using the ReorderableListView
  /// convention (newIndex is the post-removal index).
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Key for the item wrapper. Defaults to [ValueKey] of the item.
  final Key Function(T item)? itemKey;

  /// Label for the drag handle, e.g. (item) => 'Reorder ${item.name}'.
  final String Function(T item)? handleSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
        child: child,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return KeyedSubtree(
          key: itemKey?.call(item) ?? ValueKey(item),
          child: Row(
            children: [
              Expanded(child: itemBuilder(context, item)),
              Semantics(
                button: true,
                label: handleSemanticLabel?.call(item) ?? 'Reorder item $index',
                child: ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.all(
                      theme.spaceScale.of(FwSpace.s2, context),
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      color: colors.of(FwColorRole.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        context.fwTheme.haptics.selection(context);
        onReorder(oldIndex, newIndex);
      },
    );
  }
}
