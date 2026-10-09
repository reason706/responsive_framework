import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

import 'field.dart';
import 'text_input.dart';

/// A country for [FwPhoneField]: ISO code, display name, dial code, and an
/// (optional) flag glyph. Flag emoji may not render on all platforms; the
/// picker always shows the dial code and name as well.
@immutable
class FwCountry {
  const FwCountry({
    required this.code,
    required this.name,
    required this.dialCode,
    this.flag = '',
  });

  final String code;
  final String name;
  final String dialCode;
  final String flag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FwCountry && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Default country list for [FwPhoneField]. Override with your own set;
/// number parsing stays dependency-free (no libphonenumber).
const kFwDefaultCountries = <FwCountry>[
  FwCountry(code: 'AU', name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  FwCountry(code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  FwCountry(code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  FwCountry(code: 'CA', name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  FwCountry(code: 'NZ', name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  FwCountry(code: 'IE', name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
  FwCountry(code: 'DE', name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  FwCountry(code: 'FR', name: 'France', dialCode: '+33', flag: '🇫🇷'),
  FwCountry(code: 'NL', name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  FwCountry(code: 'SE', name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
  FwCountry(code: 'NO', name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
  FwCountry(code: 'DK', name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
  FwCountry(code: 'FI', name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
  FwCountry(code: 'ES', name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  FwCountry(code: 'IT', name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  FwCountry(code: 'CH', name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
  FwCountry(code: 'AT', name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  FwCountry(code: 'BE', name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
  FwCountry(code: 'PT', name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  FwCountry(code: 'JP', name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  FwCountry(code: 'KR', name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  FwCountry(code: 'CN', name: 'China', dialCode: '+86', flag: '🇨🇳'),
  FwCountry(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
  FwCountry(code: 'SG', name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  FwCountry(code: 'BR', name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  FwCountry(code: 'MX', name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  FwCountry(code: 'ZA', name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  FwCountry(code: 'AE', name: 'UAE', dialCode: '+971', flag: '🇦🇪'),
];

/// Parsed phone value: the selected country plus the national number as
/// typed (digits only). [e164] is the dial code + national number.
@immutable
class FwPhoneNumber {
  const FwPhoneNumber({required this.country, required this.nationalNumber});

  final FwCountry country;
  final String nationalNumber;

  String get e164 => '${country.dialCode}$nationalNumber';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwPhoneNumber &&
          country == other.country &&
          nationalNumber == other.nationalNumber;

  @override
  int get hashCode => Object.hash(country, nationalNumber);

  @override
  String toString() => 'FwPhoneNumber(${country.code}, $nationalNumber)';
}

/// Phone number field (+F23): country picker with dial code plus a national
/// number input.
///
/// Number handling is dependency-free: digits are kept as typed and
/// [FwPhoneNumber.e164] concatenates dial code + digits. Format the national
/// number for display in your app (a full masked input is app territory).
class FwPhoneField extends StatefulWidget {
  const FwPhoneField({
    super.key,
    required this.label,
    this.required = false,
    this.description,
    this.externalError,
    this.hintText,
    this.countries = kFwDefaultCountries,
    this.initialCountryCode = 'AU',
    this.initialNationalNumber,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
  });

  final String label;
  final bool required;
  final String? description;
  final String? externalError;
  final String? hintText;
  final List<FwCountry> countries;
  final String initialCountryCode;
  final String? initialNationalNumber;
  final TextEditingController? controller;
  final ValueChanged<FwPhoneNumber>? onChanged;
  final FormFieldValidator<FwPhoneNumber>? validator;
  final bool enabled;
  final bool autofocus;

  @override
  State<FwPhoneField> createState() => _FwPhoneFieldState();
}

class _FwPhoneFieldState extends State<FwPhoneField> {
  late FwCountry _country;
  TextEditingController? _internalController;
  TextEditingController get _controller =>
      widget.controller ?? _internalController!;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _country = widget.countries.firstWhere(
      (c) => c.code == widget.initialCountryCode,
      orElse: () => widget.countries.first,
    );
    if (widget.controller == null) {
      _internalController = TextEditingController(
        text: widget.initialNationalNumber ?? '',
      );
    }
    _controller.addListener(_notify);
  }

  @override
  void didUpdateWidget(FwPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController!.removeListener(_notify);
        _internalController!.dispose();
        _internalController = null;
      } else {
        oldWidget.controller!.removeListener(_notify);
      }
      _internalController ??= TextEditingController();
      _controller.addListener(_notify);
    }
  }

  FwPhoneNumber get _value =>
      FwPhoneNumber(country: _country, nationalNumber: _controller.text);

  void _notify() {
    setState(() {
      _localError = widget.validator?.call(_value);
    });
    widget.onChanged?.call(_value);
  }

  Future<void> _pickCountry() async {
    final picked = await showDialog<FwCountry>(
      context: context,
      builder: (context) => _CountryPickerDialog(countries: widget.countries),
    );
    if (picked != null && picked != _country) {
      setState(() => _country = picked);
      widget.onChanged?.call(_value);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_notify);
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FwField(
      label: widget.label,
      required: widget.required,
      description: widget.description,
      errorText: widget.externalError ?? _localError,
      enabled: widget.enabled,
      prefix: _CountryButton(
        country: _country,
        enabled: widget.enabled,
        onPressed: _pickCountry,
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _phoneDecoration(context, widget.hintText),
      ),
    );
  }

  InputDecoration _phoneDecoration(BuildContext context, String? hint) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final radius = BorderRadius.circular(theme.radii.of(FwRadius.md));
    return InputDecoration(
      hintText: hint,
      contentPadding: EdgeInsets.symmetric(
        horizontal: theme.spaceScale.resolveAlias(
          FwSpaceAlias.controlInline,
          context,
        ),
        vertical: theme.spaceScale.resolveAlias(
          FwSpaceAlias.controlBlock,
          context,
        ),
      ),
      filled: true,
      fillColor: colors.of(FwColorRole.surfaceContainerHighest),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: colors.of(FwColorRole.focusRing),
          width: 2,
        ),
      ),
      isDense: true,
    );
  }
}

/// Country picker trigger: flag + dial code.
class _CountryButton extends StatelessWidget {
  const _CountryButton({
    required this.country,
    required this.enabled,
    required this.onPressed,
  });

  final FwCountry country;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spaceScale.of(FwSpace.s2, context),
        ),
        minimumSize: const Size(48, 48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (country.flag.isNotEmpty) Text(country.flag),
          if (country.flag.isNotEmpty) const SizedBox(width: 4),
          Text(
            country.dialCode,
            style: theme.typeScale.resolve(FwTextRole.body, context),
          ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }
}

/// Searchable country list dialog.
class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({required this.countries});

  final List<FwCountry> countries;

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = widget.countries
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.dialCode.contains(q) ||
              c.code.toLowerCase().contains(q),
        )
        .toList();
    return AlertDialog(
      title: const Text('Select country'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FwTextField(
              label: 'Search',
              hintText: 'Name or dial code',
              prefixIcon: const Icon(Icons.search, size: 20),
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  return ListTile(
                    leading: c.flag.isNotEmpty ? Text(c.flag) : null,
                    title: Text(c.name),
                    trailing: Text(c.dialCode),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
