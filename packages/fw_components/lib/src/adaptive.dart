/// Platform-adaptive (Cupertino) variants of core components.
///
/// This file is the down-payment on the demand plan's "every component should
/// ship an iOS-styled variant": it establishes the adaptive pattern —
/// [FwPlatformOverride] for deterministic platform selection plus
/// `FwAdaptive*` widgets that render Cupertino on iOS and the framework's
/// Material components elsewhere — and applies it to the six highest-demand
/// components. Full per-component iOS coverage is 2.x; see
/// `docs/roadmap.md` (adaptive section) for the roadmap.
///
/// Shared API rule: adaptive widgets take the same constructor parameters as
/// their framework counterparts where the underlying platforms agree.
/// Deliberate divergences are documented on each widget.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';
import 'calendar.dart';
import 'dialog.dart';
import 'feedback.dart';
import 'selection.dart';
import 'slider.dart';

/// Which platform the adaptive components render as.
enum FwPlatform {
  /// Apple iOS styling (Cupertino widgets).
  iOS,

  /// Android / Material styling (framework widgets).
  android,

  /// Follow the ambient [ThemeData.platform].
  system,
}

/// Overrides the platform adaptive components resolve to.
///
/// Wrap a subtree — or a widget test — to force iOS or Material rendering
/// regardless of the real device. When no override is present,
/// [FwPlatform.system] applies and the ambient [ThemeData.platform] wins.
class FwPlatformOverride extends InheritedWidget {
  /// Creates an override for [child]'s subtree.
  const FwPlatformOverride({
    super.key,
    required this.platform,
    required super.child,
  });

  /// The forced platform for this subtree.
  final FwPlatform platform;

  /// Returns the override for [context], or [FwPlatform.system] when none
  /// is present.
  static FwPlatform of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<FwPlatformOverride>()
            ?.platform ??
        FwPlatform.system;
  }

  /// Resolves the override to a concrete [TargetPlatform].
  static TargetPlatform resolve(BuildContext context) {
    switch (of(context)) {
      case FwPlatform.iOS:
        return TargetPlatform.iOS;
      case FwPlatform.android:
        return TargetPlatform.android;
      case FwPlatform.system:
        return Theme.of(context).platform;
    }
  }

  /// Whether adaptive components under [context] render the iOS (Cupertino)
  /// variant. Only [TargetPlatform.iOS] counts — macOS renders Material.
  static bool isIOS(BuildContext context) =>
      resolve(context) == TargetPlatform.iOS;

  @override
  bool updateShouldNotify(FwPlatformOverride oldWidget) =>
      platform != oldWidget.platform;
}

/// Platform-adaptive button.
///
/// iOS renders a [CupertinoButton] ([CupertinoButton.filled] when [filled],
/// plain otherwise); other platforms render an [FwButton] (solid vs ghost).
///
/// Divergences: [FwButton]'s intent/size/shape/loading matrix is not
/// surfaced — this is the simple label/icon case. There is no icon-only
/// mode; use [FwIconButton] or [CupertinoButton] directly for that.
class FwAdaptiveButton extends StatelessWidget {
  /// Creates an adaptive button.
  const FwAdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.filled = true,
  });

  /// Button label, always visible.
  final String label;

  /// Null disables the button on both platforms.
  final VoidCallback? onPressed;

  /// Optional leading icon (start position).
  final IconData? icon;

  /// Accessible name override; defaults to [label].
  final String? semanticLabel;

  /// iOS: filled vs plain button. Material: solid vs ghost variant.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (FwPlatformOverride.isIOS(context)) {
      final Widget child = icon == null
          ? Text(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(label),
              ],
            );
      final button = filled
          ? CupertinoButton.filled(onPressed: onPressed, child: child)
          : CupertinoButton(onPressed: onPressed, child: child);
      return Semantics(
        button: true,
        label: semanticLabel ?? label,
        enabled: onPressed != null,
        child: button,
      );
    }
    return FwButton(
      label: label,
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon, size: 18),
      variant: filled ? FwButtonVariant.solid : FwButtonVariant.ghost,
      semanticLabel: semanticLabel,
    );
  }
}

