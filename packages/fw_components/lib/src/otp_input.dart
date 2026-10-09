import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'field.dart';

/// One-time-code / PIN input (+F22).
///
/// One logical editing control with segmented visuals: a single transparent
/// [TextField] drives N boxes, so paste, password managers, SMS autofill
/// ([AutofillHints.oneTimeCode]), and screen readers all behave like a
/// normal text field. The boxes are decorative; the field carries the
/// semantics.
///
/// [onCompleted] fires when [length] digits are entered. [obscureText]
/// renders dots instead of digits.
class FwOtpInput extends FormField<String> {
  FwOtpInput({
    super.key,
    required this.label,
    this.length = 6,
    this.required = false,
    this.description,
    this.externalError,
    this.onCompleted,
    this.onChanged,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.validator,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.restorationId,
    super.onSaved,
  }) : assert(length > 0, 'length must be positive'),
       super(
         initialValue: controller?.text ?? '',
         enabled: enabled,
         validator: validator,
         builder: (field) {
           final state = field as _FwOtpInputState;
           return state._build(field.context);
         },
       );

  final String label;
  final int length;
  final bool required;
  final String? description;
  final String? externalError;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final String obscuringCharacter;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  @override
  FormFieldState<String> createState() => _FwOtpInputState();
}

class _FwOtpInputState extends FormFieldState<String> {
  @override
  FwOtpInput get widget => super.widget as FwOtpInput;

  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
    if (widget.focusNode == null) _internalFocusNode = FocusNode();
    _effectiveController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(FwOtpInput oldWidget) {
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

  void _handleTextChanged() {
    final text = _effectiveController.text;
    if (text != value) {
      didChange(text);
      widget.onChanged?.call(text);
      if (text.length == widget.length) {
        widget.onCompleted?.call(text);
      }
    }
    setState(() {});
  }

  String? get displayError => widget.externalError ?? errorText;

  Widget _build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final text = _effectiveController.text;
    final hasError = displayError != null;

    Widget box(int i, double size) {
      final filled = i < text.length;
      final active = i == text.length && widget.enabled;
      final char = filled
          ? (widget.obscureText ? widget.obscuringCharacter : text[i])
          : '';
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.of(FwColorRole.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
            border: Border.all(
              color: hasError
                  ? colors.of(FwColorRole.error)
                  : active
                  ? colors.of(FwColorRole.focusRing)
                  : colors.of(FwColorRole.border),
              width: active ? 2 : 1,
            ),
          ),
          child: Text(
            char,
            style: theme.typeScale.resolve(FwTextRole.h4, context),
          ),
        ),
      );
    }

    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: displayError,
      enabled: widget.enabled,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Segmented visuals. Decorative: the text field owns semantics.
          ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Boxes fill the available width; 52px when unconstrained.
                // They shrink fluidly on narrow screens (no minimum — the
                // digits scale down with the box).
                final gap = theme.spaceScale.of(FwSpace.s2, context);
                final maxW = constraints.maxWidth;
                final boxSize = maxW.isFinite
                    ? (maxW - gap * (widget.length - 1)) / widget.length
                    : 52.0;
                return Row(
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      box(i, boxSize),
                    ],
                  ],
                );
              },
            ),
          ),
          // The single logical editor: transparent but focusable, so paste,
          // autofill, and screen readers work like a normal field.
          Positioned.fill(
            child: TextField(
              controller: _effectiveController,
              focusNode: _effectiveFocusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
              onChanged: (v) {
                // Handled via the controller listener.
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void reset() {
    super.reset();
    _effectiveController.clear();
  }

  @override
  void dispose() {
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
