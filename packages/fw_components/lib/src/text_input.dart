import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'field.dart';

/// Visual treatment of a text input, independent of its content.
enum FwTextFieldVariant { filled, outline }

/// Limits input to [maxLength] grapheme clusters (not UTF-16 code units),
/// so emoji and combined characters count as the user perceives them.
class GraphemeLengthLimiter extends TextInputFormatter {
  GraphemeLengthLimiter(this.maxLength) : assert(maxLength > 0);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.characters.length <= maxLength) return newValue;
    final truncated = newValue.text.characters.take(maxLength).toString();
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
      composing: TextRange.empty,
    );
  }
}

InputDecoration _decorationFor({
  required BuildContext context,
  required FwTextFieldVariant variant,
  required bool hasError,
  required bool enabled,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final theme = context.fwTheme;
  final colors = theme.colors;
  final radius = BorderRadius.circular(theme.radii.of(FwRadius.md));
  final contentPadding = EdgeInsets.symmetric(
    horizontal: theme.spaceScale.resolveAlias(FwSpaceAlias.controlInline, context),
    vertical: theme.spaceScale.resolveAlias(FwSpaceAlias.controlBlock, context),
  );

  final errorColor = colors.of(FwColorRole.error);
  final focusColor = colors.of(FwColorRole.focusRing);
  final borderColor = hasError
      ? errorColor
      : colors.of(FwColorRole.borderStrong);

  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: contentPadding,
    filled: variant == FwTextFieldVariant.filled,
    fillColor: variant == FwTextFieldVariant.filled
        ? colors.of(FwColorRole.surfaceContainerHighest)
        : null,
    border: variant == FwTextFieldVariant.filled
        ? OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          )
        : border(colors.of(FwColorRole.border)),
    enabledBorder: variant == FwTextFieldVariant.filled
        ? OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          )
        : border(colors.of(FwColorRole.border)),
    focusedBorder: border(hasError ? errorColor : focusColor, width: 2),
    errorBorder: border(errorColor),
    focusedErrorBorder: border(errorColor, width: 2),
    disabledBorder: variant == FwTextFieldVariant.filled
        ? OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          )
        : border(colors.of(FwColorRole.disabled)),
    // The shell owns the visible label; the decoration carries none so the
    // label is never duplicated or floated into the box.
    floatingLabelBehavior: FloatingLabelBehavior.never,
    isDense: true,
  );
}

/// Single-line text input (F02) with the [FwField] shell built in.
///
/// Integrates with Flutter [Form]: [validator], `save`/`reset`, and
/// [AutovalidateMode] behave like [TextFormField]. [externalError] (e.g. a
/// server rejection) takes precedence over validator output and is shown
/// immediately; validator errors follow [autovalidateMode] (default:
/// [AutovalidateMode.onUserInteraction]) so nothing flashes on first paint.
///
/// Controller lifecycle: pass [controller] to own it (it is never disposed
/// here); otherwise an internal controller is created and disposed. Swapping
/// controllers preserves the framework value contract.
class FwTextField extends FormField<String> {
  FwTextField({
    super.key,
    required this.label,
    this.required = false,
    this.description,
    this.externalError,
    this.hintText,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.showClear = false,
    this.variant = FwTextFieldVariant.filled,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.restorationId,
  }) : assert(
         controller == null || initialValue == null,
         'Pass either a controller or an initialValue, not both.',
       ),
       super(
         initialValue: controller != null
             ? controller.text
             : (initialValue ?? ''),
         enabled: enabled,
         validator: validator,
         builder: (field) {
           final state = field as _FwTextFieldState;
           return state._build(field.context);
         },
       );

  /// Persistent visible label, rendered by the shell.
  final String label;
  final bool required;

  /// Persistent guidance under the editor.
  final String? description;

  /// Error supplied from outside (e.g. server-side). Shown immediately and
  /// takes precedence over validator output.
  final String? externalError;

  final String? hintText;

  /// Widgets flanking the editor in the shell (outside the input box).
  final Widget? prefix;
  final Widget? suffix;

  /// Icons inside the input box.
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  /// Show a clear button when the field has text.
  final bool showClear;

  final FwTextFieldVariant variant;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  /// Obscure the text (used by [FwPasswordField]; prefer that widget).
  final bool obscureText;

  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;

