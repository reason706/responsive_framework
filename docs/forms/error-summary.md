# Error summary

When a form has multiple errors, show a summary at the top that:

1. States how many fields need attention.
2. Lists each error as a link that focuses the field.
3. Moves screen-reader focus to the summary on submit.

```dart
if (!formKey.currentState!.validate()) {
  // collect (fieldLabel, message) pairs from validators
  showDialog(...FwAlert with error links...);
}
```

Rules:

- The summary and inline field errors always agree.
- Errors link to fields — never make the user hunt.
- Keep the summary visible until all errors clear; announce changes via
  live region semantics.
