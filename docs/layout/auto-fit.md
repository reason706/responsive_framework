# Auto-fit

`FwAutoGrid` computes column count from available width and a minimum
cell width:

```dart
FwAutoGrid(
  minItemWidth: 160, // logical px at root 16; root-relative in practice
  gap: FwSpace.s3,
  children: [...],
)
```

Use for card grids, galleries, and dashboards where the column count
should be fluid. For fixed 12-column work, use [grid math](grid.md).

Rules: set a sensible `minItemWidth` so cells never squeeze below usable
size at 320px widths; test at 2× text scaling since labels grow.
