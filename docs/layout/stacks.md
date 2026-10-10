# Stacks & wrap

- `FwVStack` / `FwHStack` — gaps resolve against the container width;
  `gap` takes `FwSpace` tokens.
- `FwWrap` — flows children onto multiple lines with run spacing; the
  fix for narrow/large-text/RTL overflow (the gallery stress test caught
  a real overflow this way).
- `FwAutoGrid` — auto-fit grid; prefer over manual `Wrap` + width math.

Rules:

- Gaps are tokens, not doubles.
- In RTL, `FwHStack` lays out start-to-end automatically; never mirror
  manually.
- For forms, prefer `FwVStack(gap: FwSpaceAlias.fieldGap)` semantics via
  the field shell rather than raw stacks.
