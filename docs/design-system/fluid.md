# Fluid values

Some lengths should interpolate between breakpoints instead of jumping.
The framework supports fluid values that resolve against the container
width: declare a min/max pair and the value blends across the range.

Use fluid values for:

- Page insets that grow on wide screens (`FwSpaceAlias.pageInset`).
- Section gaps that breathe more on desktop.
- Type sizes only where the design explicitly calls for fluid type —
  default to stepped roles from `FwTextRole`.

Rules:

- Fluid ranges are declared in root-relative units, not pixels.
- Every fluid value documents its min width, max width, min value, and
  max value; clamping outside the range is mandatory.
- Never use fluid values for touch targets or text line-height — those
  must stay predictable for accessibility.
