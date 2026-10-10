import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'field.dart';
import 'form_controller.dart';
import 'text_input.dart';

/// Typed option for checkbox groups, radio groups, and selects.
///
/// [T] should implement value equality (or pass identical instances) so
/// selection compares by value, not by widget identity.
@immutable
class FwOption<T> {
  const FwOption({
    required this.value,
    required this.label,
    this.description,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? description;
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwOption<T> &&
          value == other.value &&
          label == other.label &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(value, label, enabled);
}

// ---------------------------------------------------------------------------
// F04 — password field.
// ---------------------------------------------------------------------------

/// Rough password-strength estimate for UX hints only.
///
/// Never presented as a security guarantee: a high score does not mean the
/// password is safe, and a low score must not block submission by itself.
double defaultPasswordStrength(String password) {
  var score = 0.0;
  if (password.length >= 8) score += 0.25;
  if (password.length >= 12) score += 0.25;
  if (RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[A-Z]').hasMatch(password)) {
    score += 0.25;
  }
  if (RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
    score += 0.25;
  }
  return score.clamp(0.0, 1.0);
}

/// Password input (F04): [FwTextField] with password defaults and a reveal
/// toggle.
///
/// Toggling reveal keeps the same controller and focus node, so selection
/// and focus are preserved. Pair with [FwPasswordStrengthBar] for the
/// optional strength presentation.
class FwPasswordField extends StatefulWidget {
  const FwPasswordField({
    super.key,
    required this.label,
    this.required = false,
    this.description,
    this.externalError,
    this.hintText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.autofocus = false,
    this.autofillHints = const [AutofillHints.password],
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.showReveal = true,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.formName,
  }) : assert(
         controller == null || initialValue == null,
         'Pass either a controller or an initialValue, not both.',
       );

  final String label;
  final bool required;
  final String? description;
  final String? externalError;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final bool autofocus;
  final Iterable<String> autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;

  /// Show the reveal toggle. When false the field stays obscured.
  final bool showReveal;

  final AutovalidateMode autovalidateMode;

  /// Forwarded to the inner [FwTextField]: registers with the nearest
  /// [FwForm]'s [FwFormController] under this name. Null (default) opts out.
  final String? formName;

  @override
  State<FwPasswordField> createState() => _FwPasswordFieldState();
}

class _FwPasswordFieldState extends State<FwPasswordField> {
  bool _obscured = true;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _internalFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(FwPasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode == null && oldWidget.focusNode != null) {
      _internalFocusNode = FocusNode();
    } else if (widget.focusNode != null && oldWidget.focusNode == null) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }
  }

  void _toggleReveal() {
    setState(() => _obscured = !_obscured);
    // Return focus to the field; the toggle button momentarily takes it.
    _effectiveFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FwTextField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      externalError: widget.externalError,
      hintText: widget.hintText,
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: widget.autofillHints,
      obscureText: _obscured,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autovalidateMode: widget.autovalidateMode,
      formName: widget.formName,
      suffixIcon: widget.showReveal
          ? IconButton(
              tooltip: _obscured ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscured ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
              onPressed: widget.enabled && !widget.readOnly
                  ? _toggleReveal
                  : null,
            )
          : null,
    );
  }
}

/// Optional strength presentation for [FwPasswordField].
///
/// Purely presentational: [strengthOf] maps the password to 0..1 and the bar
/// fills accordingly with an intent color. Compose below the field and feed
/// it the same controller text.
class FwPasswordStrengthBar extends StatelessWidget {
  const FwPasswordStrengthBar({
    super.key,
    required this.password,
    this.strengthOf = defaultPasswordStrength,
    this.label,
  });

  final String password;
  final double Function(String) strengthOf;