/// Platform-adaptive switch.
///
/// iOS renders a [CupertinoSwitch] beside the label/description column;
/// other platforms render an [FwSwitch].
///
/// Divergences: [FwSwitch]'s `busy`/`focusNode`/`autofocus` are not
/// surfaced. iOS uses the default Cupertino switch tint.
class FwAdaptiveSwitch extends StatelessWidget {
  /// Creates an adaptive switch.
  const FwAdaptiveSwitch({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// Accessible name.
  final String label;

  /// Optional secondary text under the label.
  final String? description;

  /// Current state.
  final bool value;

  /// Called with the toggled value; null (or [enabled] false) disables.
  final ValueChanged<bool>? onChanged;

  /// Whether the switch is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (FwPlatformOverride.isIOS(context)) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (description != null) Text(description!),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: enabled ? onChanged : null),
        ],
      );
    }
    return FwSwitch(
      label: label,
      description: description,
      value: value,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}

/// Platform-adaptive activity indicator.
///
/// iOS renders a [CupertinoActivityIndicator]; other platforms render an
/// [FwCircularProgress].
///
/// Divergence: [CupertinoActivityIndicator] is indeterminate-only, so
/// [value] is ignored on iOS.
class FwAdaptiveIndicator extends StatelessWidget {
  /// Creates an adaptive indicator.
  const FwAdaptiveIndicator({
    super.key,
    this.value,
    this.size = 36,
    this.semanticLabel,
  }) : assert(
         value == null || (value >= 0.0 && value <= 1.0),
         'value must be null or within 0..1',
       );

  /// 0..1 determinate progress, or null for indeterminate.
  /// Ignored on iOS (always indeterminate).
  final double? value;

  /// Diameter in logical pixels.
  final double size;

  /// Accessible label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (FwPlatformOverride.isIOS(context)) {
      return Semantics(
        label: semanticLabel,
        child: CupertinoActivityIndicator(radius: size / 2),
      );
    }
    return FwCircularProgress(
      value: value,
      size: size,
      semanticLabel: semanticLabel,
    );
  }
}

/// Platform-adaptive slider.
///
/// iOS renders a [CupertinoSlider] under a label; other platforms render an
/// [FwSlider].
///
/// Divergences: [CupertinoSlider] has no label, value bubble, ticks, marks,
/// or error text — the adaptive slider renders the label above the track on
/// iOS to keep the accessible name, and drops the rest. For the full
/// feature set use [FwSlider] directly.
class FwAdaptiveSlider extends StatelessWidget {
  /// Creates an adaptive slider.
  const FwAdaptiveSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.enabled = true,
  }) : assert(min < max, 'min must be less than max'),
       assert(divisions == null || divisions > 0, 'divisions must be positive'),
       assert(value >= min && value <= max, 'value must be within min..max');

  /// Accessible name, rendered above the track on iOS.
  final String label;

  /// Current value within [min]..[max].
  final double value;

  /// Called with the new value; null (or [enabled] false) disables.
  final ValueChanged<double>? onChanged;

  /// Domain bounds.
  final double min;

  /// Domain bounds.
  final double max;

  /// Discrete steps; null is continuous.
  final int? divisions;

  /// Whether the slider is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (FwPlatformOverride.isIOS(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          CupertinoSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      );
    }
    return FwSlider(
      label: label,
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      enabled: enabled,
    );
  }
}

/// Platform-adaptive date picker (inline).
///
/// iOS renders a [CupertinoDatePicker] in date mode (spinner wheels);
/// other platforms render an [FwCalendar] month grid.
///
/// Divergences: date-only on both platforms (no time mode). iOS wheels need
/// a bounded height (216, the Cupertino convention) and always show a date
/// (defaults to today when [selectedDate] is null); Material can show
/// nothing selected. [onDateSelected] always receives the day with the time
/// components zeroed.
class FwAdaptiveDatePicker extends StatelessWidget {
  /// Creates an adaptive date picker.
  const FwAdaptiveDatePicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.minDate,
    this.maxDate,
  });

  /// Currently selected day. Null selects nothing on Material; iOS wheels
  /// fall back to today.
  final DateTime? selectedDate;

  /// Fires with the selected day (time zeroed).
  final ValueChanged<DateTime> onDateSelected;

  /// Inclusive bounds for selectable days.
  final DateTime? minDate;

  /// Inclusive bounds for selectable days.
  final DateTime? maxDate;

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    if (FwPlatformOverride.isIOS(context)) {
      return SizedBox(
        height: 216,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: selectedDate ?? DateTime.now(),
          minimumDate: minDate,
          maximumDate: maxDate,
          onDateTimeChanged: (date) => onDateSelected(_day(date)),
        ),
      );
    }
    return FwCalendar(
      selectedDate: selectedDate == null ? null : _day(selectedDate!),
      onDateSelected: (date) => onDateSelected(_day(date)),
      minDate: minDate,
      maxDate: maxDate,
    );
  }
}

