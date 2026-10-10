import 'package:flutter/material.dart';

/// Form controller: the "ship a form controller, not just fields" gap.
///
/// `Fw*` fields are `FormField` subclasses with their own validators, so a
/// bare Flutter `Form` already validates them one by one. What was missing
/// is the orchestration layer real forms need:
///
/// * [validateAll]/[validateFields] — sync validators first, then async,
///   with per-field errors and a global [isValidating] flag.
/// * Aggregates as listenable state: [isDirty], [isTouched], [isValid].
/// * Conditional visibility: fields register predicates over other fields'
///   values; hidden fields are excluded from validation and [values].
/// * [values] map and [reset].
/// * Wizard support: [validateFields] gates per-step continue handlers
///   (see the [FwForm] example and the gallery board).
///
/// ## Registration model
///
/// Fields opt in with an optional `formName` constructor parameter. When a
/// named field builds inside an [FwForm], its state auto-registers with the
/// form's controller via the [FwFormFieldRegistration] mixin; fields without
/// `formName`, or outside an [FwForm], behave exactly as before. This was
/// chosen over a `controller` constructor parameter because several fields
/// already use `controller` for their text controllers, and a scope widget
/// keeps every existing call site source-compatible.
///
/// The controller never touches widget types: registration stores a small
/// adapter of closures ([FwFieldEntry]), so custom (non-`Fw*`) fields can
/// participate by calling [registerField]/[unregisterField] directly.
///
/// The controller is app-owned: create it in `initState` (or as a field)
/// and [dispose] it. [FwForm] never disposes it.
///
/// ```dart
/// final controller = FwFormController()
///   ..setAsyncValidator<String>('email', (v) async =>
///       v != null && await isEmailTaken(v) ? 'Already registered' : null)
///   ..setVisibleWhen('company', (values) => values['accountType'] == 'business');
///
/// FwForm(
///   controller: controller,
///   child: Column(
///     children: [
///       FwTextField(formName: 'email', label: 'Email', validator: _validateEmail),
///       FwFormVisibility(
///         name: 'company',
///         child: FwTextField(formName: 'company', label: 'Company'),
///       ),
///       ListenableBuilder(
///         listenable: controller,
///         builder: (context, _) => FwButton(
///           label: 'Submit',
///           onPressed: controller.isValid
///               ? () async {
///                   if (await controller.validateAll()) {
///                     submit(controller.values);
///                   }
///                 }
///               : null,
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
class FwFormController extends ChangeNotifier {
  final Map<String, FwFieldEntry> _entries = {};
  final Map<String, bool Function(Map<String, Object?> values)>
  _visibilityPredicates = {};
  final Set<String> _hidden = {};
  final Map<String, Future<String?> Function(Object? value)> _asyncValidators =
      {};
  final Map<String, String> _asyncErrors = {};
  final Map<String, bool> _lastSyncValid = {};

  int _validating = 0;
  bool _submitted = false;

  // -------------------------------------------------------------------------
  // Registration (called by [FwFormFieldRegistration]; public for custom
  // fields that want to participate without the mixin).
  // -------------------------------------------------------------------------

  /// Registers a field under [entry.name], replacing any previous entry
  /// with the same name. Names must be unique within a form.
  void registerField(FwFieldEntry entry) {
    _entries[entry.name] = entry;
    _evaluateVisibility();
    notifyListeners();
  }

  /// Removes the field registered under [name]. Async validators and
  /// visibility predicates are name-keyed configuration and are kept, so a
  /// field that temporarily unmounts (tab switch, step change) does not lose
  /// them.
  void unregisterField(String name) {
    _entries.remove(name);
    _asyncErrors.remove(name);
    _lastSyncValid.remove(name);
    _hidden.remove(name);
    _evaluateVisibility();
    notifyListeners();
  }

  /// Names of currently registered fields.
  Iterable<String> get fieldNames => _entries.keys;

