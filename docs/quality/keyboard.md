# Keyboard reference

| Key | Action |
|---|---|
| Tab / Shift+Tab | Move focus through interactive elements |
| Enter / Space | Activate focused button, link, menu item |
| Arrow keys | Move within radio groups, sliders, menus, tabs, steppers |
| Home / End | Jump to first/last item in lists, menus, sliders |
| Escape | Dismiss dialog, sheet, popover, menu, suggestions |
| Type-ahead | Jump to matching item in menus and selects |

Component-specific maps (e.g. `FwStepper`'s `controlsBuilder`,
`FwCombobox` suggestion navigation) are documented on the component's
gallery board.

Rules:

- Every mouse/gesture action has a keyboard equivalent.
- Focus order follows visual order (which follows DOM order — don't
  reorder visually with `Stack`/`Positioned` against the semantics).
- Focus is trapped in modal dialogs and sheets; restored on dismiss.
