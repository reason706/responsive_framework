# Platform matrix

| Target | Status | Notes |
|---|---|---|
| Web (Chromium) | ✅ Validated | Release build in CI (`flutter build web`) |
| Android | ⚠️ Partial | Debug APK builds; device runs need the Android SDK (not installed here) |
| iOS | ⚠️ Partial | Needs Xcode; not run in this environment |
| Desktop | — | Not a primary target; widgets are pointer-agnostic |

The framework is pure Dart with zero plugins, so platform risk is low —
the remaining work is device-level validation (keyboard behavior,
TalkBack/VoiceOver, haptics) on real runners.

Native gallery targets are separate implementation changes per the
delivery plan; the current gallery is web-focused.
