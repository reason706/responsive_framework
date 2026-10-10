# Known issues

Tracked here until fixed; fixed items move to the [changelog](../../CHANGELOG.md).

1. **Font first-paint swap (web)** — text may render in a fallback font
   until bundled fonts load. Mitigate with preloading; the gallery
   bundles Roboto offline.
2. **`FwShow` retain-mode cost** — `FwVisibilityMode.retain` keeps hidden
   subtrees mounted; prefer `remove` for rarely-shown content.
3. **Golden renderer pinning** — goldens are validated against the CI
   renderer; local runs on different GPUs need human review.
4. **Native device validation pending** — Android/iOS device runs need
   SDKs not present in this environment (see
   [platform matrix](../quality/platform-matrix.md)).
