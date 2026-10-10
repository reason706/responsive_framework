/// Tag input (+F25): chips inside the field.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'field.dart';
import 'text.dart';

/// Tag input (+F25): an inline chip editor for short token lists —
/// skills, recipients, labels, filters.
///
/// Tags render as removable [FwChip]s inside the field box; typing a
/// separator (comma/semicolon by default) or pressing Enter commits the
/// text as a tag. Backspace on empty input removes the last tag. Everything
/// is keyboard-operable: each chip's remove button is focusable, and the
/// input is a plain text field.
///
/// Controlled: [value] is the source of truth, [onChanged] reports edits.
/// Integrates with Flutter [Form] via [validator], `save`/`reset`, and
/// [autovalidateMode]. Per-tag [tagValidator] rejects individual tags with
/// a transient message; [validator] validates the whole list.
///
/// Example:
/// ```dart
/// FwTagInput(
///   label: 'Skills',
///   value: tags,
///   onChanged: (v) => setState(() => tags = v),
///   maxTags: 5,
///   description: 'Press Enter after each skill.',
/// )
/// ```
class FwTagInput extends FormField<List<String>> {
  FwTagInput({
    super.key,
    required this.label,
    this.value = const [],
    this.onChanged,
    this.hintText,
    this.description,
    this.required = false,
    this.enabled = true,
    this.maxTags,
    this.separators = const {',', ';'},
    this.allowDuplicates = false,
    this.tagValidator,
    this.externalError,
    this.autofocus = false,
    super.validator,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.restorationId,
    super.onSaved,
  }) : assert(maxTags == null || maxTags > 0, 'maxTags must be positive'),
       super(
         initialValue: value,
         enabled: enabled,
         builder: (field) {
           final state = field as _FwTagInputState;
           return state._build(field.context);
         },
       );

  /// Persistent visible label, rendered by the shell.
  final String label;

  /// Current tags. `const []` means "no tags yet".
  final List<String> value;

  /// Fired with the new tag list after every add/remove.
  final ValueChanged<List<String>>? onChanged;

  /// Placeholder inside the input when there are no tags and no text.
  final String? hintText;

  /// Persistent guidance under the editor.
  final String? description;

  final bool required;
  final bool enabled;

  /// Maximum number of tags. Further commits are rejected with a message.
  final int? maxTags;

  /// Characters that commit the current text as tag(s). Typing any of these
  /// splits the input and commits each part.
  final Set<String> separators;

  /// When false (default), adding an existing tag is rejected with a message.
  final bool allowDuplicates;

  /// Per-tag validation. Return an error message to reject the tag, or null
  /// to accept it. Runs at commit time, before [maxTags]/duplicate checks.
  final FormFieldValidator<String>? tagValidator;

  /// Error supplied from outside (e.g. server-side). Shown immediately and
  /// takes precedence over validator output.
  final String? externalError;

  final bool autofocus;

  @override
  FormFieldState<List<String>> createState() => _FwTagInputState();
}

class _FwTagInputState extends FormFieldState<List<String>> {
  @override
  FwTagInput get widget => super.widget as FwTagInput;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;
  String? _transientError;

  String? get displayError =>
      widget.externalError ?? _transientError ?? errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode(
      debugLabel: 'FwTagInput',
      onKeyEvent: _handleKeyEvent,
    );
    _focusNode.addListener(_handleFocusChanged);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty &&
        widget.value.isNotEmpty &&
        widget.enabled) {
      _removeAt(widget.value.length - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleTextChanged() {
    if (_transientError != null) {
      setState(() => _transientError = null);
    }
    final text = _controller.text;
    if (widget.separators.any(text.contains)) {
      _commitText();
    }
  }

  /// Commits the current input text as one or more tags.
  void _commitText() {
    final raw = _controller.text;
    if (raw.trim().isEmpty) {
      _controller.clear();
      return;
    }
    final pattern = RegExp('[${RegExp.escape(widget.separators.join())}]');
    final tags = List<String>.of(widget.value);
    String? rejection;
    for (final part in raw.split(pattern)) {
      final tag = part.trim();
      if (tag.isEmpty) continue;
      final tagError = widget.tagValidator?.call(tag);
      if (tagError != null) {
        rejection ??= tagError;
        continue;
      }
      if (!widget.allowDuplicates && tags.contains(tag)) {
        rejection ??= '“$tag” is already added.';
        continue;
      }
      if (widget.maxTags != null && tags.length >= widget.maxTags!) {
        rejection ??= 'Maximum ${widget.maxTags} tags.';
        break;
      }
      tags.add(tag);
    }
    _controller.clear();
    setState(() => _transientError = rejection);
    if (tags.length != widget.value.length) {
      didChange(tags);
      widget.onChanged?.call(tags);
    }
  }

  void _removeAt(int index) {
    final tags = List<String>.of(widget.value)..removeAt(index);
    setState(() => _transientError = null);
    didChange(tags);
    widget.onChanged?.call(tags);
    // Keep focus in the input so keyboard users can keep editing.
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }

  Widget _build(BuildContext context) {
    final theme = context.fwTheme;
    final tags = widget.value;
    final hasError = displayError != null;
    final colors = theme.colors;
    final borderColor = !widget.enabled
        ? colors.of(FwColorRole.disabled)
        : hasError
        ? colors.of(FwColorRole.error)
        : _focused
        ? colors.of(FwColorRole.focusRing)
        : colors.of(FwColorRole.border);
    final radius = BorderRadius.circular(theme.radii.of(FwRadius.md));
    final chipGap = theme.spaceScale.of(FwSpace.s2, context);

    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: displayError,
      enabled: widget.enabled,
      child: Container(
        decoration: BoxDecoration(
          color: colors.of(FwColorRole.surfaceContainerHighest),
          border: Border.all(
            color: borderColor,
            width: (_focused || hasError) ? 2 : 1,
          ),
          borderRadius: radius,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: theme.spaceScale.resolveAlias(
            FwSpaceAlias.controlInline,
            context,
          ),
          vertical: theme.spaceScale.resolveAlias(
            FwSpaceAlias.controlBlock,
            context,
          ),
        ),
        child: Wrap(
          spacing: chipGap,
          runSpacing: chipGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < tags.length; i++)
              FwChip(
                kind: FwChipKind.input,
                label: tags[i],
                enabled: widget.enabled,
                onDeleted: widget.enabled ? () => _removeAt(i) : null,
                deleteTooltip: 'Remove “${tags[i]}”',
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: IntrinsicWidth(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _commitText(),
                  style: theme.typeScale.resolve(FwTextRole.body, context),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: tags.isEmpty ? widget.hintText : null,
                    hintStyle: theme.typeScale
                        .resolve(FwTextRole.body, context)
                        .copyWith(color: colors.of(FwColorRole.textMuted)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
