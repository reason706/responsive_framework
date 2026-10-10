# Grid math

`FwGrid` tokens define columns, gutters, and margins per viewport class
(compact / medium / expanded):

```dart
final spec = const FwGrid().of(context);
// spec.columns, spec.gutter, spec.margin — all root-relative
```

- 4 / 8 / 12 columns across the viewport classes; gutters and margins
  from the spacing scale.
- `FwAutoGrid` places children into as many columns as fit (auto-fit),
  with a minimum cell width — no manual breakpoint math.
- The gallery's width slider drives the real grid constraints, so what
  you see is what ships.

Rules: gutters come from tokens, never literals; grid math is
container-relative (a grid inside a 400px panel uses the compact spec
even on desktop).
