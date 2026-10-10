import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

// ---------------------------------------------------------------------------
// Command palette (P4): fuzzy-filtered command list with keyboard nav.
// ---------------------------------------------------------------------------

/// A single command in the palette.
class FwCommand {
  const FwCommand({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.keywords = const [],
    this.trailing,
  });

  /// Stable identifier returned on selection.
  final String id;

  /// Primary label. Matched by the fuzzy filter.
  final String title;

  /// Secondary label, shown under the title.
  final String? subtitle;

  /// Leading icon.
  final IconData? icon;

  /// Extra match terms (aliases, action names).
  final List<String> keywords;

  /// Trailing slot — typically a shortcut hint.
  final Widget? trailing;

  @override
  String toString() => 'FwCommand($id)';
}

/// Command palette (P4): a keyboard-first command launcher.
///
/// Type to fuzzy-filter [commands]; ArrowUp/ArrowDown moves the active
/// command, Enter selects it, Escape dismisses. Pass [onQuery] for an async
/// source (debounced by the caller if needed) — otherwise filtering is
/// local. Use [FwCommandPalette.show] for the standard modal presentation,
/// or embed the widget inline.
///
/// Demand note: enhancement-plan item (delivery.md — "command palette"
/// prioritized for 1.x by real application demand).
class FwCommandPalette extends StatefulWidget {
  const FwCommandPalette({
    super.key,
    this.commands = const [],
    this.onQuery,
    this.onSelected,
    this.placeholder = 'Type a command or search...',
    this.emptyText = 'No results found',
    this.loadingText = 'Loading...',
    this.autofocus = true,
    this.maxResults,
  });

  /// Static command list, filtered locally with fuzzy matching.
  /// Ignored when [onQuery] is set.
  final List<FwCommand> commands;

  /// Async source: called with the current query, returns matches.
  /// When set, local filtering is skipped.
  final Future<List<FwCommand>> Function(String query)? onQuery;

  /// Called when a command is selected (in addition to [show]'s future).
  final ValueChanged<FwCommand>? onSelected;

  final String placeholder;
  final String emptyText;
  final String loadingText;
  final bool autofocus;

  /// Cap on visible results. Null shows all.
  final int? maxResults;

  /// Shows the palette as a modal dialog, completing with the selected
  /// command or null on dismiss.
  static Future<FwCommand?> show({
    required BuildContext context,
    List<FwCommand> commands = const [],
    Future<List<FwCommand>> Function(String query)? onQuery,
    String placeholder = 'Type a command or search...',
    FwTheme? theme,
  }) {
    Widget palette = FwCommandPalette(
      commands: commands,
      onQuery: onQuery,
      placeholder: placeholder,
    );
    if (theme != null) {
      palette = FwThemeScope(theme: theme, child: palette);
    }
    return showDialog<FwCommand>(
      context: context,
      barrierLabel: 'Dismiss',
      builder: (dialogContext) {
        final s = dialogContext.fwTheme.spaceScale;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: s.of(FwSpace.s4, dialogContext),
            vertical: s.of(FwSpace.s10, dialogContext),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              dialogContext.fwTheme.radii.of(FwRadius.lg),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: palette,
          ),
        );
      },
    );
  }

  @override
  State<FwCommandPalette> createState() => _FwCommandPaletteState();
}

