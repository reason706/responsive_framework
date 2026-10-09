import 'colors.dart';

/// Semantic intent of an action. Never conveyed by color alone: intents
/// also differ in label, icon, or placement in the UI.
///
/// Shared vocabulary for every component that communicates intent (buttons,
/// icon buttons, badges, chips): intent means the same colors everywhere,
/// resolved through [intentRoles] into [FwColorRole]s.
enum FwIntent { primary, neutral, success, warning, danger, info }

/// Intent color roles: (background, foreground).
///
/// Shared by action widgets so intent means the same colors everywhere.
/// Components resolve these through [FwColors]; the component-token layer
/// ([FwButtonColors]) pre-resolves them per component.
(FwColorRole, FwColorRole) intentRoles(FwIntent intent) => switch (intent) {
  FwIntent.primary => (FwColorRole.primary, FwColorRole.onPrimary),
  FwIntent.neutral => (
    FwColorRole.secondaryContainer,
    FwColorRole.onSecondaryContainer,
  ),
  FwIntent.success => (FwColorRole.success, FwColorRole.onSuccess),
  FwIntent.warning => (FwColorRole.warning, FwColorRole.onWarning),
  FwIntent.danger => (FwColorRole.error, FwColorRole.onError),
  FwIntent.info => (FwColorRole.info, FwColorRole.onInfo),
};
