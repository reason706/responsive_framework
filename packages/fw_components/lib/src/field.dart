import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Immutable snapshot of a single form field's state, shared by every
/// `Fw*` input so label/error/disabled conventions never drift per control.
///
/// The model is UI-agnostic: widgets read it, applications own the values.
/// [externalError] (e.g. a server rejection) takes precedence over
/// [validatorError] (local validation output); both are kept distinct so a
/// form can clear them independently.
@immutable
class FwFieldState<T> {
  const FwFieldState({
    this.value,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.focused = false,
    this.dirty = false,
    this.touched = false,
    this.validating = false,
    this.validatorError,
    this.externalError,
  });

  /// Current field value. `null` means "no value yet", not "invalid".
  final T? value;

  final bool enabled;
  final bool readOnly;

  /// Whether a value must be supplied before the form can submit.
  final bool required;

  final bool focused;

  /// Value changed since the field was created or last reset.
  final bool dirty;

  /// The field received and lost focus, or was otherwise interacted with.
  /// Validation messages are withheld until [touched] (or submit) so forms
  /// never flash errors on first paint.
  final bool touched;

  /// An asynchronous validation is in flight.
  final bool validating;

  /// Error produced by the field's own validator.
  final String? validatorError;

  /// Error supplied from outside (e.g. server-side rejection). Wins over
  /// [validatorError] via [resolvedError].
  final String? externalError;

  /// The error to display, if any. External errors take precedence.
  String? get resolvedError => externalError ?? validatorError;

  bool get hasError => resolvedError != null;

  /// The field accepts user input right now.
  bool get interactive => enabled && !readOnly;

  /// Whether an error should be *shown*: only after interaction or submit,
  /// never on first paint.
  bool get showError => hasError && (touched || dirty);

