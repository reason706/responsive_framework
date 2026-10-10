# Async suggestions

`FwCombobox` and search fields fetch suggestions asynchronously:

```dart
FwCombobox<String>(
  label: 'City',
  onSelected: (v) {},
  suggestionsBuilder: (query) async {
    final seq = ++_seq;
    final results = await api.search(query);
    if (seq != _seq) return const []; // stale guard
    return results;
  },
  debounce: const Duration(milliseconds: 250),
)
```

Rules:

- Debouncing is built in (`debounce` param, default 200ms) — never fire a
  request per keystroke.
- Guard against stale results with sequence ids: a slow earlier response
  must not overwrite a newer one.
- Show loading, empty ("No matches"), and error states in the suggestion
  list — never a blank popover.
- Keyboard: arrow keys move through suggestions, Enter selects, Escape
  dismisses without selecting.
