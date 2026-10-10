# Text scaling

The OS text scaler flows through `MediaQuery` and is applied exactly
once by Flutter's `TextScaler`. The framework:

- Sets type roles to declared (unscaled) sizes; never multiplies by the
  scaler manually.
- Keeps root-size scaling independent: changing the root re-scales
  spacing/layout, not text.
- Tests 1×, 1.5×, 2× and nonlinear scaling in the gallery stress rig
  (320px width + 2× text + RTL).

App rules:

- Don't fix heights on text containers — let text wrap; use `FwWrap`
  for action rows.
- Truncation (`maxLines`/`overflow`) needs an accessible expansion
  (tooltip, "show more", or navigation).
- Test your screens at 2× text: the gallery's text-scale slider is the
  fastest way.
