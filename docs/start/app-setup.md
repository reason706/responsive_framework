# Application setup

Wrap your app with an `FwTheme` and (optionally) a toast host. Sizes resolve
against the root you choose; accessibility text scaling stays independent.

```dart
import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: FwTheme.ocean().toThemeData(),
      darkTheme: FwTheme.ocean(brightness: Brightness.dark).toThemeData(),
      builder: (context, child) => FwToastHost(child: child!),
      home: const HomePage(),
    );
  }
}
```

## Choosing a preset

`FwTheme.presets` lists every tested preset: Light, Dark, Light/Dark high
contrast, Compact, Comfortable, Ocean, Forest, Sunset, Monochrome (each in
light and dark). Pick one per brightness, or build from a seed:

```dart
FwTheme.fromSeed(seed: const Color(0xFF6750A4), brightness: Brightness.light)
```

All presets share identical token keys (verified by test) — switching
presets never changes layout, only values. See [brand presets](../theming/presets.md).

## Root size

```dart
FwTheme.light(metrics: FwMetrics(rootSize: 18)).toThemeData()
```

Root-relative lengths (`FwSpace`, `FwLength`) scale with this root.
Text set through `FwText` roles scales with the OS text scaler, applied
exactly once — changing the root does not double-scale text.
See [units](../design-system/units.md).
