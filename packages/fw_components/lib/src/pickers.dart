/// Phase 4 pickers and advanced inputs: range slider (F10), number
/// field (F11), combobox (F13), multi-select (F14), date field (F15),
/// and time field (F16).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'dialog.dart';
import 'button.dart';
import 'field.dart';
import 'menu.dart';
import 'selection.dart';
import 'text_input.dart';

// ---------------------------------------------------------------------------
// Range slider (F10).
// ---------------------------------------------------------------------------

/// Range slider with two endpoints (F10).
///
/// A two-thumb [RangeSlider] adapted to framework tokens with a label row
/// and a formatted range readout. Endpoints stay ordered — the platform
/// enforces `start <= end` — and both thumbs get native semantics.
///
/// In RTL layouts the value axis mirrors (platform behavior); the readout
/// string is localizable via [valueFormatter].
class FwRangeSlider extends StatelessWidget {
  const FwRangeSlider({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChangeEnd,
    this.enabled = true,
    this.valueFormatter,
    this.unit,
  });

  /// Field label shown above the slider.
  final String label;

  /// Current endpoints, kept ordered with `start <= end`.
  final RangeValues values;

  /// Fired while a thumb drags.
  final ValueChanged<RangeValues> onChanged;

  final double min;
  final double max;
  final int? divisions;

  /// Fired when the user releases a thumb.
  final ValueChanged<RangeValues>? onChangeEnd;

  final bool enabled;

  /// Formats the `(start, end)` pair for the readout. Defaults to
  /// `"20 – 80"` (appending [unit] when set).
  final String Function(double start, double end)? valueFormatter;

  /// Unit suffix appended to the default readout, e.g. `"%"`.
  final String? unit;

  String _readout(BuildContext context) {
    if (valueFormatter != null) {
      return valueFormatter!(values.start, values.end);
    }
    String fmt(double v) =>
        divisions == null ? v.toStringAsFixed(1) : v.round().toString();
    final suffix = unit ?? '';
    return '${fmt(values.start)}$suffix – ${fmt(values.end)}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final onChanged = enabled ? this.onChanged : null;
    return Semantics(
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: typeScale.resolve(FwTextRole.label, context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _readout(context),
                  style: typeScale
                      .resolve(FwTextRole.bodySm, context)
                      .copyWith(color: colors.of(FwColorRole.textMuted)),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: values,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            min: min,
            max: max,
            divisions: divisions,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Number field (F11).
// ---------------------------------------------------------------------------

/// Number input with increment/decrement actions (F11).
///
/// [value] is nullable: `null` means "empty", not "invalid". Intermediate
/// text while typing is never coerced; on submit or focus loss the text is
/// parsed (decimal-aware) and clamped to [min]/[max], or the field reverts
/// to the last valid value. Stepper actions clamp and round to
/// [decimalPlaces]. While an IME composition is active, no reformatting
/// happens mid-keystroke.
class FwNumberField extends StatefulWidget {
  const FwNumberField({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.decimalPlaces = 0,
    this.enabled = true,
    this.required = false,
    this.description,
    this.externalError,
    this.validator,
  }) : assert(step > 0, 'step must be positive'),
       assert(decimalPlaces >= 0, 'decimalPlaces cannot be negative');

  /// Field label.
  final String label;

  /// Current value; `null` renders as empty text.
  final double? value;

  /// Fired with the committed value, or `null` when cleared.
  final ValueChanged<double?> onChanged;

  final double? min;
  final double? max;

  /// Stepper increment; must be positive.
  final double step;

  /// Decimals preserved by the stepper and the default formatter.
  final int decimalPlaces;

  final bool enabled;
  final bool required;
  final String? description;
  final String? externalError;
  final FormFieldValidator<double>? validator;

  @override
  State<FwNumberField> createState() => _FwNumberFieldState();
}

class _FwNumberFieldState extends State<FwNumberField> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(FwNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only resync from the outside while the user isn't mid-edit.
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(widget.decimalPlaces);
  }

  double _round(double value) {
    final factor = _pow10(widget.decimalPlaces);
    return (value * factor).round() / factor;
  }

  static double _pow10(int n) {
    var result = 1.0;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  double? _parse(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  double? _clamp(double? value) {
    if (value == null) return null;
    var v = _round(value);
    if (widget.min != null && v < widget.min!) v = widget.min!;
    if (widget.max != null && v > widget.max!) v = widget.max!;
    return v;
  }

  /// Commits the current text: valid numbers clamp and round, empty
  /// clears to `null`, invalid text reverts to the last valid value.
  void _commit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (widget.value != null) widget.onChanged(null);
      return;
    }
    final parsed = _parse(text);
    if (parsed == null) {
      // Invalid intermediate text: revert, don't coerce.
      _controller.text = _format(widget.value);
      return;
    }
    final clamped = _clamp(parsed)!;
    _controller.text = _format(clamped);
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  void _step(double direction) {
    if (!widget.enabled) return;
    final base = widget.value ?? 0;
    final next = _clamp(base + direction * widget.step)!;
    _controller.text = _format(next);
    widget.onChanged(next);
    context.fwTheme.haptics.tap(context);
  }

  @override
  Widget build(BuildContext context) {
    return FwTextField(
      label: widget.label,
      controller: _controller,
      required: widget.required,
      description: widget.description,
      externalError: widget.externalError,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))],
      onChanged: (_) => _editing = true,
      onSubmitted: (_) {
        _editing = false;
        _commit();
      },
      validator: (_) {
        if (widget.validator != null) {
          return widget.validator!(widget.value);
        }
        return null;
      },
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            semanticLabel: 'Decrement',
            onPressed: widget.enabled ? () => _step(-1) : null,
          ),
          _StepperButton(
            icon: Icons.add,
            semanticLabel: 'Increment',
            onPressed: widget.enabled ? () => _step(1) : null,
          ),
        ],
      ),
    );
  }
}