/// One action in an adaptive dialog or action sheet.
///
/// Tapping the action dismisses the dialog and completes the [Future]
/// with [value].
class FwAdaptiveDialogAction<T> {
  /// Creates a dialog action.
  const FwAdaptiveDialogAction({
    required this.label,
    this.value,
    this.isDestructive = false,
    this.isDefault = false,
  });

  /// Action label.
  final String label;

  /// Value the dialog's future completes with when tapped.
  final T? value;

  /// iOS: red action text. Material: danger intent.
  final bool isDestructive;

  /// iOS: bold action text. Material: solid primary treatment.
  final bool isDefault;
}

/// Platform-adaptive dialogs.
///
/// Alert dialogs render [CupertinoAlertDialog] on iOS and [FwDialog]
/// elsewhere; action sheets render [CupertinoActionSheet] on iOS.
///
/// The futures complete with the tapped action's value, or null when
/// dismissed without choosing.
///
/// Divergences: the framework's [FwDismissReason] taxonomy is not surfaced
/// (only the value comes back). On Material, action sheets render as
/// dialogs rather than bottom sheets — a bottom-sheet rendering is on the
/// 2.x roadmap.
class FwAdaptiveDialog {
  const FwAdaptiveDialog._();

  /// Shows an alert dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<FwAdaptiveDialogAction<T>> actions = const [],
    bool barrierDismissible = true,
  }) {
    if (FwPlatformOverride.isIOS(context)) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: title == null ? null : Text(title),
          content: content,
          actions: [
            for (final action in actions)
              CupertinoDialogAction(
                isDestructiveAction: action.isDestructive,
                isDefaultAction: action.isDefault,
                onPressed: () => Navigator.of(dialogContext).pop(action.value),
                child: Text(action.label),
              ),
          ],
        ),
      );
    }
    return FwDialog.show<T>(
      context: context,
      title: title == null ? null : Text(title),
      content: content,
      barrierDismissible: barrierDismissible,
      actions: [
        // Builder: FwDialog.close must run inside the dialog route (it
        // looks up the route's _ReasonScope), so the action buttons need
        // the dialog's BuildContext, not the caller's.
        for (final action in actions)
          Builder(
            builder: (actionContext) => FwButton(
              label: action.label,
              variant: action.isDefault
                  ? FwButtonVariant.solid
                  : FwButtonVariant.ghost,
              intent: action.isDestructive ? FwIntent.danger : FwIntent.primary,
              onPressed: () => FwDialog.close(actionContext, action.value),
            ),
          ),
      ],
    ).then((result) => result.value);
  }

  /// Shows an action sheet (iOS) / dialog (Material).
  ///
  /// [cancelLabel] renders the iOS cancel button; on Material it is ignored
  /// (the dialog's barrier/back handling dismisses instead).
  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<FwAdaptiveDialogAction<T>> actions,
    String? cancelLabel,
  }) {
    if (FwPlatformOverride.isIOS(context)) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: title == null ? null : Text(title),
          message: message == null ? null : Text(message),
          actions: [
            for (final action in actions)
              CupertinoActionSheetAction(
                isDestructiveAction: action.isDestructive,
                isDefaultAction: action.isDefault,
                onPressed: () => Navigator.of(sheetContext).pop(action.value),
                child: Text(action.label),
              ),
          ],
          cancelButton: cancelLabel == null
              ? null
              : CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(cancelLabel),
                ),
        ),
      );
    }
    // Divergence: Material renders the sheet as a dialog; a bottom-sheet
    // rendering is on the 2.x roadmap.
    return show<T>(
      context: context,
      title: title,
      content: message == null ? const SizedBox.shrink() : Text(message),
      actions: actions,
    );
  }
}
