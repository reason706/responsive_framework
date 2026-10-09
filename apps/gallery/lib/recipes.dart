import 'package:flutter/material.dart';
import 'package:fw_components/fw_components.dart';
import 'package:fw_core/fw_core.dart';
import 'package:fw_layout/fw_layout.dart';

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
        SizedBox(height: 24),
        DashboardRecipe(),
        SizedBox(height: 24),
        MasterDetailRecipe(),
        SizedBox(height: 24),
        DataPageRecipe(),
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

// ---------------------------------------------------------------------------
// Dashboard recipe (P5.6 exit gate).
// ---------------------------------------------------------------------------

/// Dashboard recipe: proves the adaptive navigation contract.
///
/// One [FwAdaptiveScaffold] renders bottom navigation on compact widths,
/// a rail on medium, and a sidebar on expanded — all driven by a single
/// selection model ([_selected]). Destination state (including a text
/// field and a scroll position) survives width transitions because bodies
/// stay mounted in the scaffold's IndexedStack.
///
/// Route-neutral contracts: [onNavigate] maps destination ids to routes
/// (e.g. `context.go('/${id}')` with go_router, or `Navigator.pushNamed`).
/// Deep links set the initial [initialDestination].
class DashboardRecipe extends StatefulWidget {
  const DashboardRecipe({
    super.key,
    this.initialDestination = 'overview',
    this.onNavigate,
  });

  final String initialDestination;

  /// Route-neutral navigation contract: the app maps the destination id
  /// to its router. Called on every selection change.
  final ValueChanged<String>? onNavigate;

  @override
  State<DashboardRecipe> createState() => _DashboardRecipeState();
}

class _DashboardRecipeState extends State<DashboardRecipe> {
  late String _selected = widget.initialDestination;
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();