/// Icon-only button used by the number stepper.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: semanticLabel,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ---------------------------------------------------------------------------
// Combobox (F13).
// ---------------------------------------------------------------------------

/// Builds suggestions for a query. May return a list synchronously (local
/// filter) or a future (async fetch).
typedef FwSuggestionsBuilder<T> =
    FutureOr<List<FwOption<T>>> Function(String query);

enum _ComboStatus { idle, loading, error }

/// Combobox / autocomplete (F13): a text field with an anchored suggestion
/// listbox.
///
/// [suggestionsBuilder] serves both local filtering (return a list) and
/// async sources (return a future). Async results are guarded by debounce
/// plus sequence IDs: only the latest query's results are applied, so
/// stale responses can never corrupt the selection.
///
/// Keyboard: ArrowDown/ArrowUp moves the active option (opening the
/// listbox first), Enter selects it, Escape closes. Disabled options are
/// skipped by both pointer and keyboard.
class FwCombobox<T> extends StatefulWidget {
  const FwCombobox({
    super.key,
    required this.label,
    this.selectedOption,
    required this.onSelected,
    required this.suggestionsBuilder,
    this.debounce = const Duration(milliseconds: 200),
    this.enabled = true,
    this.required = false,
    this.hintText,
    this.description,
    this.externalError,
    this.emptyText = 'No results',
    this.loadingText = 'Loading…',
    this.errorText = 'Could not load suggestions',
  });

  /// Field label.
  final String label;

  /// Currently selected option; its label fills the field.
  final FwOption<T>? selectedOption;

  /// Fired with the picked option, or `null` when the field is cleared.
  final ValueChanged<FwOption<T>?> onSelected;

  /// Suggestion source for the current query.
  final FwSuggestionsBuilder<T> suggestionsBuilder;