class _FwCommandPaletteState extends State<FwCommandPalette> {
  final _queryController = TextEditingController();
  final _listFocus = FocusNode();
  List<FwCommand> _results = [];
  int _active = 0;
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _results = _localFilter('');
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _listFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _queryController.text;
    if (widget.onQuery != null) {
      final gen = ++_generation;
      setState(() => _loading = true);
      widget.onQuery!(query).then((results) {
        if (!mounted || gen != _generation) return;
        setState(() {
          _results = _cap(results);
          _active = 0;
          _loading = false;
        });
      });
    } else {
      setState(() {
        _results = _localFilter(query);
        _active = 0;
      });
    }
  }

  List<FwCommand> _cap(List<FwCommand> results) {
    final max = widget.maxResults;
    if (max == null || results.length <= max) return results;
    return results.sublist(0, max);
  }

  List<FwCommand> _localFilter(String query) {
    if (query.isEmpty) return _cap(widget.commands);
    final scored = <(FwCommand, int)>[];
    for (final command in widget.commands) {
      final score = _fuzzyScore(query, command);
      if (score >= 0) scored.add((command, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return _cap([for (final s in scored) s.$1]);
  }

  /// Subsequence fuzzy score. -1 means no match; higher is better.
  /// Word-start and title matches score above keyword matches.
  static int _fuzzyScore(String query, FwCommand command) {
    final q = query.toLowerCase();
    var best = _subsequenceScore(q, command.title.toLowerCase(), 2);
    for (final keyword in command.keywords) {
      final s = _subsequenceScore(q, keyword.toLowerCase(), 1);
      if (s > best) best = s;
    }
    if (command.subtitle != null) {
      final s = _subsequenceScore(q, command.subtitle!.toLowerCase(), 1);
      if (s > best) best = s;
    }
    return best;
  }

  static int _subsequenceScore(String query, String target, int weight) {
    if (query.isEmpty) return 0;
    var score = 0;
    var ti = 0;
    for (var qi = 0; qi < query.length; qi++) {
      final qc = query[qi];
      var found = false;
      while (ti < target.length) {
        final tc = target[ti];
        ti++;
        if (tc == qc) {
          found = true;
          // Bonus for word-start matches.
          if (ti == 1 || target[ti - 2] == ' ') score += 10;
          // Bonus for consecutive matches.
          if (qi > 0 && ti >= 2 && target[ti - 2] == query[qi - 1]) {
            score += 5;
          }
          score += 1;
          break;
        }
      }
      if (!found) return -1;
    }
    // Bonus for shorter targets (more specific match).
    score += (100 - target.length).clamp(0, 50);
    return score * weight;
  }

  void _select(FwCommand command) {
    widget.onSelected?.call(command);
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && ModalRoute.of(context) is PopupRoute) {
      navigator.pop(command);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_results.isNotEmpty) {
        setState(() => _active = (_active + 1) % _results.length);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_results.isNotEmpty) {
        setState(
          () => _active = (_active - 1 + _results.length) % _results.length,
        );
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_results.isNotEmpty) _select(_results[_active]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final s = theme.spaceScale;

    return Focus(
      focusNode: _listFocus,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(s.of(FwSpace.s3, context)),
            child: TextField(
              controller: _queryController,
              autofocus: widget.autofocus,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
              ),
              onSubmitted: (_) {
                if (_results.isNotEmpty) _select(_results[_active]);
              },
            ),
          ),
          const Divider(height: 1),
          if (_loading)
            Padding(
              padding: EdgeInsets.all(s.of(FwSpace.s4, context)),
              child: Text(widget.loadingText),
            )
          else if (_results.isEmpty)
            Padding(
              padding: EdgeInsets.all(s.of(FwSpace.s4, context)),
              child: Text(widget.emptyText),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final command = _results[index];
                  final active = index == _active;
                  return InkWell(
                    onTap: () => _select(command),
                    onHover: (_) => setState(() => _active = index),
                    child: Container(
                      color: active
                          ? colors.of(FwColorRole.surfaceContainerHighest)
                          : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: s.of(FwSpace.s4, context),
                        vertical: s.of(FwSpace.s2, context),
                      ),
                      child: Row(
                        children: [
                          if (command.icon != null) ...[
                            Icon(
                              command.icon,
                              size: theme.iconSizes.of(FwIconSize.md),
                              color: colors.of(FwColorRole.onSurfaceMuted),
                            ),
                            SizedBox(width: s.of(FwSpace.s3, context)),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  command.title,
                                  style: theme.typeScale.resolve(
                                    FwTextRole.label,
                                    context,
                                  ),
                                ),
                                if (command.subtitle != null)
                                  Text(
                                    command.subtitle!,
                                    style: theme.typeScale.resolve(
                                      FwTextRole.bodySm,
                                      context,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (command.trailing != null) command.trailing!,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
