import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Which side a chat bubble sits on.
enum FwChatSide {
  /// Current user's message: end-aligned, primary tint.
  sent,

  /// Other party's message: start-aligned, surface tint.
  received,
}

/// Delivery status for sent messages.
enum FwChatStatus { sending, sent, delivered, read }

/// Chat bubble.
///
/// A single message with an asymmetric bubble (the tail side is less
/// rounded), optional sender name, timestamp, and delivery ticks for sent
/// messages. [side] drives alignment and tint; [status] only renders for
/// [FwChatSide.sent].
class FwChatBubble extends StatelessWidget {
  const FwChatBubble({
    super.key,
    required this.message,
    required this.side,
    this.senderName,
    this.timestamp,
    this.status,
  });

  final String message;
  final FwChatSide side;
  final String? senderName;
  final String? timestamp;
  final FwChatStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final sent = side == FwChatSide.sent;

    final bubbleColor = sent
        ? colors.of(FwColorRole.primary)
        : colors.of(FwColorRole.surfaceContainerHighest);
    final textColor = sent
        ? colors.of(FwColorRole.onPrimary)
        : colors.of(FwColorRole.text);
    final metaColor = sent
        ? colors.of(FwColorRole.onPrimary).withValues(alpha: 0.75)
        : colors.of(FwColorRole.textMuted);

    final radius = theme.radii.of(FwRadius.lg);
    final tight = theme.radii.of(FwRadius.sm);

    return Semantics(
      container: true,
      label:
          '${sent ? 'You' : senderName ?? 'Them'}: $message${timestamp == null ? '' : ', $timestamp'}',
      child: Row(
        mainAxisAlignment: sent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: EdgeInsets.symmetric(
                horizontal: theme.spaceScale.of(FwSpace.s3, context),
                vertical: theme.spaceScale.of(FwSpace.s2, context),
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(sent ? radius : tight),
                  topRight: Radius.circular(sent ? tight : radius),
                  bottomLeft: Radius.circular(radius),
                  bottomRight: Radius.circular(radius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!sent && senderName != null)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: theme.spaceScale.of(FwSpace.s1, context),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          senderName!,
                          style: theme.typeScale
                              .resolve(FwTextRole.label, context)
                              .copyWith(color: colors.of(FwColorRole.primary)),
                        ),
                      ),
                    ),
                  ExcludeSemantics(
                    child: Text(
                      message,
                      style: theme.typeScale
                          .resolve(FwTextRole.body, context)
                          .copyWith(color: textColor),
                    ),
                  ),
                  if (timestamp != null || (sent && status != null))
                    Padding(
                      padding: EdgeInsets.only(
                        top: theme.spaceScale.of(FwSpace.s1, context),
                      ),
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (timestamp != null)
                              Text(
                                timestamp!,
                                style: theme.typeScale
                                    .resolve(FwTextRole.caption, context)
                                    .copyWith(color: metaColor),
                              ),
                            if (sent && status != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                switch (status!) {
                                  FwChatStatus.sending => Icons.access_time,
                                  FwChatStatus.sent => Icons.check,
                                  FwChatStatus.delivered => Icons.done_all,
                                  FwChatStatus.read => Icons.done_all,
                                },
                                size: 14,
                                color: status == FwChatStatus.read
                                    ? colors.of(FwColorRole.info)
                                    : metaColor,
                                semanticLabel: status!.name,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