  /// Debounce before an async fetch starts.
  final Duration debounce;

  final bool enabled;
  final bool required;
  final String? hintText;
  final String? description;
  final String? externalError;
  final String emptyText;
  final String loadingText;
  final String errorText;

  @override
  State<FwCombobox<T>> createState() => _FwComboboxState<T>();
}

class _FwComboboxState<T> extends State<FwCombobox<T>> {
  late final TextEditingController _controller;
  late final FocusNode _fieldFocus;
  final _popoverController = FwPopoverController();
  Timer? _debounce;
  int _queryId = 0;
  List<FwOption<T>> _options = const [];
  int _activeIndex = -1;
  _ComboStatus _status = _ComboStatus.idle;
  bool _suppressQuery = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedOption?.label ?? '',
    );
    _fieldFocus = FocusNode();
  }

  @override
  void didUpdateWidget(FwCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedOption != widget.selectedOption &&
        !_fieldFocus.hasFocus) {
      _controller.text = widget.selectedOption?.label ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryId++; // Invalidate any in-flight fetch.
    _controller.dispose();
    _fieldFocus.dispose();
    _popoverController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (_suppressQuery) return;
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!widget.enabled) return;
    final id = ++_queryId;
    setState(() => _status = _ComboStatus.loading);
    _popoverController.show();
    List<FwOption<T>> results;
    try {
      results = await widget.suggestionsBuilder(query);
    } catch (_) {
      // Stale or failed: only the latest query may update state.
      if (!mounted || id != _queryId) return;
      setState(() => _status = _ComboStatus.error);
      return;
    }
    if (!mounted || id != _queryId) return;
    setState(() {
      _options = results;
      _activeIndex = results.isEmpty ? -1 : 0;
      _status = _ComboStatus.idle;
    });
  }

  void _select(FwOption<T> option) {
    if (!option.enabled) return;
    _debounce?.cancel();
    _queryId++; // Invalidate in-flight fetches.
    _suppressQuery = true;
    _controller.text = option.label;
    _suppressQuery = false;
    _popoverController.hide();
    context.fwTheme.haptics.selection(context);
    widget.onSelected(option);
  }

  void _moveActive(int delta) {
    if (_options.isEmpty) return;
    var next = _activeIndex + delta;
    // Skip disabled options.
    while (next >= 0 && next < _options.length && !_options[next].enabled) {
      next += delta;
    }
    if (next >= 0 && next < _options.length) {
      setState(() => _activeIndex = next);
    }
  }

  KeyEventResult _onFieldKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (!_popoverController.isShowing) {
          _search(_controller.text);
        } else {
          _moveActive(1);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (_popoverController.isShowing) _moveActive(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        if (_popoverController.isShowing &&
            _activeIndex >= 0 &&
            _activeIndex < _options.length) {
          _select(_options[_activeIndex]);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.escape:
        if (_popoverController.isShowing) {
          _popoverController.hide();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }

  Widget _listbox(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    switch (_status) {
      case _ComboStatus.loading:
        return Padding(
          padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s3, context)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
              Text(
                widget.loadingText,
                style: typeScale.resolve(FwTextRole.bodySm, context),
              ),
            ],
          ),
        );
      case _ComboStatus.error:
        return Padding(
          padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s3, context)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: colors.of(FwColorRole.error),
              ),
              SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
              Flexible(
                child: Text(
                  widget.errorText,
                  style: typeScale.resolve(FwTextRole.bodySm, context),
                ),
              ),
            ],
          ),
        );
      case _ComboStatus.idle:
        if (_options.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(theme.spaceScale.of(FwSpace.s3, context)),
            child: Text(
              widget.emptyText,
              style: typeScale
                  .resolve(FwTextRole.bodySm, context)
                  .copyWith(color: colors.of(FwColorRole.textMuted)),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final option = _options[index];
              final active = index == _activeIndex;
              return _SuggestionTile(
                option: option,
                active: active,
                onTap: () => _select(option),
              );
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FwPopover(
      controller: _popoverController,
      autofocusContent: false,
      dismissOnTapOutside: true,
      anchor: Focus(
        onKeyEvent: _onFieldKey,
        child: FwTextField(
          label: widget.label,
          controller: _controller,
          focusNode: _fieldFocus,
          required: widget.required,
          hintText: widget.hintText,
          description: widget.description,
          externalError: widget.externalError,
          enabled: widget.enabled,
          onChanged: _onQueryChanged,
          suffix: IconButton(
            icon: Icon(
              _popoverController.isShowing
                  ? Icons.arrow_drop_up
                  : Icons.arrow_drop_down,
            ),
            tooltip: 'Show suggestions',
            onPressed: widget.enabled
                ? () {
                    if (_popoverController.isShowing) {
                      _popoverController.hide();
                    } else {
                      _search(_controller.text);
                    }
                  }
                : null,
          ),
        ),
      ),
      content: _listbox(context),
    );
  }
}

