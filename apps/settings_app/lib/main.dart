/// Settings pilot: a settings/forms screen built ONLY on public fw exports.
///
/// Exercises: FwField shell, FwTextField validation, FwSwitch, FwSelect,
/// FwSlider, FwButton (loading), FwToast, theme preset switching.
import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

void main() => runApp(const SettingsPilotApp());

class SettingsPilotApp extends StatefulWidget {
  const SettingsPilotApp({super.key});

  @override
  State<SettingsPilotApp> createState() => _SettingsPilotAppState();
}

class _SettingsPilotAppState extends State<SettingsPilotApp> {
  int _preset = 0;
  bool _dark = false;

  static const _presets = ['Light', 'Ocean', 'Forest'];

  FwTheme get _theme {
    final base = switch (_preset) {
      1 => FwTheme.ocean(
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
      2 => FwTheme.forest(
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
      _ => _dark ? FwTheme.dark() : FwTheme.light(),
    };
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Settings pilot',
      theme: _theme.toThemeData(),
      builder: (context, child) => FwToastHost(child: child!),
      home: FwViewportQuery(
        child: SettingsPage(
          preset: _presets[_preset],
          dark: _dark,
          onPresetChanged: (v) => setState(() => _preset = v),
          onDarkChanged: (v) => setState(() => _dark = v),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.preset,
    required this.dark,
    required this.onPresetChanged,
    required this.onDarkChanged,
  });

  final String preset;
  final bool dark;
  final ValueChanged<int> onPresetChanged;
  final ValueChanged<bool> onDarkChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _notifications = true;
  bool _marketing = false;
  String _language = 'en';
  double _textScale = 1.0;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _saving = false);
    FwToast.show(const FwToast(message: 'Settings saved'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FwResponsiveBuilder(
        builder: (context, width, breakpoint) {
          final wide = width >= 720;
          final form = Form(
            key: _formKey,
            child: FwVStack(
              gap: FwSpace.s4,
              children: [
                const FwText('Profile', role: FwTextRole.h2, heading: true),
                FwTextField(
                  label: 'Display name',
                  controller: _name,
                  required: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a display name'
                      : null,
                ),
                FwTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email address'
                      : null,
                ),
                const FwText('Preferences', role: FwTextRole.h2, heading: true),
                FwSwitch(
                  label: 'Push notifications',
                  description: 'Order updates and mentions.',
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                FwSwitch(
                  label: 'Marketing email',
                  value: _marketing,
                  onChanged: (v) => setState(() => _marketing = v),
                ),
                FwSelect<String>(
                  label: 'Language',
                  value: _language,
                  options: const [
                    FwOption(value: 'en', label: 'English'),
                    FwOption(value: 'es', label: 'Español'),
                    FwOption(value: 'ar', label: 'العربية'),
                  ],
                  onChanged: (v) => setState(() => _language = v ?? 'en'),
                ),
                FwSlider(
                  label: 'Interface text size',
                  value: _textScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  onChanged: (v) => setState(() => _textScale = v),
                ),
                const FwText('Appearance', role: FwTextRole.h2, heading: true),
                FwSelect<int>(
                  label: 'Brand preset',
                  value: const [
                    'Light',
                    'Ocean',
                    'Forest',
                  ].indexOf(widget.preset),
                  options: const [
                    FwOption(value: 0, label: 'Light'),
                    FwOption(value: 1, label: 'Ocean'),
                    FwOption(value: 2, label: 'Forest'),
                  ],
                  onChanged: (v) => widget.onPresetChanged(v ?? 0),
                ),
                FwSwitch(
                  label: 'Dark mode',
                  value: widget.dark,
                  onChanged: widget.onDarkChanged,
                ),
                FwButton(
                  label: 'Save settings',
                  intent: FwIntent.primary,
                  loading: _saving,
                  loadingLabel: 'Saving…',
                  onPressed: _save,
                ),
              ],
            ),
          );
          return SingleChildScrollView(
            padding: FwInsets.token(FwSpace.s4).resolve(context),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: wide ? 560 : double.infinity,
                ),
                child: form,
              ),
            ),
          );
        },
      ),
    );
  }
}
