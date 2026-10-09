import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// An event on a [FwTimeline].
class FwTimelineEvent {
  const FwTimelineEvent({
    required this.title,
    this.timeLabel,
    this.description,
    this.icon,
    this.intent = FwIntent.primary,
  });

  /// Event title.
  final String title;

  /// Preformatted timestamp ("2h ago", "10:30"). Null hides the time.
  final String? timeLabel;

  /// Optional detail text.
  final String? description;

  /// Glyph inside the dot. Null keeps the plain dot.
  final IconData? icon;

  /// Intent tinting the dot.
  final FwIntent intent;
}

/// Timeline / activity feed.
///
/// A vertical rail of dots connected by a line; each event shows its time,
/// title, and optional description. The rail is decorative — semantics read
/// the events as a list.
class FwTimeline extends StatelessWidget {
  const FwTimeline({super.key, required this.events, this.dense = false});

  /// Events in display order (top = first).
  final List<FwTimelineEvent> events;

  /// Compact spacing.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final titleStyle = theme.typeScale.resolve(FwTextRole.label, context);
    final timeStyle = theme.typeScale
        .resolve(FwTextRole.caption, context)
        .copyWith(color: colors.of(FwColorRole.textMuted));
    final descStyle = theme.typeScale.resolve(FwTextRole.body, context);
    final dotSize = dense ? 28.0 : 36.0;
    final lineColor = colors.of(FwColorRole.border);

    return Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < events.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Rail: dot centered on a vertical line (no line stub
                  // above the first dot / below the last).
                  SizedBox(
                    width: dotSize,
                    child: Column(
                      children: [
                        Container(
                          height: (dotSize - 12) / 2,
                          width: 2,
                          color: i == 0 ? null : lineColor,
                        ),
                        Container(
                          width: dotSize - 12,
                          height: dotSize - 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.of(intentRoles(events[i].intent).$1),
                          ),
                          alignment: Alignment.center,
                          child: events[i].icon == null
                              ? null
                              : Icon(
                                  events[i].icon,
                                  size: 16,
                                  color: colors.of(
                                    intentRoles(events[i].intent).$2,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: i == events.length - 1 ? null : lineColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: theme.spaceScale.of(
                          dense ? FwSpace.s3 : FwSpace.s4,
                          context,
                        ),
                      ),
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (events[i].timeLabel != null)
                              Text(events[i].timeLabel!, style: timeStyle),
                            Text(events[i].title, style: titleStyle),
                            if (events[i].description != null)
                              Text(events[i].description!, style: descStyle),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
