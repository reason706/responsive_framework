# Safe area & keyboard

- `FwResponsiveLayout` (from `FwGrid`) applies safe-area insets for the
  viewport class.
- Sheets and dialogs inset for the software keyboard (`viewInsets`):
  form sheets must keep the focused field visible — test with the
  keyboard open at 2× text scaling.
- Bottom navigation and snackbars sit above the system gesture bar; never
  hard-code bottom padding.

Rules: read insets from `MediaQuery`/`SafeArea`, never literals; the
toast host lives above the navigator so toasts aren't clipped by
keyboard or system bars.
