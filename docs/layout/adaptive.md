# Adaptive panes

`L09` adaptive scaffold and `L10` master-detail implement the
phone → tablet → desktop continuum:

- Bottom navigation on compact, rail on medium, sidebar/drawer on
  expanded — driven by one shared selection model (`FwDestination`
  ids). Never duplicate selection state per form factor.
- Master-detail: list + detail side-by-side on wide screens, pushed
  routes on narrow; detail selection survives transitions.

See the [dashboard recipe](../recipes.md#dashboard) for the canonical
example, and [navigation components](../components/families.md#navigation).
