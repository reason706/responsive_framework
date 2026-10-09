/// Phase 4 feedback: in-app notification center (B11).
library;

import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

// ---------------------------------------------------------------------------
// Notification center (B11).
// ---------------------------------------------------------------------------

/// Severity of a notification; drives the leading icon.
enum FwNotificationSeverity { info, success, warning, error }

/// One in-app notification. Push delivery is platform work — this is the
/// in-app list model. [deepLink] is app-owned: [FwNotificationCenter]
/// reports taps, the app navigates.
class FwNotification {
  const FwNotification({
    required this.id,
    required this.title,
    this.body,
    this.timestamp,
    this.read = false,
    this.severity = FwNotificationSeverity.info,
    this.group,
    this.deepLink,
  });

  /// Stable ID for mark-read/dismiss callbacks.
  final String id;

  final String title;
  final String? body;

  /// When it happened; used for relative time and default grouping.
  final DateTime? timestamp;

  final bool read;
  final FwNotificationSeverity severity;

  /// Grouping key (e.g. "Mentions"). Null groups under "Other"/by time.
  final String? group;

  /// App-owned deep link or route. The center never navigates itself.
  final String? deepLink;

  FwNotification copyWith({bool? read}) => FwNotification(
    id: id,
    title: title,
    body: body,
    timestamp: timestamp,
    read: read ?? this.read,
    severity: severity,
    group: group,
    deepLink: deepLink,
  );
}

/// In-app notification list (B11): unread badges, grouping, mark-read /
/// clear-all, empty state with an illustration slot.
///
/// Taps report the notification via [onNotificationTap]; the app owns
/// deep-link navigation. Push delivery stays platform work.
class FwNotificationCenter extends StatelessWidget {
  const FwNotificationCenter({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onMarkRead,
    this.onMarkAllRead,
    this.onClearAll,
    this.onDismiss,
    this.emptyIllustration,
    this.emptyTitle = 'No notifications',
    this.emptyBody,
    this.markAllReadLabel = 'Mark all read',
    this.clearAllLabel = 'Clear all',
  });

  final List<FwNotification> notifications;

  /// Tap on a notification. The app owns deep-link navigation.
  final ValueChanged<FwNotification>? onNotificationTap;

  /// Mark one notification read, by id.
  final ValueChanged<String>? onMarkRead;

  final VoidCallback? onMarkAllRead;
  final VoidCallback? onClearAll;

  /// Remove one notification, by id.
  final ValueChanged<String>? onDismiss;

  /// Illustration shown in the empty state.
  final Widget? emptyIllustration;
  final String emptyTitle;
  final String? emptyBody;
  final String markAllReadLabel;
  final String clearAllLabel;

  int get _unread => notifications.where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _EmptyState(
        illustration: emptyIllustration,
        title: emptyTitle,
        body: emptyBody,
      );
    }
    final groups = _group(notifications);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          unread: _unread,
          markAllReadLabel: markAllReadLabel,
          clearAllLabel: clearAllLabel,
          onMarkAllRead: onMarkAllRead,
          onClearAll: onClearAll,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupHeader(title: group.title),
                  for (final notification in group.items)
                    _NotificationRow(
                      notification: notification,
                      onNotificationTap: onNotificationTap,
                      onMarkRead: onMarkRead,
                      onDismiss: onDismiss,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Groups by [FwNotification.group], preserving first-seen order.
  /// Ungrouped notifications land in a single trailing group.
  List<_Group> _group(List<FwNotification> items) {
    final order = <String>[];
    final buckets = <String, List<FwNotification>>{};
    final ungrouped = <FwNotification>[];
    for (final item in items) {
      final key = item.group;
      if (key == null) {
        ungrouped.add(item);
        continue;
      }
      if (!buckets.containsKey(key)) {
        order.add(key);
        buckets[key] = [];
      }
      buckets[key]!.add(item);
    }
    final groups = [
      for (final key in order) _Group(title: key, items: buckets[key]!),
    ];
    if (ungrouped.isNotEmpty) {
      groups.add(_Group(title: 'Other', items: ungrouped));
    }
    return groups;
  }
}

class _Group {
  const _Group({required this.title, required this.items});

  final String title;
  final List<FwNotification> items;
}

/// Header: unread count + mark-all-read / clear-all actions.
class _Header extends StatelessWidget {
  const _Header({
    required this.unread,
    required this.markAllReadLabel,
    required this.clearAllLabel,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  final int unread;
  final String markAllReadLabel;
  final String clearAllLabel;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spaceScale.of(FwSpace.s3, context),
        vertical: theme.spaceScale.of(FwSpace.s2, context),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: theme.spaceScale.of(FwSpace.s2, context),
        runSpacing: theme.spaceScale.of(FwSpace.s1, context),
        children: [
          Text(
            unread == 0 ? 'All caught up' : '$unread unread',
            style: typeScale.resolve(FwTextRole.label, context),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: theme.spaceScale.of(FwSpace.s1, context),
            children: [
              if (onMarkAllRead != null && unread > 0)
                TextButton(
                  onPressed: onMarkAllRead,
                  child: Text(markAllReadLabel),
                ),
              if (onClearAll != null)
                TextButton(onPressed: onClearAll, child: Text(clearAllLabel)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Group section header.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: theme.spaceScale.of(FwSpace.s3, context),
        end: theme.spaceScale.of(FwSpace.s3, context),
        top: theme.spaceScale.of(FwSpace.s2, context),
        bottom: theme.spaceScale.of(FwSpace.s1, context),
      ),
      child: Text(
        title,
        style: theme.typeScale
            .resolve(FwTextRole.caption, context)
            .copyWith(color: theme.colors.of(FwColorRole.textMuted)),
      ),
    );
  }
}

/// One notification row: severity icon, title/body/time, unread dot,
/// tap for deep link, swipe or button to dismiss.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.onNotificationTap,
    required this.onMarkRead,
    required this.onDismiss,
  });