  /// Optional localized label, e.g. "Weak" / "Strong". When null, only the
  /// bar is shown (the bar itself is decorative).
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final theme = context.fwTheme;
    final strength = strengthOf(password);
    final intent = strength < 0.4
        ? FwIntent.danger
        : strength < 0.75
        ? FwIntent.warning
        : FwIntent.success;
    final roles = intentRoles(intent);
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.pill)),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 4,
              backgroundColor: theme.colors.of(
                FwColorRole.surfaceContainerHigh,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colors.of(roles.$1),
              ),
            ),
          ),
          if (label != null) ...[
            SizedBox(
              height: theme.spaceScale.resolveAlias(
                FwSpaceAlias.iconGap,
                context,
              ),
            ),
            Text(
              label!,
              style: theme.typeScale.resolve(FwTextRole.caption, context),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// F05 — checkbox and checkbox group.
// ---------------------------------------------------------------------------

/// Tri-state checkbox (F05) with a merged label semantics node.
///
/// [value] `null` renders the indeterminate (dash) state; requires
/// [tristate] to be true. Tapping cycles null -> true -> false -> true.
/// The whole row (box + label) is one semantic node: the inner [Checkbox]
/// is excluded from semantics and the outer node carries `checked`.
class FwCheckbox extends StatelessWidget {
  const FwCheckbox({
    super.key,
    required this.label,
    this.description,
    required this.value,
    this.tristate = false,
    this.onChanged,
    this.enabled = true,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         tristate || value != null,
         'value must not be null unless tristate is true',
       );

  final String label;
  final String? description;

  /// true = checked, false = unchecked, null = indeterminate (tristate).
  final bool? value;
  final bool tristate;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final String? errorText;
  final FocusNode? focusNode;
  final bool autofocus;

  bool? get _nextValue {
    if (!tristate) return !(value ?? false);
    return switch (value) {
      null => true,
      true => false,
      false => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final interactive = enabled && onChanged != null;
    final hasError = errorText != null;

    void toggle() => onChanged?.call(_nextValue);

    return Semantics(
      container: true,
      checked: value,
      enabled: interactive,
      label: label,
      hint: description,
      child: InkWell(
        onTap: interactive ? toggle : null,
        focusNode: focusNode,
        autofocus: autofocus,
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
        child: Padding(
          // P3.2: selection-row inset keeps its 4px base value and
          // compacts with density.
          padding: EdgeInsets.symmetric(
            vertical: theme.spaceScale.ofScaled(FwSpace.s1, context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Checkbox(
                  value: value,
                  tristate: tristate,
                  onChanged: interactive ? (_) => toggle() : null,
                  isError: hasError,
                ),
              ),
              // The container carries label + hint: keep a single node.
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.typeScale
                            .resolve(FwTextRole.body, context)
                            .copyWith(
                              color: enabled
                                  ? colors.of(FwColorRole.text)
                                  : colors.of(FwColorRole.textMuted),
                            ),
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: theme.typeScale
                              .resolve(FwTextRole.bodySm, context)
                              .copyWith(
                                color: colors.of(FwColorRole.textMuted),
                              ),
                        ),
                      if (hasError)
                        Text(
                          errorText!,
                          style: theme.typeScale
                              .resolve(FwTextRole.bodySm, context)
                              .copyWith(color: colors.of(FwColorRole.error)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Checkbox group (F05) over typed option IDs.
///
/// Uncontrolled by default ([initialValues]); pass [values] to control it.
/// Integrates with [Form] via [validator]/save/reset.
class FwCheckboxGroup<T> extends FormField<Set<T>> {
  FwCheckboxGroup({
    super.key,
    required this.label,
    required this.options,
    this.required = false,
    this.description,
    this.externalError,
    this.initialValues = const {},
    this.values,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.formName,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.restorationId,
    super.onSaved,
  }) : super(
         initialValue: values ?? initialValues,
         enabled: enabled,
         validator: validator,
         builder: (field) {
           final state = field as _FwCheckboxGroupState<T>;
           return state._build(field.context);
         },
       );

  final String label;
  final List<FwOption<T>> options;
  final bool required;
  final String? description;
  final String? externalError;
  final Set<T> initialValues;

  /// Controlled values. When provided, the parent owns the set.
  final Set<T>? values;
  final ValueChanged<Set<T>>? onChanged;
  final bool enabled;
  final FormFieldValidator<Set<T>>? validator;

  /// Name under which this field registers with the nearest [FwForm]'s
  /// [FwFormController]. Null (default) opts out.
  final String? formName;

  @override
  FormFieldState<Set<T>> createState() => _FwCheckboxGroupState<T>();
}

class _FwCheckboxGroupState<T> extends FormFieldState<Set<T>>
    with FwFormFieldRegistration<Set<T>> {
  @override
  FwCheckboxGroup<T> get widget => super.widget as FwCheckboxGroup<T>;

  @override
  String? get formName => widget.formName;

  @override
  void didUpdateWidget(FwCheckboxGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values != null && widget.values != value) {
      setValue(Set<T>.of(widget.values!));
    }
  }

  void _toggle(T option) {
    final next = Set<T>.of(value ?? const {});
    if (next.contains(option)) {
      next.remove(option);
    } else {
      next.add(option);
    }
    didChange(next);
    widget.onChanged?.call(next);
  }

  String? get displayError =>
      widget.externalError ?? formAsyncError ?? errorText;

  Widget _build(BuildContext context) {
    final selected = value ?? const {};
    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: displayError,
      enabled: widget.enabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in widget.options)
            FwCheckbox(
              label: option.label,
              description: option.description,
              value: selected.contains(option.value),
              onChanged: widget.enabled && option.enabled
                  ? (_) => _toggle(option.value)
                  : null,
              enabled: widget.enabled && option.enabled,
            ),
        ],
      ),
    );
  }

  @override
  void reset() {
    super.reset();
    setValue(Set<T>.of(widget.initialValues));
  }
}

// ---------------------------------------------------------------------------
// F06 — radio group.
// ---------------------------------------------------------------------------

/// Radio group (F06) over typed option IDs with arrow-key traversal.
///
/// Arrow up/left moves to the previous enabled option, arrow down/right to
/// the next; the newly focused option is selected. Each option exposes
/// mutually-exclusive `checked` semantics.
class FwRadioGroup<T> extends FormField<T> {
  FwRadioGroup({
    super.key,
    required this.label,
    required this.options,
    this.required = false,
    this.description,
    this.externalError,
    this.initialValue,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.formName,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.restorationId,
    super.onSaved,
  }) : super(
         initialValue: value ?? initialValue,
         enabled: enabled,
         validator: validator,
         builder: (field) {
           final state = field as _FwRadioGroupState<T>;
           return state._build(field.context);
         },
       );

  final String label;
  final List<FwOption<T>> options;
  final bool required;
  final String? description;
  final String? externalError;
  final T? initialValue;

  /// Controlled value. When provided, the parent owns the selection.
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final FormFieldValidator<T>? validator;

  /// Name under which this field registers with the nearest [FwForm]'s
  /// [FwFormController]. Null (default) opts out.
  final String? formName;

  @override
  FormFieldState<T> createState() => _FwRadioGroupState<T>();
}

class _FwRadioGroupState<T> extends FormFieldState<T>
    with FwFormFieldRegistration<T> {
  @override
  FwRadioGroup<T> get widget => super.widget as FwRadioGroup<T>;

  @override
  String? get formName => widget.formName;

  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = [for (var i = 0; i < widget.options.length; i++) FocusNode()];
  }

  @override
  void didUpdateWidget(FwRadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != value) {
      setValue(widget.value);
    }
    if (widget.options.length != oldWidget.options.length) {
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = [for (var i = 0; i < widget.options.length; i++) FocusNode()];
    }
  }

  void _select(T? optionValue) {
    didChange(optionValue);
    widget.onChanged?.call(optionValue);
  }

  /// Arrow-key traversal that skips disabled options. RadioGroup's own
  /// shortcuts don't skip disabled radios, so this handler runs first (it
  /// is an ancestor of the radio focus nodes) and consumes arrows.
  KeyEventResult _handleArrows(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final current = _nodes.indexWhere((n) => n.hasFocus);
    if (current == -1) return KeyEventResult.ignored;
    final int? delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowLeft => -1,
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    final options = widget.options;
    var next = current;
    for (var i = 0; i < options.length; i++) {
      next = (next + delta + options.length) % options.length;
      if (options[next].enabled && widget.enabled) {
        _nodes[next].requestFocus();
        _select(options[next].value);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  String? get displayError =>
      widget.externalError ?? formAsyncError ?? errorText;

  Widget _build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: displayError,
      enabled: widget.enabled,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (v) {
          didChange(v);
          widget.onChanged?.call(v);
        },
        child: Focus(
          onKeyEvent: (node, event) => _handleArrows(event),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                _optionRow(context, theme, colors, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionRow(
    BuildContext context,
    FwTheme theme,
    FwColors colors,
    int i,
  ) {
    final option = widget.options[i];
    final interactive =
        widget.enabled && option.enabled && widget.onChanged != null;
    return MergeSemantics(
      child: InkWell(
        // Tapping the row selects and moves focus to the radio, so arrow
        // keys work immediately after pointer interaction.
        onTap: interactive
            ? () {
                _nodes[i].requestFocus();
                _select(option.value);
              }
            : null,
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
        child: Padding(
          // P3.2: selection-row inset keeps its 4px base value and
          // compacts with density.
          padding: EdgeInsets.symmetric(
            vertical: theme.spaceScale.ofScaled(FwSpace.s1, context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<T>(
                value: option.value,
                enabled: interactive,
                focusNode: _nodes[i],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: theme.typeScale
                          .resolve(FwTextRole.body, context)
                          .copyWith(
                            color: interactive
                                ? colors.of(FwColorRole.text)
                                : colors.of(FwColorRole.textMuted),
                          ),
                    ),
                    if (option.description != null)
                      Text(
                        option.description!,
                        style: theme.typeScale
                            .resolve(FwTextRole.bodySm, context)
                            .copyWith(color: colors.of(FwColorRole.textMuted)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void reset() {
    super.reset();
    setValue(widget.initialValue);
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// F07 — switch.
// ---------------------------------------------------------------------------

/// Labeled switch (F07) with merged semantics.
///
/// The whole row is one semantic node carrying `checked`; the inner [Switch]
/// is excluded from semantics. [busy] replaces the switch with a spinner
/// and blocks interaction — the caller owns async state. Use for immediate
/// settings; for choices submitted with a form, prefer a checkbox.
class FwSwitch extends StatelessWidget {
  const FwSwitch({
    super.key,
    required this.label,
    this.description,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.busy = false,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  /// Async work in flight: spinner replaces the switch, input blocked.
  final bool busy;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final interactive = enabled && !busy && onChanged != null;

    void toggle() => onChanged?.call(!value);

    return Semantics(
      container: true,
      checked: value,
      enabled: interactive,
      label: label,
      hint: description,
      child: InkWell(
        onTap: interactive ? toggle : null,
        focusNode: focusNode,
        autofocus: autofocus,
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
        child: Padding(
          // P3.2: selection-row inset keeps its 4px base value and
          // compacts with density.
          padding: EdgeInsets.symmetric(
            vertical: theme.spaceScale.ofScaled(FwSpace.s1, context),
          ),
          child: Row(
            children: [
              // The container carries label + hint: keep a single node.
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.typeScale
                            .resolve(FwTextRole.body, context)
                            .copyWith(
                              color: enabled
                                  ? colors.of(FwColorRole.text)
                                  : colors.of(FwColorRole.textMuted),
                            ),
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: theme.typeScale
                              .resolve(FwTextRole.bodySm, context)
                              .copyWith(
                                color: colors.of(FwColorRole.textMuted),
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              if (busy)
                Semantics(
                  label: 'Loading',
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                ExcludeSemantics(
                  child: Switch(
                    value: value,
                    onChanged: interactive ? (_) => toggle() : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// F08 — simple select.
// ---------------------------------------------------------------------------

/// Simple select (F08) over typed option IDs.
///
/// Small option sets only — no remote fetch. [T] should implement value
/// equality; the selected value compares with `==` against option values.
/// Placeholder shows when nothing is selected; per-option [FwOption.enabled]
/// disables individual items.
class FwSelect<T> extends FormField<T> {
  FwSelect({
    super.key,
    required this.label,
    required this.options,
    this.placeholder = 'Select',
    this.required = false,
    this.description,
    this.externalError,
    this.initialValue,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.formName,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.restorationId,
    super.onSaved,
  }) : super(
         initialValue: value ?? initialValue,
         enabled: enabled,
         validator: validator,
         builder: (field) {
           final state = field as _FwSelectState<T>;
           return state._build(field.context);
         },
       );

  final String label;
  final List<FwOption<T>> options;
  final String placeholder;
  final bool required;
  final String? description;
  final String? externalError;
  final T? initialValue;

  /// Controlled value. When provided, the parent owns the selection.
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final FormFieldValidator<T>? validator;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Name under which this field registers with the nearest [FwForm]'s
  /// [FwFormController]. Null (default) opts out.
  final String? formName;

  @override
  FormFieldState<T> createState() => _FwSelectState<T>();
}

class _FwSelectState<T> extends FormFieldState<T>
    with FwFormFieldRegistration<T> {
  @override
  FwSelect<T> get widget => super.widget as FwSelect<T>;

  @override
  String? get formName => widget.formName;

  @override
  void didUpdateWidget(FwSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != value) {
      setValue(widget.value);
    }
  }

  String? get displayError =>
      widget.externalError ?? formAsyncError ?? errorText;

  Widget _build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final hasError = displayError != null;
    final interactive = widget.enabled && widget.onChanged != null;

    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: displayError,
      enabled: widget.enabled,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spaceScale.resolveAlias(
            FwSpaceAlias.controlInline,
            context,
          ),
        ),
        decoration: BoxDecoration(
          color: theme.colors.of(FwColorRole.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
          border: Border.all(
            color: hasError
                ? colors.of(FwColorRole.error)
                : colors.of(FwColorRole.border),
          ),
        ),
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            widget.placeholder,
            style: theme.typeScale
                .resolve(FwTextRole.body, context)
                .copyWith(color: colors.of(FwColorRole.textMuted)),
          ),
          isExpanded: true,
          underline: const SizedBox.shrink(),
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onChanged: interactive
              ? (next) {
                  didChange(next);
                  widget.onChanged?.call(next);
                }
              : null,
          items: [
            for (final option in widget.options)
              DropdownMenuItem<T>(
                value: option.value,
                enabled: option.enabled,
                child: Text(
                  option.label,
                  style: theme.typeScale.resolve(FwTextRole.body, context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void reset() {
    super.reset();
    setValue(widget.initialValue);
  }
}
