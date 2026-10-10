# Adapters

Optional adapters bridge the framework to platform capabilities. Per the
delivery plan, 1.x and optional adapters are **out of scope** for this
release — this page records the policy, not a catalog.

## Policy

- The core framework has **zero platform plugins**. Anything needing a
  plugin (push delivery, native share sheets, biometric auth) stays in
  the app or in an explicitly versioned adapter package.
- An adapter, if added later, must document: installation, capabilities,
  and platform limitations — especially where behavior degrades
  (e.g. haptics on web, clipboard permissions).
- Adapters never change widget APIs: they plug into existing seams
  (`FwHaptics` signals, `FwToast` host, notification deep-link
  callbacks).

## Current seams

| Seam | Adapter hook |
|---|---|
| `FwHaptics` | Platform haptic engine; no-op default |
| Clipboard | `Clipboard.setData` via app code; web permission caveats apply |
| Notification deep links | App-owned callbacks; push transport is platform work |
| W3C token JSON | Consumed by web/design tools directly |

If your app needs a capability listed here, implement it against the seam
— don't fork the widget.