  final FwNotification notification;
  final ValueChanged<FwNotification>? onNotificationTap;
  final ValueChanged<String>? onMarkRead;
  final ValueChanged<String>? onDismiss;

  (IconData, FwColorRole) _style() => switch (notification.severity) {
    FwNotificationSeverity.info => (Icons.info_outline, FwColorRole.info),
    FwNotificationSeverity.success => (
      Icons.check_circle_outline,
      FwColorRole.success,
    ),
    FwNotificationSeverity.warning => (
      Icons.warning_amber_outlined,
      FwColorRole.warning,
    ),
    FwNotificationSeverity.error => (Icons.error_outline, FwColorRole.error),
  };

  String _relativeTime(DateTime timestamp) {
    final delta = DateTime.now().difference(timestamp);
    if (delta.inMinutes < 1) return 'now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final (icon, role) = _style();
    final row = InkWell(
      onTap: onNotificationTap == null
          ? null
          : () => onNotificationTap!(notification),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spaceScale.of(FwSpace.s3, context),
          vertical: theme.spaceScale.of(FwSpace.s2, context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(icon, size: 20, color: colors.of(role)),
            ),
            SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: typeScale
                              .resolve(FwTextRole.label, context)
                              .copyWith(
                                fontWeight: notification.read
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (notification.timestamp != null)
                        Text(
                          _relativeTime(notification.timestamp!),
                          style: typeScale
                              .resolve(FwTextRole.caption, context)
                              .copyWith(
                                color: colors.of(FwColorRole.textMuted),
                              ),
                        ),
                    ],
                  ),
                  if (notification.body != null)
                    Text(
                      notification.body!,
                      style: typeScale.resolve(FwTextRole.bodySm, context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Unread dot: the badge. Tapping it marks read.
            if (!notification.read)
              IconButton(
                icon: Icon(
                  Icons.circle,
                  size: 10,
                  color: colors.of(FwColorRole.primary),
                ),
                tooltip: 'Mark read',
                visualDensity: VisualDensity.compact,
                onPressed: onMarkRead == null
                    ? null
                    : () => onMarkRead!(notification.id),
              )
            else if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: () => onDismiss!(notification.id),
              ),
          ],
        ),
      ),
    );
    if (onDismiss == null) return row;
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss!(notification.id),
      background: Container(
        color: colors.of(FwColorRole.errorContainer),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 16),
        child: Icon(
          Icons.delete_outline,
          color: colors.of(FwColorRole.onErrorContainer),
        ),
      ),
      child: row,
    );
  }
}

/// Empty state: illustration slot + title + body.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.illustration,
    required this.title,
    required this.body,
  });

  final Widget? illustration;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final typeScale = theme.typeScale;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s6, context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Icon(
                  Icons.notifications_none,
                  size: 48,
                  color: theme.colors.of(FwColorRole.textMuted),
                ),
            SizedBox(height: theme.spaceScale.of(FwSpace.s3, context)),
            Text(title, style: typeScale.resolve(FwTextRole.h6, context)),
            if (body != null) ...[
              SizedBox(height: theme.spaceScale.of(FwSpace.s1, context)),
              Text(
                body!,
                style: typeScale
                    .resolve(FwTextRole.bodySm, context)
                    .copyWith(color: theme.colors.of(FwColorRole.textMuted)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unread badge.
// ---------------------------------------------------------------------------

/// Unread count badge for app bars / nav icons. Hides at zero.
class FwUnreadBadge extends StatelessWidget {
  const FwUnreadBadge({
    super.key,
    required this.count,
    this.max = 99,
    this.child,
  });

  /// Unread count; zero hides the badge.
  final int count;

  /// Counts above this render as "max+".
  final int max;

  /// The icon being badged. If null, renders the badge alone.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final label = count > max ? '$max+' : '$count';
    final badge = Semantics(
      label: '$count unread notifications',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.of(FwColorRole.error),
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.pill)),
        ),
        child: Text(
          label,
          style: theme.typeScale
              .resolve(FwTextRole.caption, context)
              .copyWith(color: colors.of(FwColorRole.onError)),
        ),
      ),
    );
    final icon = child;
    if (icon == null || count == 0) {
      return count == 0 ? (icon ?? const SizedBox.shrink()) : badge;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        PositionedDirectional(top: -4, end: -4, child: badge),
      ],
    );
  }
}
