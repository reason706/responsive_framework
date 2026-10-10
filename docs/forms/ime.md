# IME & keyboard input

- Set `keyboardType` and `textInputAction` per field (`emailAddress`,
  `phone`, `number`, `visiblePassword`); `textInputAction.next` moves
  focus through the form.
- `autofillHints` enable platform autofill (`AutofillHints.email`,
  `oneTimeCode` for `FwOtpInput`, etc.).
- Input formatters shape input as the user types (phone masks, card
  numbers) without fighting the cursor; keep them pure and reversible.
- The software keyboard must not cover the focused field: form sheets
  inset for `viewInsets`; test at 2× text scaling.

Never disable the keyboard or force a custom keyboard without a
fallback — IME behavior is platform-owned.
