# Field lifecycle

Every input lives in the `FwField` shell (F01): label, helper text, and
error message share one layout so fields align in forms.

## Controlled vs uncontrolled

- **Controlled** (recommended): the caller owns the `TextEditingController`
  or value + `onChanged`, and disposes the controller. Use for forms with
  validation, formatting, or cross-field rules.
- **Uncontrolled**: the widget owns its state via `initialValue`. Use for
  simple, isolated inputs.

```dart
final controller = TextEditingController();

FwTextField(
  controller: controller,
  label: 'Email',
  helperText: 'We never share your email.',
  validator: (v) => v != null && v.contains('@') ? null : 'Enter an email',
  onChanged: (v) => setState(() {}),
)
```

## Ownership rules

- The creator disposes: if you pass a controller, you dispose it; if the
  widget creates one from `initialValue`, it disposes it.
- `validator` runs on demand (see [validation timing](validation.md));
  it must be pure — no side effects.
- Async work (suggestions, uniqueness checks) debounces (see
  `FwCombobox.debounce`) and guards against stale results (sequence ids);
  see [async suggestions](async.md).