  // -------------------------------------------------------------------------
  // Async validators.
  // -------------------------------------------------------------------------

  /// Registers an async validator for the field named [name] (e.g. a
  /// server-side uniqueness check). Runs after the sync validators pass,
  /// during [validateAll]/[validateFields]; the error is shown on the
  /// field like any other error.
  void setAsyncValidator<T>(
    String name,
    Future<String?> Function(T? value) validator,
  ) {
    _asyncValidators[name] = (Object? value) => validator(value as T?);
  }

  /// Removes the async validator for [name].
  void clearAsyncValidator(String name) {
    _asyncValidators.remove(name);
    _asyncErrors.remove(name);
    notifyListeners();
  }

  /// The current async error for [name], if any. Read by registered fields
  /// to display alongside their sync errors.
  String? asyncErrorFor(String name) => _asyncErrors[name];

  // -------------------------------------------------------------------------
  // Conditional visibility.
  // -------------------------------------------------------------------------

  /// Shows the field named [name] only while [predicate] holds over the
  /// values of all registered fields. Predicates re-evaluate on every field
  /// change. Hidden fields are excluded from validation and [values], but
  /// keep their state so they restore when shown again.
  void setVisibleWhen(
    String name,
    bool Function(Map<String, Object?> values) predicate,
  ) {
    _visibilityPredicates[name] = predicate;
    _evaluateVisibility();
    notifyListeners();
  }

  /// Removes the visibility predicate for [name] (the field is always shown).
  void clearVisibleWhen(String name) {
    _visibilityPredicates.remove(name);
    _hidden.remove(name);
    notifyListeners();
  }

  /// Whether the field named [name] is currently visible. Unknown names
  /// report visible.
  bool isVisible(String name) => !_hidden.contains(name);

  void _evaluateVisibility() {
    final all = <String, Object?>{
      for (final entry in _entries.entries) entry.key: entry.value.getValue(),
    };
    var changed = false;
    for (final name in _entries.keys) {
      final predicate = _visibilityPredicates[name];
      final visible = predicate == null || predicate(all);
      final hidden = !visible;
      if (_hidden.contains(name) != hidden) {
        changed = true;
        if (hidden) {
          _hidden.add(name);
        } else {
          _hidden.remove(name);
        }
      }
    }
    if (changed) notifyListeners();
  }