  static const _destinations = [
    FwDestination(
      id: 'overview',
      label: 'Overview',
      icon: Icon(Icons.dashboard_outlined),
    ),
    FwDestination(
      id: 'analytics',
      label: 'Analytics and reporting',
      icon: Icon(Icons.analytics_outlined),
      badgeLabel: '4',
    ),
    FwDestination(
      id: 'customers',
      label: 'Customer management',
      icon: Icon(Icons.people_outlined),
    ),
    FwDestination(
      id: 'settings',
      label: 'Settings and preferences',
      icon: Icon(Icons.settings_outlined),
    ),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _select(String id) {
    setState(() => _selected = id);
    widget.onNavigate?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Dashboard recipe',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Resize the window (or use the gallery width slider): bottom '
          'navigation on phone, rail on tablet, sidebar on desktop. The '
          'selected destination, the notes field, and the list scroll '
          'position survive every transition. Long labels truncate '
          'gracefully.',
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: FwAdaptiveScaffold(
            destinations: _destinations,
            selectedId: _selected,
            onDestinationSelected: _select,
            header: FwNavbar(
              title: 'Acme Dashboard',
              actions: [
                FwIconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
              ],
              compactActions: [
                FwIconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More',
                  onPressed: () {},
                ),
              ],
            ),
            bodies: {
              'overview': _DashboardBody(
                title: 'Overview',
                notesController: _notesController,
                scrollController: _scrollController,
              ),
              'analytics': const Center(child: Text('Analytics and reporting')),
              'customers': const Center(child: Text('Customer management')),
              'settings': const Center(child: Text('Settings and preferences')),
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.title,
    required this.notesController,
    required this.scrollController,
  });

  final String title;
  final TextEditingController notesController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return FwScrollArea(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'The notes field and this list keep their state when the '
            'viewport crosses breakpoints.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (state survives width changes)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 30; i++)
            Card(
              child: ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text('Metric ${i + 1}'),
                subtitle: const Text(
                  'Long labels truncate; layout never breaks.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Master-detail recipe (P5.6 exit gate).
// ---------------------------------------------------------------------------

/// Master-detail recipe: a list pane and a detail pane with route-neutral
/// selection.
///
/// On wide screens both panes show side by side; on narrow the detail
/// pushes full-screen with system-back support. [onSelectItem] maps the
/// selected id to a route (e.g. `/items/:id`); deep links set
/// [initialItemId].
class MasterDetailRecipe extends StatefulWidget {
  const MasterDetailRecipe({super.key, this.initialItemId, this.onSelectItem});

  final String? initialItemId;
  final ValueChanged<String?>? onSelectItem;

  @override
  State<MasterDetailRecipe> createState() => _MasterDetailRecipeState();
}

class _MasterDetailRecipeState extends State<MasterDetailRecipe> {
  late String? _selected = widget.initialItemId;
  final _detailScroll = ScrollController();

  static const _items = [
    'Apollo project',
    'Zephyr launch',
    'Nimbus refactor',
    'Atlas migration',
    'Orion dashboard',
  ];

  @override
  void dispose() {
    _detailScroll.dispose();
    super.dispose();
  }

  void _select(String? id) {
    setState(() => _selected = id);
    widget.onSelectItem?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Master-detail recipe',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Narrow: detail covers the list; system back returns. Wide: '
          'side-by-side. The detail scroll position survives.',
        ),
        const SizedBox(height: 16),
        Container(
          height: 420,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: FwMasterDetail(
            master: ListView(
              children: [
                for (var i = 0; i < _items.length; i++)
                  ListTile(
                    title: Text(_items[i]),
                    selected: _selected == 'item-$i',
                    onTap: () => _select('item-$i'),
                  ),
              ],
            ),
            detail: FwScrollArea(
              controller: _detailScroll,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _selected ?? 'none',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < 20; i++)
                    Text('Detail paragraph ${i + 1} for $_selected.'),
                ],
              ),
            ),
            selectedId: _selected,
            onSelected: _select,
            emptyDetail: const Center(
              child: Text('Select an item from the list'),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data page (Phase 6 exit gate).
// ---------------------------------------------------------------------------

/// Product row for the data page recipe.
@immutable
class _RecipeProduct {
  const _RecipeProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.status,
    required this.stock,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final FwIntent status;
  final int stock;
}

/// Phase 6 exit-gate recipe: searchable, sortable, paginated data page.
///
/// State machine:
/// ```
/// idle ──search──▶ idle (filtered, page reset to 1)
/// idle ──sort────▶ idle (sorted by column)
/// idle ──page────▶ idle (page N)
/// idle ──delete──▶ confirming ──confirm──▶ idle (item removed)
///                  └──cancel──▶ idle
/// ```
///
/// The app owns ALL data operations: filtering, sorting, and paging happen
/// in this State (standing in for a backend). [FwDataTable] only reports
/// user intent via onSort/onSelectionChanged. Nothing here claims
/// server-side behavior — wire these callbacks to your API.
///
/// On phones (below the compact breakpoint) rows become cards via
/// [FwDataTable.compactBuilder]; every essential field and row action is
/// represented in the card, and the layout survives large text.
class DataPageRecipe extends StatefulWidget {
  const DataPageRecipe({super.key});

  @override
  State<DataPageRecipe> createState() => _DataPageRecipeState();
}

class _DataPageRecipeState extends State<DataPageRecipe> {
  static const _pageSize = 5;

  final List<_RecipeProduct> _all = const [
    _RecipeProduct(
      id: 'p1',
      name: 'Acme Widget',
      category: 'Widgets',
      price: 19.99,
      status: FwIntent.success,
      stock: 142,
    ),
    _RecipeProduct(
      id: 'p2',
      name: 'Acme Gizmo',
      category: 'Gizmos',
      price: 49.99,
      status: FwIntent.success,
      stock: 87,
    ),
    _RecipeProduct(
      id: 'p3',
      name: 'Acme Doohickey',
      category: 'Widgets',
      price: 9.99,
      status: FwIntent.warning,
      stock: 12,
    ),
    _RecipeProduct(
      id: 'p4',
      name: 'Acme Thingamajig',
      category: 'Gizmos',
      price: 99.99,
      status: FwIntent.danger,
      stock: 0,
    ),
    _RecipeProduct(
      id: 'p5',
      name: 'Acme Contraption',
      category: 'Contraptions',
      price: 29.99,
      status: FwIntent.success,
      stock: 203,
    ),
    _RecipeProduct(
      id: 'p6',
      name: 'Acme Apparatus',
      category: 'Contraptions',
      price: 79.99,
      status: FwIntent.info,
      stock: 45,
    ),
    _RecipeProduct(
      id: 'p7',
      name: 'Acme Implement',
      category: 'Widgets',
      price: 14.99,
      status: FwIntent.success,
      stock: 98,
    ),
    _RecipeProduct(
      id: 'p8',
      name: 'Acme Utensil',
      category: 'Gizmos',
      price: 39.99,
      status: FwIntent.warning,
      stock: 7,
    ),
  ];

  final List<_RecipeProduct> _products = [];
  String _query = '';
  String? _sortId = 'name';
  bool _ascending = true;
  int _page = 1;
  Set<String> _selected = const {};

  @override
  void initState() {
    super.initState();
    _products.addAll(_all);
  }

  /// App-owned filtering + sorting (a backend would do this).
  List<_RecipeProduct> get _visible {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<_RecipeProduct>.of(_products)
        : _products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(q) ||
                    p.category.toLowerCase().contains(q),
              )
              .toList();
    switch (_sortId) {
      case 'name':
        filtered.sort(
          (a, b) =>
              _ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
      case 'price':
        filtered.sort(
          (a, b) => _ascending
              ? a.price.compareTo(b.price)
              : b.price.compareTo(a.price),
        );
      case 'stock':
        filtered.sort(
          (a, b) => _ascending
              ? a.stock.compareTo(b.stock)
              : b.stock.compareTo(a.stock),
        );
    }
    return filtered;
  }

  List<_RecipeProduct> get _pageRows {
    final visible = _visible;
    final start = (_page - 1) * _pageSize;
    if (start >= visible.length) return const [];
    return visible.sublist(start, (start + _pageSize).clamp(0, visible.length));
  }

  int get _pageCount => (_visible.length / _pageSize).ceil().clamp(1, 1 << 30);

  String _statusLabel(FwIntent status) => switch (status) {
    FwIntent.success => 'In stock',
    FwIntent.warning => 'Low stock',
    FwIntent.danger => 'Out of stock',
    FwIntent.info => 'New arrival',
    _ => 'Unknown',
  };

  Future<void> _confirmDelete(_RecipeProduct product) async {
    final result = await FwConfirmDialog.show(
      context: context,
      title: 'Delete ${product.name}?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    final confirmed = result.value ?? false;
    if (confirmed && mounted) {
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
        _selected = _selected.difference({product.id});
        if (_page > _pageCount) _page = _pageCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final spacing = theme.spaceScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Product inventory',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Search, sort, page, and manage products. Filtering, sorting, '
          'and paging are app-owned here — the table reports intent.',
        ),
        SizedBox(height: spacing.of(FwSpace.s4, context)),
        // Summary stats (D06 in context).
        Wrap(
          spacing: spacing.of(FwSpace.s6, context),
          runSpacing: spacing.of(FwSpace.s3, context),
          children: [
            FwStat(value: '${_products.length}', label: 'Products'),
            FwStat(value: '${_visible.length}', label: 'Matching search'),
            FwStat(value: '${_selected.length}', label: 'Selected'),
          ],
        ),
        SizedBox(height: spacing.of(FwSpace.s4, context)),
        FwSearchField(
          label: 'Search products',
          hintText: 'Name or category…',
          onChanged: (value) => setState(() {
            _query = value;
            _page = 1;
          }),
        ),
        SizedBox(height: spacing.of(FwSpace.s3, context)),
        FwDataTable<_RecipeProduct>(
          columns: [
            FwDataColumn<_RecipeProduct>(
              id: 'name',
              label: 'Product',
              sortable: true,
              cell: (p) => Text(p.name),
            ),
            FwDataColumn<_RecipeProduct>(
              id: 'category',
              label: 'Category',
              cell: (p) => Text(p.category),
            ),
            FwDataColumn<_RecipeProduct>(
              id: 'price',
              label: 'Price',
              sortable: true,
              numeric: true,
              cell: (p) => Text('\$${p.price.toStringAsFixed(2)}'),
            ),
            FwDataColumn<_RecipeProduct>(
              id: 'stock',
              label: 'Stock',
              sortable: true,
              numeric: true,
              cell: (p) => Text('${p.stock}'),
            ),
            FwDataColumn<_RecipeProduct>(
              id: 'status',
              label: 'Status',
              cell: (p) =>
                  FwStatusDot(label: _statusLabel(p.status), intent: p.status),
            ),
          ],
          rows: _pageRows,
          getRowId: (p) => p.id,
          sortColumnId: _sortId,
          sortAscending: _ascending,
          onSort: (id) => setState(() {
            if (_sortId == id) {
              _ascending = !_ascending;
            } else {
              _sortId = id;
              _ascending = true;
            }
          }),
          selectable: true,
          selectedIds: _selected,
          onSelectionChanged: (ids) => setState(() => _selected = ids),
          rowActions: (p) => [
            FwDataRowAction<_RecipeProduct>(
              id: 'delete',
              label: 'Delete ${p.name}',
              icon: Icons.delete,
              onInvoked: _confirmDelete,
            ),
          ],
          emptyLabel: _query.isEmpty
              ? 'No products'
              : 'No products match "$_query"',
          semanticLabel: 'Product inventory',
          compactBuilder: (context, scope) {
            final p = scope.row;
            return Card(
              child: Padding(
                padding: EdgeInsets.all(spacing.of(FwSpace.s3, context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: theme.typeScale.resolve(
                              FwTextRole.body,
                              context,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: scope.selected,
                          onChanged: (v) => scope.onSelected(v ?? false),
                        ),
                      ],
                    ),
                    Text(
                      '${p.category} · \$${p.price.toStringAsFixed(2)} · '
                      'Stock: ${p.stock}',
                      style: theme.typeScale.resolve(
                        FwTextRole.bodySm,
                        context,
                      ),
                    ),
                    SizedBox(height: spacing.of(FwSpace.s2, context)),
                    Row(
                      children: [
                        Expanded(
                          child: FwStatusDot(
                            label: _statusLabel(p.status),
                            intent: p.status,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete ${p.name}',
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(p),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: spacing.of(FwSpace.s3, context)),
        // App-owned paging.
        FwPagination(
          page: _page,
          pageCount: _pageCount,
          onPageChanged: (page) => setState(() => _page = page),
        ),
      ],
    );
  }
}
