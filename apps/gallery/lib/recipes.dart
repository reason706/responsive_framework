import 'package:flutter/material.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';

/// Phase 3 exit-gate recipes: complete forms exercising validate/save/reset.
///
/// Each recipe documents its state machine (the "behavior-specifying
/// components" rule): the states, the events that transition between them,
/// and what the user sees in each state. Form state lives in [State]
/// objects (controllers, not build locals), so values survive theme and
/// width changes — the gallery's own theme toggle is the test.
class RecipeSection extends StatelessWidget {
  const RecipeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recipes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Complete forms with documented state machines. State lives in '
          'State objects, so values survive the theme toggle above and '
          'width changes.',
        ),
        SizedBox(height: 16),
        RegistrationFormRecipe(),
        SizedBox(height: 24),
        SettingsFormRecipe(),
        SizedBox(height: 24),
        EventSchedulingRecipe(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Registration form.
// ---------------------------------------------------------------------------

/// Registration form state machine:
///
/// ```
/// idle ──submit──▶ validating ──valid──▶ submitting ──ok──▶ success
///   ▲                  │                      │
///   │                invalid               failure
///   │                  │                      │
///   │                  ▼                      ▼
///   └────────────── idle ◀──────────────── error
///        (reset / edit)          (dismiss / edit)
/// ```
///
/// - idle: editable; errors from a previous validation persist until fixed.
/// - validating: synchronous; invalid fields show FwField errors and focus
///   moves to the first invalid field.
/// - submitting: inputs disabled; FwBusyIndicator with live-region status.
/// - success: FwAlert (announced); form cleared.
/// - error: FwAlert (announced) with retry; inputs re-enabled, values kept.
enum _RegistrationState { idle, validating, submitting, success, error }

class RegistrationFormRecipe extends StatefulWidget {
  const RegistrationFormRecipe({super.key});

  @override
  State<RegistrationFormRecipe> createState() => _RegistrationFormRecipeState();
}

class _RegistrationFormRecipeState extends State<RegistrationFormRecipe> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  FwPhoneNumber? _phone;
  String? _country;
  bool _terms = false;
  var _state = _RegistrationState.idle;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _state = _RegistrationState.validating);
    final valid = _formKey.currentState!.validate() && _terms;
    if (!valid) {
      setState(() => _state = _RegistrationState.idle);
      return;
    }
    setState(() => _state = _RegistrationState.submitting);
    // Simulated async registration.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    // Fail when the email contains "fail" — a deterministic demo hook.
    if (_email.text.contains('fail')) {
      setState(() {
        _state = _RegistrationState.error;
        _errorMessage = 'The email ${_email.text} is already registered.';
      });
    } else {
      setState(() => _state = _RegistrationState.success);
    }
  }

  void _reset() {
    _formKey.currentState!.reset();
    _name.clear();
    _email.clear();
    _password.clear();
    setState(() {
      _phone = null;
      _country = null;
      _terms = false;
      _state = _RegistrationState.idle;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final submitting = _state == _RegistrationState.submitting;

    return FwCard(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Registration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'State machine: idle → validating → submitting → success | error. '
            'Try an email containing "fail" to see the error state.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_state == _RegistrationState.success)
            FwAlert(
              intent: FwAlertIntent.success,
              title: 'Account created',
              body:
                  'Welcome, ${_name.text}!'
                  '${_phone == null ? '' : ' We\'ll text ${_phone!.e164}.'}',
              announce: true,
              onDismiss: _reset,
            ),
          if (_state == _RegistrationState.error)
            FwAlert(
              intent: FwAlertIntent.danger,
              title: 'Registration failed',
              body: _errorMessage,
              announce: true,
              action: TextButton(
                onPressed: _submit,
                child: const Text('Try again'),
              ),
              onDismiss: () => setState(() => _state = _RegistrationState.idle),
            ),
          if (_state == _RegistrationState.success ||
              _state == _RegistrationState.error)
            const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FwTextField(
                  label: 'Full name',
                  controller: _name,
                  enabled: !submitting,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 12),
                FwTextField(
                  label: 'Email',
                  controller: _email,
                  enabled: !submitting,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                FwPasswordField(
                  label: 'Password',
                  controller: _password,
                  enabled: !submitting,
                  validator: (v) => (v == null || v.length < 8)
                      ? 'At least 8 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                FwPhoneField(
                  label: 'Phone',
                  enabled: !submitting,
                  onChanged: (n) => _phone = n,
                ),
                const SizedBox(height: 12),
                FwSelect<String>(
                  label: 'Country',
                  placeholder: 'Select a country',
                  enabled: !submitting,
                  options: const [
                    FwOption(value: 'au', label: 'Australia'),
                    FwOption(value: 'us', label: 'United States'),
                    FwOption(value: 'gb', label: 'United Kingdom'),
                  ],
                  value: _country,
                  onChanged: (v) => setState(() => _country = v),
                ),
                const SizedBox(height: 12),
                FwCheckbox(
                  label: 'I agree to the terms',
                  value: _terms,
                  enabled: !submitting,
                  onChanged: (v) => setState(() => _terms = v ?? false),
                ),
                if (!_terms && _state == _RegistrationState.validating)
                  const Text(
                    'You must accept the terms.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                const SizedBox(height: 16),
                if (submitting)
                  const FwBusyIndicator(label: 'Creating your account…')
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          child: const Text('Create account'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(onPressed: _reset, child: const Text('Reset')),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings form.
// ---------------------------------------------------------------------------

/// Settings form state machine:
///
/// ```
/// idle ──save──▶ saving ──ok──▶ saved ──edit──▶ idle
///                  │
///                failure
///                  │
///                  ▼
///                error ──dismiss──▶ idle
/// ```
///
/// Simpler than registration: no validation, just save/reset with
/// unambiguous feedback. Draft values are kept in state; Reset restores
/// the last saved values.
class SettingsFormRecipe extends StatefulWidget {
  const SettingsFormRecipe({super.key});

  @override
  State<SettingsFormRecipe> createState() => _SettingsFormRecipeState();
}

class _SettingsFormRecipeState extends State<SettingsFormRecipe> {
  bool _notifications = true;
  bool _marketing = false;
  String? _themeChoice = 'system';

  // Last saved snapshot for Reset.
  bool _savedNotifications = true;
  bool _savedMarketing = false;
  String? _savedThemeChoice = 'system';

  var _saving = false;
  var _saved = false;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
      _savedNotifications = _notifications;
      _savedMarketing = _marketing;
      _savedThemeChoice = _themeChoice;
    });
  }

  void _reset() {
    setState(() {
      _notifications = _savedNotifications;
      _marketing = _savedMarketing;
      _themeChoice = _savedThemeChoice;
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FwCard(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'State machine: idle → saving → saved. Reset restores the last '
            'saved values.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_saved)
            FwAlert(
              intent: FwAlertIntent.success,
              title: 'Settings saved',
              announce: true,
              onDismiss: () => setState(() => _saved = false),
            ),
          if (_saved) const SizedBox(height: 12),
          FwSwitch(
            label: 'Notifications',
            value: _notifications,
            enabled: !_saving,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          FwSwitch(
            label: 'Marketing emails',
            value: _marketing,
            enabled: !_saving,
            onChanged: (v) => setState(() => _marketing = v),
          ),
          const SizedBox(height: 12),
          FwSelect<String>(
            label: 'Theme',
            enabled: !_saving,
            options: const [
              FwOption(value: 'system', label: 'System'),
              FwOption(value: 'light', label: 'Light'),
              FwOption(value: 'dark', label: 'Dark'),
            ],
            value: _themeChoice,
            onChanged: (v) => setState(() => _themeChoice = v),
          ),
          const SizedBox(height: 16),
          if (_saving)
            const FwBusyIndicator(label: 'Saving…')
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save settings'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event scheduling recipe (Phase 4 exit gate).
// ---------------------------------------------------------------------------

/// Event-scheduling flow exercising overlays + pickers + toasts together:
/// pick date/time (F15/F16) → select attendees (F14) → confirm in a dialog
/// (O02) → toast the result (B02).
///
/// State lives in the State object, so values survive theme toggles and
/// width changes. Every step is keyboard and screen-reader operable:
/// fields are labelled, the dialog traps focus and restores it, the toast
/// announces via a live region without stealing focus.
class EventSchedulingRecipe extends StatefulWidget {
  const EventSchedulingRecipe({super.key});

  @override
  State<EventSchedulingRecipe> createState() => _EventSchedulingRecipeState();
}

class _EventSchedulingRecipeState extends State<EventSchedulingRecipe> {
  final _titleController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  Set<String> _attendees = {};
  String? _titleError;

  static const _people = [
    FwOption(value: 'ada', label: 'Ada Lovelace'),
    FwOption(value: 'grace', label: 'Grace Hopper'),
    FwOption(value: 'alan', label: 'Alan Turing'),
    FwOption(value: 'katherine', label: 'Katherine Johnson'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _valid =>
      _titleController.text.trim().isNotEmpty && _date != null && _time != null;

  String _summary() {
    final date = _date == null
        ? '—'
        : MaterialLocalizations.of(context).formatFullDate(_date!);
    final time = _time == null
        ? '—'
        : MaterialLocalizations.of(context).formatTimeOfDay(_time!);
    final attendees = _attendees.isEmpty
        ? 'Just you'
        : _attendees
              .map((id) => _people.firstWhere((p) => p.value == id).label)
              .join(', ');
    return '${_titleController.text.trim()}\n$date at $time\n$attendees';
  }

  Future<void> _schedule() async {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty
          ? 'Give the event a title'
          : null;
    });
    if (!_valid) return;

    // Confirm in a dialog (O02): the busy lock models the save.
    final busy = ValueNotifier<bool>(false);
    try {
      final result = await FwConfirmDialog.show(
        context: context,
        title: 'Schedule event?',
        message: _summary(),
        confirmLabel: 'Schedule',
        busy: busy,
      );
      if (result.reason == FwDismissReason.action && result.value == true) {
        busy.value = true;
        // Simulate the save; the dialog stays locked until we resolve.
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        busy.value = false;
        // Toast the result (B02): context-free, announced, no focus theft.
        FwToast.show(
          const FwToast(
            message: 'Event scheduled',
            severity: FwToastSeverity.success,
          ),
        );
        setState(() {
          _titleController.clear();
          _date = null;
          _time = null;
          _attendees = {};
        });
      }
    } finally {
      busy.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return FwCard(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Schedule an event',
            style: theme.typeScale.resolve(FwTextRole.h6, context),
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s3, context)),
          FwTextField(
            label: 'Event title',
            controller: _titleController,
            externalError: _titleError,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
          FwDateField(
            label: 'Date',
            value: _date,
            onChanged: (v) => setState(() => _date = v),
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
          FwTimeField(
            label: 'Time',
            value: _time,
            onChanged: (v) => setState(() => _time = v),
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s2, context)),
          FwMultiSelect<String>(
            label: 'Attendees',
            options: _people,
            selected: _attendees,
            onChanged: (s) => setState(() => _attendees = s),
          ),
          SizedBox(height: theme.spaceScale.of(FwSpace.s3, context)),
          FwButton(
            label: 'Review and schedule',
            variant: FwButtonVariant.solid,
            onPressed: _schedule,
          ),
        ],
      ),
    );
  }
}
