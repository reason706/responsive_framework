/// Phase 4 feedback: upload/task progress list (B08).
library;

import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

// ---------------------------------------------------------------------------
// Upload/task progress list (B08).
// ---------------------------------------------------------------------------

/// Lifecycle status of one task.
enum FwTaskStatus { queued, running, succeeded, failed, cancelled }

/// One unit of background work. Pure data — transport (upload/download)
/// lives in the app or an optional adapter; this renders state.
class FwTask {
  const FwTask({
    required this.id,
    required this.label,
    this.status = FwTaskStatus.queued,
    this.progress,
    this.detail,
  }) : assert(
         progress == null || (progress >= 0 && progress <= 1),
         'progress must be between 0 and 1.',
       );

  /// Stable ID used for cancel/retry/dismiss callbacks.
  final String id;

  final String label;

  final FwTaskStatus status;

  /// 0..1 when totals are known; null renders an indeterminate bar.
  /// Only aggregate into a summary when every task reports totals.
  final double? progress;

  /// Optional human detail, e.g. "3.2 MB of 8 MB" or an error message.
  final String? detail;

  FwTask copyWith({FwTaskStatus? status, double? progress, String? detail}) =>
      FwTask(
        id: id,
        label: label,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        detail: detail ?? this.detail,
      );
}

/// Progress list over typed task state (B08).
///
/// Each row shows a status icon, label, progress (bar or detail text), and
/// contextual actions: cancel while queued/running, retry after failure,
/// dismiss once finished. The list itself is presentation-only.
class FwTaskList extends StatelessWidget {
  const FwTaskList({
    super.key,
    required this.tasks,
    this.onCancel,
    this.onRetry,
    this.onDismiss,
    this.emptyText = 'No tasks',
  });

  final List<FwTask> tasks;

  /// Cancel a queued/running task, by task id.
  final ValueChanged<String>? onCancel;

  /// Retry a failed/cancelled task, by task id.
  final ValueChanged<String>? onRetry;

  /// Dismiss a finished task from the list, by task id.
  final ValueChanged<String>? onDismiss;

  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(
          context.fwTheme.spaceScale.of(FwSpace.s4, context),
        ),
        child: Center(child: Text(emptyText)),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _TaskRow(
        task: tasks[index],
        onCancel: onCancel,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// One task row.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onCancel,
    required this.onRetry,
    required this.onDismiss,
  });

  final FwTask task;
  final ValueChanged<String>? onCancel;
  final ValueChanged<String>? onRetry;
  final ValueChanged<String>? onDismiss;

  (IconData, FwColorRole) _statusStyle() => switch (task.status) {
    FwTaskStatus.queued => (Icons.schedule, FwColorRole.textMuted),
    FwTaskStatus.running => (Icons.sync, FwColorRole.info),
    FwTaskStatus.succeeded => (Icons.check_circle, FwColorRole.success),
    FwTaskStatus.failed => (Icons.error, FwColorRole.error),
    FwTaskStatus.cancelled => (Icons.cancel, FwColorRole.textMuted),
  };

  bool get _active =>
      task.status == FwTaskStatus.queued || task.status == FwTaskStatus.running;

  bool get _failed =>
      task.status == FwTaskStatus.failed ||
      task.status == FwTaskStatus.cancelled;

  bool get _finished => !_active;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final (icon, role) = _statusStyle();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spaceScale.of(FwSpace.s3, context),
        vertical: theme.spaceScale.of(FwSpace.s2, context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: theme.spaceScale.resolveAlias(FwSpaceAlias.iconGap, context),
            ),
            child: Icon(icon, size: 20, color: colors.of(role)),
          ),
          SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.label,
                  style: typeScale.resolve(FwTextRole.label, context),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_active) ...[
                  SizedBox(height: theme.spaceScale.of(FwSpace.s1, context)),
                  task.progress == null
                      ? const LinearProgressIndicator()
                      : LinearProgressIndicator(value: task.progress),
                ],
                if (task.detail != null)
                  Text(
                    task.detail!,
                    style: typeScale
                        .resolve(FwTextRole.caption, context)
                        .copyWith(color: colors.of(FwColorRole.textMuted)),
                  ),
              ],
            ),
          ),
          if (_active && onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Cancel ${task.label}',
              visualDensity: VisualDensity.compact,
              onPressed: () => onCancel!(task.id),
            ),
          if (_failed && onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Retry ${task.label}',
              visualDensity: VisualDensity.compact,
              onPressed: () => onRetry!(task.id),
            ),
          if (_finished && onDismiss != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Dismiss ${task.label}',
              visualDensity: VisualDensity.compact,
              onPressed: () => onDismiss!(task.id),
            ),
        ],
      ),
    );
  }
}
