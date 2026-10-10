# Localization

- All user-visible strings are caller-supplied: the framework ships no
  English fallback text in widgets (labels, hints, errors come from you).
- Relative timestamps (`FwNotificationCenter`) and date/time pickers
  format via the app's locale — pass locale-aware formatters.
- `FwPhoneField` dial-code labels localize through the country names
  your app provides.
- RTL: fields, labels, and validation icons follow `Directionality`
  automatically; logical start/end slots flip. Test every form in the
  gallery's RTL mode.

Never hard-code locale assumptions (date order, name order, phone
formats) in shared widgets — those belong to the app.