  /// Called by registered fields when their value changes.
  void fieldDidChange(String name) {
    _evaluateVisibility();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Validation.
  // -------------------------------------------------------------------------

  /// Validates every visible registered field: sync validators first, then
  /// async validators for the fields that passed sync. Per-field errors are
  /// updated as it goes; [isValidating] is true while async work is in
  /// flight. Returns whether the whole form is valid.
  Future<bool> validateAll() => validateFields(_entries.keys.where(isVisible));

  /// Validates a subset of fields by name — the wizard hook. Unknown or
  /// hidden names are skipped. Use with a stepper's continue handler:
  ///
  /// ```dart
  /// onStepContinue: (step) => controller.validateFields(_stepFields[step]),
  /// ```
  Future<bool> validateFields(Iterable<String> names) async {
    final targets = <String>[
      for (final name in names)
        if (_entries.containsKey(name) && isVisible(name)) name,
    ];
    _submitted = true;
    var syncOk = true;
    for (final name in targets) {
      final ok = _entries[name]!.validateAndShow();
      _lastSyncValid[name] = ok;
      if (!ok) syncOk = false;
    }
    // Drop stale async errors for fields being revalidated.
    for (final name in targets) {
      _asyncErrors.remove(name);
    }
    notifyListeners();

    final asyncTargets = <String>[
      for (final name in targets)
        if (_asyncValidators.containsKey(name) && _lastSyncValid[name] == true)
          name,
    ];
    if (asyncTargets.isNotEmpty) {
      _validating += asyncTargets.length;
      notifyListeners();
      try {
        final results = await Future.wait([
          for (final name in asyncTargets)
            _asyncValidators[name]!(
              _entries[name]!.getValue(),
            ).then((error) => MapEntry(name, error)),
        ]);
        for (final result in results) {
          if (result.value != null) {
            _asyncErrors[result.key] = result.value!;
          } else {
            _asyncErrors.remove(result.key);
          }
        }
      } finally {
        _validating -= asyncTargets.length;
        notifyListeners();
      }
    }
    return isValid && syncOk;
  }

  /// True while one or more async validators are in flight.
  bool get isValidating => _validating > 0;

  /// Whether every visible field currently passes its sync validator and
  /// no async errors are present. Pure: validators run without side effects.
  /// Listenable via this controller — it notifies on every field change,
  /// validation, visibility change, and reset.
  bool get isValid {
    for (final entry in _entries.entries) {
      if (!isVisible(entry.key)) continue;
      if (entry.value.validatePure() != null) return false;
      if (_asyncErrors[entry.key] != null) return false;
    }
    return true;
  }

  // -------------------------------------------------------------------------
  // Aggregates, values, reset.
  // -------------------------------------------------------------------------

  /// True when any registered field's value differs from its initial value.
  bool get isDirty {
    for (final entry in _entries.values) {
      if (entry.getValue() != entry.getInitialValue()) return true;
    }
    return false;
  }

  /// True once the user has interacted (any value changed) or a validation
  /// was requested. Never true on first paint.
  bool get isTouched => _submitted || isDirty;

  /// Current values keyed by field name. Hidden fields are excluded — they
  /// keep their state but do not submit.
  Map<String, Object?> get values => <String, Object?>{
    for (final entry in _entries.entries)
      if (isVisible(entry.key)) entry.key: entry.value.getValue(),
  };

  /// Restores every field to its initial value, clears errors (sync and
  /// async), submission state, and re-evaluates visibility.
  void reset() {
    for (final entry in _entries.values) {
      entry.resetField();
    }
    _asyncErrors.clear();
    _lastSyncValid.clear();
    _submitted = false;
    _evaluateVisibility();
    notifyListeners();
  }
}

/// Registration adapter: the controller talks to fields only through these
/// closures, so it never depends on widget types. Built by
/// [FwFormFieldRegistration] for `Fw*` fields; custom fields can construct
/// one directly and use [FwFormController.registerField].
class FwFieldEntry {
  FwFieldEntry({
    required this.name,
    required this.getValue,
    required this.getInitialValue,
    required this.validatePure,
    required this.validateAndShow,
    required this.resetField,
  });

  /// Unique field name within the form.
  final String name;

  /// Current value. For visibility predicates and [FwFormController.values].
  final Object? Function() getValue;

  /// Value captured at registration; drives [FwFormController.isDirty].
  final Object? Function() getInitialValue;

  /// Runs the field's sync validator without side effects.
  final String? Function() validatePure;

  /// Runs the sync validator, updates the displayed error, returns validity.
  final bool Function() validateAndShow;

  /// Restores the initial value and clears the displayed error.
  final void Function() resetField;
}

/// Scope widget that connects [FwFormController] to descendant fields.
///
/// Named `Fw*` fields (`formName` set) inside [FwForm] auto-register with
/// [controller]; fields outside it, or without `formName`, are unaffected.
/// The scope rebuilds when the controller notifies so async errors and
/// validation state reach the fields.
///
/// The controller is app-owned: [FwForm] never disposes it.
class FwForm extends StatefulWidget {
  const FwForm({super.key, required this.controller, required this.child});

  final FwFormController controller;
  final Widget child;

  /// The nearest [FwForm]'s controller. Throws in debug when no [FwForm]
  /// is in scope — prefer [maybeOf] in reusable code.
  static FwFormController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FwFormScope>();
    assert(scope != null, 'FwForm.of() called with no FwForm in scope.');
    return scope!.controller;
  }