  @override
  FormFieldState<String> createState() => _FwTextFieldState();
}

class _FwTextFieldState extends FormFieldState<String> {
  @override
  FwTextField get widget => super.widget as FwTextField;

  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? _internalFocusNode!;

  bool _touched = false;
  late String _initialText;

  @override
  void initState() {
    super.initState();
    _initialText = widget.controller?.text ?? widget.initialValue ?? '';
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_handleFocusChanged);
    _effectiveController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(FwTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController!.removeListener(_handleTextChanged);
        _internalController!.dispose();
        _internalController = null;
      } else {
        oldWidget.controller!.removeListener(_handleControllerChanged);
        oldWidget.controller!.removeListener(_handleTextChanged);
      }
      if (widget.controller == null) {
        _internalController = TextEditingController(
          text: oldWidget.controller?.text ?? value,
        );
        _internalController!.addListener(_handleTextChanged);
      } else {
        widget.controller!.addListener(_handleControllerChanged);
        widget.controller!.addListener(_handleTextChanged);
        _initialText = widget.controller!.text;
      }
      setValue(_effectiveController.text);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)!.removeListener(
        _handleFocusChanged,
      );
      if (widget.focusNode == null && _internalFocusNode == null) {
        _internalFocusNode = FocusNode();
      }
      if (widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _effectiveFocusNode.addListener(_handleFocusChanged);
    }
  }

  void _handleControllerChanged() {
    if (_effectiveController.text != value) {
      didChange(_effectiveController.text);
    }
  }

  void _handleTextChanged() => setState(() {});

  void _handleFocusChanged() {
    if (!_effectiveFocusNode.hasFocus && !_touched) {
      _touched = true;
      setState(() {});
    }
  }

  /// Error to display: external errors show immediately; validator errors
  /// follow the framework's autovalidation timing.
  String? get displayError => widget.externalError ?? errorText;

  void _clear() {
    _effectiveController.clear();
    didChange('');
    widget.onChanged?.call('');
  }

  Widget _build(BuildContext context) {
    final hasText = _effectiveController.text.isNotEmpty;
    Widget? clearButton;
    if (widget.showClear &&
        hasText &&
        widget.enabled &&
        !widget.readOnly) {
      clearButton = IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear, size: 18),
        onPressed: _clear,
      );
    }
    Widget? suffixIcon = widget.suffixIcon;
    if (clearButton != null) {
      suffixIcon = suffixIcon == null
          ? clearButton
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [clearButton, suffixIcon],
            );
    }

    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: displayError,
      prefix: widget.prefix,
      suffix: widget.suffix,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      child: TextField(
        controller: _effectiveController,
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        autofillHints: widget.autofillHints,
        inputFormatters: widget.inputFormatters,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        decoration: _decorationFor(
          context: context,
          variant: widget.variant,
          hasError: displayError != null,
          enabled: widget.enabled,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffixIcon,
        ),
        onChanged: (v) {
          didChange(v);
          widget.onChanged?.call(v);
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }

  @override
  void reset() {
    super.reset();
    _effectiveController.text = widget.initialValue ?? '';
    _touched = false;
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _effectiveController.removeListener(_handleTextChanged);
    if (widget.controller == null) {
      _internalController!.dispose();
    } else {
      widget.controller!.removeListener(_handleControllerChanged);
    }
    _internalFocusNode?.dispose();
    super.dispose();
  }
}

/// Multi-line text area (F03): min/max lines, bounded expansion, and a
/// grapheme-aware character counter.
///
/// The editor grows to [maxLines], then scrolls internally — it never takes
/// unbounded height. When [maxLength] is set, input is limited to that many
/// grapheme clusters and a `used / max` counter is shown; the counter policy
/// counts what the user perceives (emoji count as one).
class FwTextArea extends FormField<String> {
  FwTextArea({
    super.key,
    required this.label,
    this.required = false,
    this.description,
    this.externalError,
    this.hintText,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.showCounter = true,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction = TextInputAction.newline,
    this.textCapitalization = TextCapitalization.sentences,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.restorationId,
  }) : assert(minLines >= 1, 'minLines must be at least 1'),
       assert(
         maxLines == null || maxLines >= minLines,
         'maxLines must be >= minLines',
       ),
       assert(
         controller == null || initialValue == null,
         'Pass either a controller or an initialValue, not both.',
       ),
       super(
         initialValue: controller != null
             ? controller.text
             : (initialValue ?? ''),
         enabled: enabled,
         validator: validator,
         builder: (field) {
           final state = field as _FwTextAreaState;
           return state._build(field.context);
         },
       );

