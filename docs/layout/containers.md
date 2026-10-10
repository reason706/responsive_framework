# Containers

Layout starts from bounded containers. Rules:

- Prefer `FwResponsiveBuilder` (container queries via `LayoutBuilder`)
  over `MediaQuery` for layout decisions — components adapt to their
  available width, not the device.
- `FwResponsiveBuilder` requires bounded width and exposes
  `(context, width, breakpoint)`; breakpoints come from the theme
  (`theme.breakpoints.at(width)`).
- Cards and panels (`FwCard`) are the default content containers; they
  resolve padding from `FwSpaceAlias.cardInset`.
- Avoid unbounded nesting: a scrollable inside a scrollable needs an
  explicit extent (see [scrolling](scrolling.md)).
