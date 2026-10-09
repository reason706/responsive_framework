import 'dart:async';

import 'package:flutter/services.dart';

/// Debounce (+U02): collapses rapid calls into one.
///
/// [run] schedules [action] after [delay]; a new [run] before the delay
/// elapses cancels the pending one. [cancel] drops the pending action;
/// [dispose] cancels and releases the timer. For search-as-you-type, call
/// [run] on every keystroke and fire the query in [action].
class FwDebouncer {
  FwDebouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  /// Whether an action is currently pending.
  bool get isPending => _timer?.isActive ?? false;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}

/// Throttle (+U02): at most one call per [interval].
///
/// The first [run] fires immediately; calls inside [interval] are dropped
/// except the latest, which fires when the interval ends (trailing edge).
/// For scroll/resize handlers.
class FwThrottler {
  FwThrottler({this.interval = const Duration(milliseconds: 100)});

  final Duration interval;
  Timer? _timer;
  void Function()? _trailing;

  void run(void Function() action) {
    if (_timer == null) {
      action();
      _timer = Timer(interval, () {
        _timer = null;
        final trailing = _trailing;
        _trailing = null;
        trailing?.call();
      });
    } else {
      _trailing = action;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _trailing = null;
  }
}

/// Clipboard helper.
///
/// Thin, testable wrapper over [Clipboard]: [copy] writes plain text,
/// [paste] reads it back (null when empty or unavailable).
class FwClipboard {
  const FwClipboard._();

  static Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  static Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}

/// Common [TextInputFormatter]s (+U02).
class FwFormatters {
  const FwFormatters._();

  /// Strips everything except digits.
  static final digitsOnly = FilteringTextInputFormatter.digitsOnly;

  /// Forces uppercase while preserving the caret.
  static final upperCase = TextInputFormatter.withFunction(
    (oldValue, newValue) => newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    ),
  );

  /// Single-line: strips newlines.
  static final singleLine = FilteringTextInputFormatter.singleLineFormatter;
}