  final String label;
  final bool required;
  final String? description;
  final String? externalError;
  final String? hintText;
  final int minLines;
  final int? maxLines;

  /// Maximum grapheme clusters. Enables the counter and enforcement.
  final int? maxLength;
  final bool showCounter;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;

  @override
  FormFieldState<String> createState() => _FwTextAreaState();
}

class _FwTextAreaState extends FormFieldState<String> {
  @override
  FwTextArea get widget => super.widget as FwTextArea;

  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
    _effectiveController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(FwTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController!.removeListener(_handleTextChanged);
        _internalController!.dispose();
        _internalController = null;
      } else {
        oldWidget.controller!.removeListener(_handleControllerChanged);
        oldWidget.controller!.removeListener(_handleTextChanged);
      }
      if (widget.controller == null) {
        _internalController = TextEditingController(
          text: oldWidget.controller?.text ?? value,
        );
        _internalController!.addListener(_handleTextChanged);
      } else {
        widget.controller!.addListener(_handleControllerChanged);
        widget.controller!.addListener(_handleTextChanged);
      }
      setValue(_effectiveController.text);
    }
  }

  void _handleControllerChanged() {
    if (_effectiveController.text != value) {
      didChange(_effectiveController.text);
    }
  }

  void _handleTextChanged() => setState(() {});

  String? get displayError => widget.externalError ?? errorText;

  Widget? _counter(BuildContext context) {
    if (!widget.showCounter || widget.maxLength == null) return null;
    final theme = context.fwTheme;
    final used = _effectiveController.text.characters.length;
    final over = used > widget.maxLength!;
    return Text(
      '$used / ${widget.maxLength}',
      style: theme.typeScale
          .resolve(FwTextRole.caption, context)
          .copyWith(
            color: theme.colors.of(
              over ? FwColorRole.error : FwColorRole.textMuted,
            ),
          ),
    );
  }

  Widget _build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      if (widget.maxLength != null)
        GraphemeLengthLimiter(widget.maxLength!),
    ];
    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: displayError,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      suffix: _counter(context),
      child: TextField(
        controller: _effectiveController,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        keyboardType: TextInputType.multiline,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        autofillHints: widget.autofillHints,
        inputFormatters: formatters,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        decoration: _decorationFor(
          context: context,
          variant: FwTextFieldVariant.filled,
          hasError: displayError != null,
          enabled: widget.enabled,
          hintText: widget.hintText,
        ),
        onChanged: (v) {
          didChange(v);
          widget.onChanged?.call(v);
        },
      ),
    );
  }

  @override
  void reset() {
    super.reset();
    _effectiveController.text = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleTextChanged);
    if (widget.controller == null) {
      _internalController!.dispose();
    } else {
      widget.controller!.removeListener(_handleControllerChanged);
    }
    super.dispose();
  }
}

/// Search field (F12): an [FwTextField] specialization with a search icon,
/// clear action, loading affordance, and submit callback.
///
/// Debounce is a caller concern (a service, not a hidden network call):
/// use [onChanged] with your own debounce and [loading] for the affordance.
class FwSearchField extends StatelessWidget {
  const FwSearchField({
    super.key,
    required this.label,
    this.description,
    this.externalError,
    this.hintText = 'Search',
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.autofillHints,
    this.loading = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
  });

  final String label;
  final String? description;
  final String? externalError;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final Iterable<String>? autofillHints;

  /// Shows a spinner affordance in the suffix while results load.
  final bool loading;

  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return FwTextField(
      label: label,
      description: description,
      externalError: externalError,
      hintText: hintText,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      autofillHints: autofillHints,
      prefixIcon: const Icon(Icons.search, size: 20),
      showClear: true,
      suffixIcon: loading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : null,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      readOnly: readOnly,
    );
  }
}
