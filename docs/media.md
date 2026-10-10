# Media

## Image providers

`FwImage` accepts any Flutter `ImageProvider` — network, asset, file,
memory. The widget is provider-agnostic; policy lives in the app:

- **Decode/cache policy**: configure `ImageCache` limits in your app;
  precache hero images with `precacheImage`.
- **CORS**: network images on web need CORS-enabled sources or a proxy —
  the widget surfaces load errors; the app decides the fallback.
- **Offline/error**: `errorBuilder` slot shows branded fallback art;
  never leave a broken-image icon in production.

## Responsive images & aspect reservation

`FwImage` reserves aspect ratio before the image loads (no layout shift):

```dart
FwImage(
  provider: NetworkImage(url),
  aspectRatio: 16 / 9,
  placeholder: const FwSkeleton(),
)
```

Serve appropriately sized variants per breakpoint where bandwidth
matters; the widget picks the provider you give it.

## Avatars

`FwAvatar` falls back gracefully: image → initials → generic glyph.
`FwAvatarGroup` stacks with overlap and an overflow count.

## Photo viewer & carousel

`FwPhotoViewer` adds pinch-zoom with accessible double-tap zoom;
`FwCarousel` exposes page indicators and keyboard navigation.

## Font licensing

Only ship fonts you are licensed to distribute. The gallery bundles
Roboto (Regular/Medium/Bold) with its `LICENSE.txt` as the offline
default — replace with your licensed fonts per [custom fonts](theming/fonts.md).
