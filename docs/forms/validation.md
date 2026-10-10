# Validation timing

Validation can run at three moments — pick deliberately per field:

| Timing | When | Use for |
|---|---|---|
| On change | Every keystroke | Live feedback (password strength, character counts) |
| On blur | Field loses focus | Format checks (email, phone) without nagging |
| On submit | Form save | Required fields, cross-field rules |

Rules:

- Don't show errors before the user has interacted (no red on first
  paint). The field shell tracks "touched" state.
- Error messages are specific and actionable: "Enter an email address",
  not "Invalid input". See [error summary](error-summary.md).
- Async validators show a pending indicator and never leave stale errors
  after newer input (stale-async guard).
- Validation state is part of semantics: screen readers announce errors
  via the field's error text.