  FwFieldState<T> copyWith({
    T? value,
    bool? enabled,
    bool? readOnly,
    bool? required,
    bool? focused,
    bool? dirty,
    bool? touched,
    bool? validating,
    String? validatorError,
    String? externalError,
    bool clearValidatorError = false,
    bool clearExternalError = false,
  }) {
    return FwFieldState<T>(
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      required: required ?? this.required,
      focused: focused ?? this.focused,
      dirty: dirty ?? this.dirty,
      touched: touched ?? this.touched,
      validating: validating ?? this.validating,
      validatorError: clearValidatorError
          ? null
          : (validatorError ?? this.validatorError),
      externalError: clearExternalError
          ? null
          : (externalError ?? this.externalError),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwFieldState<T> &&
          value == other.value &&
          enabled == other.enabled &&
          readOnly == other.readOnly &&
          required == other.required &&
          focused == other.focused &&
          dirty == other.dirty &&
          touched == other.touched &&
          validating == other.validating &&
          validatorError == other.validatorError &&
          externalError == other.externalError;

  @override
  int get hashCode => Object.hash(
    value,
    enabled,
    readOnly,
    required,
    focused,
    dirty,
    touched,
    validating,
    validatorError,
    externalError,
  );

  @override
  String toString() =>
      'FwFieldState(value: $value, enabled: $enabled, readOnly: $readOnly, '
      'required: $required, error: $resolvedError)';
}

/// Layer-3 component tokens for [FwField].
///
/// Register via `ThemeData(extensions: [FwFieldTheme(...)])` or pass
/// [FwField.fieldTheme] for a local scope. Unspecified values fall back to
/// [FwFieldTheme.fromColors].
class FwFieldTheme extends ThemeExtension<FwFieldTheme> {
  const FwFieldTheme({
    this.labelStyle,
    this.requiredStyle,
    this.descriptionStyle,
    this.errorStyle,
    this.labelGap,
    this.messageGap,
    this.adornmentGap,
    this.errorIcon,
  });

  /// Semantic-role defaults so the shell renders without registration.
  factory FwFieldTheme.fromColors(FwColors colors) => const FwFieldTheme();

  final TextStyle? labelStyle;
  final TextStyle? requiredStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? errorStyle;

  /// Gap between the label row and the editor.
  final double? labelGap;

  /// Gap between the editor and the description/error line.
  final double? messageGap;

  /// Gap between prefix/suffix adornments and the editor.
  final double? adornmentGap;

  /// Icon shown before the error text. Defaults to `Icons.error_outline`.
  final IconData? errorIcon;

  static FwFieldTheme of(BuildContext context) =>
      Theme.of(context).extension<FwFieldTheme>() ??
      FwFieldTheme.fromColors(context.fwTheme.colors);

  @override
  FwFieldTheme copyWith({
    TextStyle? labelStyle,
    TextStyle? requiredStyle,
    TextStyle? descriptionStyle,
    TextStyle? errorStyle,
    double? labelGap,
    double? messageGap,
    double? adornmentGap,
    IconData? errorIcon,
  }) {
    return FwFieldTheme(
      labelStyle: labelStyle ?? this.labelStyle,
      requiredStyle: requiredStyle ?? this.requiredStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      labelGap: labelGap ?? this.labelGap,
      messageGap: messageGap ?? this.messageGap,
      adornmentGap: adornmentGap ?? this.adornmentGap,
      errorIcon: errorIcon ?? this.errorIcon,
    );
  }

  @override
  FwFieldTheme lerp(ThemeExtension<FwFieldTheme>? other, double t) {
    if (other is! FwFieldTheme) return this;
    return FwFieldTheme(
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      requiredStyle: TextStyle.lerp(requiredStyle, other.requiredStyle, t),
      descriptionStyle: TextStyle.lerp(
        descriptionStyle,
        other.descriptionStyle,
        t,
      ),
      errorStyle: TextStyle.lerp(errorStyle, other.errorStyle, t),
      labelGap: _lerpDouble(labelGap, other.labelGap, t),
      messageGap: _lerpDouble(messageGap, other.messageGap, t),
      adornmentGap: _lerpDouble(adornmentGap, other.adornmentGap, t),
      errorIcon: t < 0.5 ? errorIcon : other.errorIcon,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}

/// Inherited field context for editors hosted inside [FwField].
///
/// Editors read the shell's label, error, and enabled state from here so the
/// visual label (owned by the shell) and the editor's decoration/semantics
/// never disagree. `null` means the editor is used standalone.
class FwFieldScope extends InheritedWidget {
  const FwFieldScope({
    super.key,
    required this.label,
    required this.required,
    required this.enabled,
    required this.readOnly,
    required this.hasError,
    required super.child,
  });

  final String label;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final bool hasError;

  static FwFieldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FwFieldScope>();

  @override
  bool updateShouldNotify(FwFieldScope oldWidget) =>
      label != oldWidget.label ||
      required != oldWidget.required ||
      enabled != oldWidget.enabled ||
      readOnly != oldWidget.readOnly ||
      hasError != oldWidget.hasError;
}

/// Form field shell (F01): persistent label, required hint, description,
/// helper/error line, and prefix/suffix slots around the value editor.
///
/// The shell owns the label — it is always visible and never floats away —
/// while decoration stays with the editor. Error indication combines text
/// *and* an icon, never a red border alone. The error line is a live region
/// so its appearance is announced.
///
/// Wrap every `Fw*` input in [FwField]; labels are never optional.
class FwField extends StatelessWidget {
  const FwField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.description,
    this.errorText,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.fieldTheme,
  });

  /// Persistent visible label. Always rendered, at any text scale.
  final String label;

  /// The value editor (e.g. [FwTextField]). Reads [FwFieldScope].
  final Widget child;

  /// Shows the required marker next to the label.
  final bool required;

  /// Persistent guidance shown under the editor. Replaced by [errorText]
  /// when an error is present.
  final String? description;

  /// Error message. Shown with an icon in a live region.
  final String? errorText;

  /// Widgets flanking the editor (icons, units, actions).
  final Widget? prefix;
  final Widget? suffix;

  final bool enabled;
  final bool readOnly;

  /// Local theme scope override for this field only.
  final FwFieldTheme? fieldTheme;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final typeScale = theme.typeScale;
    final registered = FwFieldTheme.of(context);
    final ft = fieldTheme ?? registered;

    final labelGap = ft.labelGap ?? theme.spaceScale.of(FwSpace.s1, context);
    final messageGap =
        ft.messageGap ?? theme.spaceScale.of(FwSpace.s1, context);
    final adornmentGap =
        ft.adornmentGap ?? theme.spaceScale.of(FwSpace.s2, context);

    final labelColor = enabled
        ? colors.of(FwColorRole.text)
        : colors.of(FwColorRole.textMuted);
    final labelStyle =
        (ft.labelStyle ?? typeScale.resolve(FwTextRole.label, context))
            .copyWith(color: labelColor);
    final requiredStyle =
        (ft.requiredStyle ?? typeScale.resolve(FwTextRole.label, context))
            .copyWith(color: colors.of(FwColorRole.error));
    final descriptionStyle =
        (ft.descriptionStyle ?? typeScale.resolve(FwTextRole.bodySm, context))
            .copyWith(
              color: enabled
                  ? colors.of(FwColorRole.textMuted)
                  : colors.of(FwColorRole.textSubtle),
            );
    final errorStyle =
        (ft.errorStyle ?? typeScale.resolve(FwTextRole.bodySm, context))
            .copyWith(color: colors.of(FwColorRole.error));

    final hasError = errorText != null;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: FwFieldScope(
        label: label,
        required: required,
        enabled: enabled,
        readOnly: readOnly,
        hasError: hasError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label row: persistent, never floats into the editor.
            ExcludeSemantics(
              // The outer Semantics carries the label; avoid a duplicate.
              child: Row(
                children: [
                  Flexible(child: Text(label, style: labelStyle)),
                  if (required) ...[
                    SizedBox(width: theme.spaceScale.of(FwSpace.s1, context)),
                    Text('*', style: requiredStyle),
                  ],
                ],
              ),
            ),
            SizedBox(height: labelGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefix != null) ...[prefix!, SizedBox(width: adornmentGap)],
                Expanded(child: child),
                if (suffix != null) ...[SizedBox(width: adornmentGap), suffix!],
              ],
            ),
            SizedBox(height: messageGap),
            // One message line: error wins over description. The error is a
            // live region so its appearance is announced by screen readers.
            if (hasError)
              Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      ft.errorIcon ?? Icons.error_outline,
                      size: 16,
                      color: colors.of(FwColorRole.error),
                    ),
                    SizedBox(width: theme.spaceScale.of(FwSpace.s1, context)),
                    Expanded(child: Text(errorText!, style: errorStyle)),
                  ],
                ),
              )
            else if (description != null)
              Text(description!, style: descriptionStyle),
          ],
        ),
      ),
    );
  }
}