/// One suggestion row in the combobox listbox.
class _SuggestionTile<T> extends StatelessWidget {
  const _SuggestionTile({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final FwOption<T> option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    return Material(
      color: active
          ? colors.of(FwColorRole.surfaceContainerHighest)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
      child: InkWell(
        onTap: option.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spaceScale.of(FwSpace.s3, context),
            vertical: theme.spaceScale.of(FwSpace.s2, context),
          ),
          child: Opacity(
            opacity: option.enabled ? 1 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  style: theme.typeScale.resolve(FwTextRole.body, context),
                ),
                if (option.description != null)
                  Text(
                    option.description!,
                    style: theme.typeScale
                        .resolve(FwTextRole.caption, context)
                        .copyWith(color: colors.of(FwColorRole.textMuted)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-select (F14).
// ---------------------------------------------------------------------------

/// Multi-select with tags (F14): a collapsed box of removable chips that
/// opens a searchable checkbox dialog.
///
/// Selection uses stable typed IDs (`Set<T>`); options carry their own
/// [FwOption.enabled] flags. [maxSelection] caps the count — unselected
/// options disable when the cap is reached. Chips wrap and remove with a
/// tap; the dialog filters by label as you type.
class FwMultiSelect<T> extends StatefulWidget {
  const FwMultiSelect({
    super.key,
    required this.label,
    required this.options,
    this.selected = const {},
    required this.onChanged,
    this.maxSelection,
    this.enabled = true,
    this.required = false,
    this.description,
    this.externalError,
    this.searchHint = 'Search',
    this.doneLabel = 'Done',
    this.clearLabel = 'Clear',
  });

  /// Field label.
  final String label;

  /// All available options with stable typed values.
  final List<FwOption<T>> options;

  /// Currently selected values.
  final Set<T> selected;

  /// Fired with the new selection set.
  final ValueChanged<Set<T>> onChanged;

  /// Maximum selectable count; `null` means unlimited.
  final int? maxSelection;

  final bool enabled;
  final bool required;
  final String? description;
  final String? externalError;
  final String searchHint;
  final String doneLabel;
  final String clearLabel;

  @override
  State<FwMultiSelect<T>> createState() => _FwMultiSelectState<T>();
}

class _FwMultiSelectState<T> extends State<FwMultiSelect<T>> {
  void _remove(T value) {
    final next = Set<T>.of(widget.selected)..remove(value);
    widget.onChanged(next);
  }

  Future<void> _openDialog() async {
    if (!widget.enabled) return;
    final selection = ValueNotifier<Set<T>>(Set<T>.of(widget.selected));
    try {
      final result = await FwDialog.show<Set<T>>(
        context: context,
        title: Text(widget.label),
        content: _MultiSelectDialogContent<T>(
          options: widget.options,
          selection: selection,
          maxSelection: widget.maxSelection,
          searchHint: widget.searchHint,
        ),
        actions: [
          Builder(
            builder: (context) => FwButton(
              label: widget.clearLabel,
              variant: FwButtonVariant.ghost,
              onPressed: () => FwDialog.close(context, <T>{}),
            ),
          ),
          Builder(
            builder: (context) => FwButton(
              label: widget.doneLabel,
              variant: FwButtonVariant.solid,
              onPressed: () => FwDialog.close(context, selection.value),
            ),
          ),
        ],
      );
      if (result.reason == FwDismissReason.action && result.value != null) {
        widget.onChanged(result.value!);
      }
    } finally {
      selection.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final selectedOptions = widget.options
        .where((o) => widget.selected.contains(o.value))
        .toList();
    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: widget.externalError,
      enabled: widget.enabled,
      child: InkWell(
        onTap: widget.enabled ? _openDialog : null,
        borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.sm)),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.arrow_drop_down),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: selectedOptions.isEmpty
              ? Text(
                  'Select…',
                  style: typeScale
                      .resolve(FwTextRole.body, context)
                      .copyWith(color: colors.of(FwColorRole.textMuted)),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final option in selectedOptions)
                      InputChip(
                        label: Text(option.label),
                        onDeleted: widget.enabled
                            ? () => _remove(option.value)
                            : null,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Searchable checkbox list shown inside the multi-select dialog.
/// Selection is shared with the dialog's Done action via [selection].
class _MultiSelectDialogContent<T> extends StatefulWidget {
  const _MultiSelectDialogContent({
    required this.options,
    required this.selection,
    required this.maxSelection,
    required this.searchHint,
  });

  final List<FwOption<T>> options;
  final ValueNotifier<Set<T>> selection;
  final int? maxSelection;
  final String searchHint;

  @override
  State<_MultiSelectDialogContent<T>> createState() =>
      _MultiSelectDialogContentState<T>();
}

class _MultiSelectDialogContentState<T>
    extends State<_MultiSelectDialogContent<T>> {
  String _query = '';

  bool _capped(Set<T> selected) =>
      widget.maxSelection != null && selected.length >= widget.maxSelection!;

  void _toggle(FwOption<T> option, bool? checked) {
    final current = Set<T>.of(widget.selection.value);
    if (checked == true) {
      if (_capped(current) || !option.enabled) return;
      current.add(option.value);
    } else {
      current.remove(option.value);
    }
    widget.selection.value = current;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final query = _query.trim().toLowerCase();
    final visible = widget.options
        .where((o) => query.isEmpty || o.label.toLowerCase().contains(query))
        .toList();
    // Transparent Material: CheckboxListTile needs a Material ancestor for
    // ink, but the dialog card is custom-drawn.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FwTextField(
            label: widget.searchHint,
            hintText: widget.searchHint,
            onChanged: (v) => setState(() => _query = v),
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
          Flexible(
            child: ValueListenableBuilder<Set<T>>(
              valueListenable: widget.selection,
              builder: (context, selected, _) {
                if (visible.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(
                      theme.spaceScale.of(FwSpace.s4, context),
                    ),
                    child: const Text('No matches'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final option = visible[index];
                    final checked = selected.contains(option.value);
                    final enabled =
                        option.enabled && (checked || !_capped(selected));
                    return CheckboxListTile(
                      value: checked,
                      onChanged: enabled ? (v) => _toggle(option, v) : null,
                      title: Text(option.label),
                      subtitle: option.description != null
                          ? Text(option.description!)
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date field (F15).
// ---------------------------------------------------------------------------

/// Date field (F15): locale-formatted civil date with a calendar picker.
///
/// [value] is a *civil* date — only year/month/day are significant; any
/// time component is ignored. Never mix these with UTC timestamps: convert
/// at the boundary instead. Tapping the field opens the platform date
/// picker adapted to framework tokens via [FwTheme.toThemeData].
class FwDateField extends StatefulWidget {
  const FwDateField({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.enabled = true,
    this.required = false,
    this.description,
    this.externalError,
  });

  /// Field label.
  final String label;

  /// Current civil date; `null` renders as empty.
  final DateTime? value;

  /// Fired with the picked civil date, or `null` when cleared.
  final ValueChanged<DateTime?> onChanged;

  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool Function(DateTime)? selectableDayPredicate;
  final bool enabled;
  final bool required;
  final String? description;
  final String? externalError;

  @override
  State<FwDateField> createState() => _FwDateFieldState();
}

class _FwDateFieldState extends State<FwDateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(FwDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncText();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncText() {
    if (!mounted) return;
    final localizations = MaterialLocalizations.of(context);
    _controller.text = widget.value == null
        ? ''
        : localizations.formatFullDate(widget.value!);
  }

  Future<void> _pick() async {
    if (!widget.enabled) return;
    final theme = context.fwTheme;
    final now = DateTime.now();
    final value = widget.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: widget.firstDate ?? DateTime(now.year - 100),
      lastDate: widget.lastDate ?? DateTime(now.year + 100),
      selectableDayPredicate: widget.selectableDayPredicate,
      builder: (context, child) =>
          Theme(data: theme.toThemeData(), child: child!),
    );
    if (picked != null && mounted) {
      // Normalize to a civil date: strip any time component.
      widget.onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _pick : null,
      child: FwTextField(
        label: widget.label,
        controller: _controller,
        required: widget.required,
        description: widget.description,
        externalError: widget.externalError,
        enabled: widget.enabled,
        readOnly: true,
        onChanged: (_) {},
        suffix: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.value != null && widget.enabled)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Clear date',
                onPressed: () => widget.onChanged(null),
              ),
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 18),
              tooltip: 'Pick a date',
              onPressed: widget.enabled ? _pick : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time field (F16).
// ---------------------------------------------------------------------------

/// Time field (F16): locale-formatted time with a clock picker.
///
/// 12/24-hour display follows the ambient locale
/// ([MediaQuery.alwaysUse24HourFormat] wins when set). Tapping the field
/// opens the platform time picker adapted to framework tokens.
class FwTimeField extends StatefulWidget {
  const FwTimeField({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.required = false,
    this.description,
    this.externalError,
  });

  /// Field label.
  final String label;

  /// Current time; `null` renders as empty.
  final TimeOfDay? value;

  /// Fired with the picked time, or `null` when cleared.
  final ValueChanged<TimeOfDay?> onChanged;

  final bool enabled;
  final bool required;
  final String? description;
  final String? externalError;

  @override
  State<FwTimeField> createState() => _FwTimeFieldState();
}

class _FwTimeFieldState extends State<FwTimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(FwTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncText();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncText() {
    if (!mounted) return;
    final localizations = MaterialLocalizations.of(context);
    _controller.text = widget.value == null
        ? ''
        : localizations.formatTimeOfDay(widget.value!);
  }

  Future<void> _pick() async {
    if (!widget.enabled) return;
    final theme = context.fwTheme;
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.value ?? TimeOfDay.now(),
      builder: (context, child) =>
          Theme(data: theme.toThemeData(), child: child!),
    );
    if (picked != null && mounted) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _pick : null,
      child: FwTextField(
        label: widget.label,
        controller: _controller,
        required: widget.required,
        description: widget.description,
        externalError: widget.externalError,
        enabled: widget.enabled,
        readOnly: true,
        onChanged: (_) {},
        suffix: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.value != null && widget.enabled)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Clear time',
                onPressed: () => widget.onChanged(null),
              ),
            IconButton(
              icon: const Icon(Icons.access_time, size: 18),
              tooltip: 'Pick a time',
              onPressed: widget.enabled ? _pick : null,
            ),
          ],
        ),
      ),
    );
  }
}
