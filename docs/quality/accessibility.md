# Accessibility responsibility

Accessibility is a shared contract: the framework provides the mechanics,
the app provides the content.

## What the framework guarantees

- Every interactive component exposes proper semantics (button, link,
  header, slider value, checked state, dialog).
- Focus is always visible (`FwColorRole.focusRing`); keyboard maps are
  documented per component.
- `TextScaler` is applied exactly once — OS text-size settings work.
- Reduced motion collapses animations to instant transitions.
- Touch targets ≥ 48dp; contrast floors ≥ 4.5:1 (7:1 in high-contrast
  presets); status never depends on color alone.

## What the app owns

- Meaningful labels: `semanticLabel` on icon-only buttons, `label` on
  every field, alt text via `FwImage(semanticLabel:)`.
- Heading structure through `FwText(heading: true)`.
- Error messages that say what to do, announced via the field shell.
- Testing with real assistive tech (see [testing](testing.md)).

## Non-negotiables

- Gesture confirmations (slide/hold) always ship a non-gesture
  alternative.
- No `ExcludeSemantics` to hide meaningful content; decorative-only
  widgets opt out explicitly.
- New components add semantics tests with the widget tests — no
  exceptions.
