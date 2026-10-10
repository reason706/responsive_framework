# RTL

Right-to-left layouts work throughout:

- All insets are directional (`FwInsets` → `EdgeInsetsDirectional`);
  stacks lay out start-to-end automatically.
- Icon placement uses logical start/end — never physical left/right in
  new APIs. `iconAlignment` flips in RTL.
- Sliders keep logical semantics in RTL (min stays at the logical
  start); vertical sliders are unaffected.
- The gallery has an RTL toggle; the 320px/2×-text/RTL stress test runs
  the whole catalog and has caught real overflows.

App rules:

- Don't mirror icons that shouldn't flip (clocks, media play/pause
  follow platform convention — check, don't assume).
- Test every screen in RTL mode before release; text expansion in
  translation often breaks layouts that survive LTR.
