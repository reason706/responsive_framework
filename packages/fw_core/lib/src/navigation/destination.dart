import 'package:flutter/material.dart';

/// One navigation destination shared by bottom navigation, rail, sidebar,
/// and the adaptive scaffold (N03/N07/N08/L09).
///
/// IDs are stable strings: the same destination keeps its ID across
/// responsive transitions so selection state is never duplicated.
@immutable
class FwDestination {
  const FwDestination({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeLabel,
    this.disabled = false,
    this.tooltip,
    this.children = const [],
  });

  /// Stable identifier shared across all navigation widgets.
  final String id;
  final String label;
  final Widget icon;
  final Widget? selectedIcon;

  /// Optional badge text (e.g. unread count) shown on the destination.
  final String? badgeLabel;
  final bool disabled;

  /// Accessible name override; defaults to [label].
  final String? tooltip;

  /// Nested destinations rendered as an expandable group in the sidebar.
  final List<FwDestination> children;

  String get effectiveTooltip => tooltip ?? label;
}

/// One selection model driving every navigation widget.
///
/// Bottom navigation, rail, sidebar, and the adaptive scaffold all read the
/// same [FwNavigationState]: selecting a destination in one widget updates
/// the others. Widgets also work fully controlled via [selectedId] +
/// [onDestinationSelected] without this model.
class FwNavigationState extends ChangeNotifier {
  FwNavigationState({required String selectedId}) : _selectedId = selectedId;

  String _selectedId;

  String get selectedId => _selectedId;

  void select(String id) {
    if (id == _selectedId) return;
    _selectedId = id;
    notifyListeners();
  }
}
