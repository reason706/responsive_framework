# Supported SDK & platforms

| Item | Supported |
|---|---|
| Dart SDK | `>=3.9.0 <4.0.0` |
| Flutter | 3.35.x (pinned in CI; newer 3.x expected to work) |
| Android | API 21+ (validated via debug APK build; device runs need the Android SDK) |
| iOS | iOS 12+ (device validation needs Xcode; not run in this environment) |
| Web | Chromium baseline; release build via `flutter build web` |
| Desktop | Not a primary target; widgets are pointer-agnostic and should work |

The framework itself has **zero platform plugins** — everything is Dart.
Platform-specific behavior (haptics, clipboard) degrades gracefully:
`FwHaptics` no-ops when unavailable or when accessible navigation is on.

See [platform matrix](../quality/platform-matrix.md) for the validation
status of each target.