  /// The nearest [FwForm]'s controller, or null when there is none.
  static FwFormController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FwFormScope>()?.controller;

  @override
  State<FwForm> createState() => _FwFormState();
}

class _FwFormState extends State<FwForm> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(FwForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return FwFormScope(controller: widget.controller, child: widget.child);
  }
}

/// Inherited form scope. Usually accessed via [FwForm.of]/[FwForm.maybeOf];
/// [FwForm] keeps it in sync with the controller.
class FwFormScope extends InheritedWidget {
  const FwFormScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final FwFormController controller;

  static FwFormScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FwFormScope>();

  @override
  bool updateShouldNotify(FwFormScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Mixin for `Fw*` field states: auto-registers the field with the nearest
/// [FwForm] under the widget's `formName`.
///
/// Apply to a `FormFieldState` subclass and expose `formName` on the widget:
///
/// ```dart
/// class _FwTextFieldState extends FormFieldState<String>
///     with FwFormFieldRegistration<String> {
///   @override
///   String? get formName => widget.formName; // widget has the param
/// }
/// ```
///
/// Registration happens in `didChangeDependencies` (the earliest point the
/// inherited scope is readable) and is idempotent across rebuilds; the
/// field unregisters in `dispose`. `didChange` is observed to drive
/// [FwFormController.isDirty]/[FwFormController.values] and re-evaluate
/// visibility predicates.
mixin FwFormFieldRegistration<T> on FormFieldState<T> {
  /// The field's name in the form. Null (the default) opts out of
  /// registration; the field then behaves exactly as without a form.
  String? get formName;

  FwFormController? _formController;
  Object? _formInitialValue;
  String? _registeredName;

  /// This field's current controller-level async error, if any. Fields
  /// merge it into their displayed error: external > async > sync.
  String? get formAsyncError {
    final controller = _formController;
    final name = _registeredName;
    if (controller == null || name == null) return null;
    return controller.asyncErrorFor(name);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = FwFormScope.maybeOf(context)?.controller;
    final name = formName;
    if (controller != _formController || _registeredName != name) {
      if (_formController != null && _registeredName != null) {
        _formController!.unregisterField(_registeredName!);
      }
      _formController = controller;
      _registeredName = null;
      if (controller != null && name != null) {
        _formInitialValue = value;
        controller.registerField(
          FwFieldEntry(
            name: name,
            getValue: () => value,
            getInitialValue: () => _formInitialValue,
            validatePure: () => widget.validator?.call(value),
            validateAndShow: () => validate(),
            resetField: () => reset(),
          ),
        );
        _registeredName = name;
      }
    }
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    final controller = _formController;
    final name = _registeredName;
    if (controller != null && name != null) {
      controller.fieldDidChange(name);
    }
  }

  @override
  void dispose() {
    final controller = _formController;
    final name = _registeredName;
    if (controller != null && name != null) {
      controller.unregisterField(name);
    }
    _formController = null;
    _registeredName = null;
    super.dispose();
  }
}

/// Shows [child] only while the form field [name] is visible per the
/// controller's visibility predicates. State is maintained while hidden so
/// the field restores when shown again; hidden fields are excluded from
/// validation and [FwFormController.values] regardless.
///
/// Reads the controller from the nearest [FwForm].
class FwFormVisibility extends StatelessWidget {
  const FwFormVisibility({
    super.key,
    required this.name,
    required this.child,
    this.maintainState = true,
  });

  /// Field name whose visibility gates [child].
  final String name;
  final Widget child;

  /// Keep the subtree alive while hidden (default true) so field state
  /// restores when shown again.
  final bool maintainState;

  @override
  Widget build(BuildContext context) {
    final controller = FwForm.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => Visibility(
        visible: controller.isVisible(name),
        maintainState: maintainState,
        child: child!,
      ),
      child: child,
    );
  }
}
