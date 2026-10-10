# Form reset & save

```dart
final key = GlobalKey<FormState>();

Form(
  key: key,
  child: Column(children: [/* FwTextField etc. */]),
);

void _save() {
  if (key.currentState!.validate()) {
    key.currentState!.save();
    // submit with the collected values
  }
}
```

Rules:

- `validate()` runs all field validators; on failure, focus moves to the
  first invalid field and the [error summary](error-summary.md) appears.
- `reset()` restores initial values and clears touched/error state.
- Save is async-safe: disable the submit button (`loading: true` on
  `FwButton`) while the save is in flight; the confirm-dialog busy lock
  pattern (`FwConfirmDialog`) prevents double-submit and dismiss races.
- After a failed save, keep user input — never clear a form on error.
