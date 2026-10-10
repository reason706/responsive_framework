# First responsive page

A page that adapts from phone to desktop using only public API.

```dart
import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hello')),
      body: FwResponsiveBuilder(
        builder: (context, width, breakpoint) {
          final wide = width >= 720;
          return Padding(
            padding: FwInsets.token(FwSpace.s4).resolve(context),
            child: FwVStack(
              gap: FwSpace.s4,
              children: [
              FwText('Welcome', role: FwTextRole.h1),
              if (wide)
                FwHStack(
                  gap: FwSpace.s3,
                  children: const [
                    Expanded(child: FwCard(child: Text('One'))),
                    Expanded(child: FwCard(child: Text('Two'))),
                  ],
                )
              else
                const FwCard(child: Text('One')),
              FwButton(
                label: 'Continue',
                onPressed: () {},
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

What this demonstrates:

- `FwVStack`/`FwHStack` gaps and `FwInsets` padding resolve against the
  root, so the whole page re-scales when the root changes.
- `FwResponsiveBuilder` exposes the viewport; the layout switches at 720px.
- `FwText` with a role keeps text on the type scale and honors the OS text
  scaler exactly once.
- `FwButton` separates visual variant from semantic intent
  (`FwButton.intent(FwIntent.primary, ...)` style APIs).

Next: [Layout](../layout/containers.md) · [Components](../components/overview.md).
