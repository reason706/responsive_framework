import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR code display (+M13).
///
/// Display-only: renders [data] as a scannable QR code. There is no
/// scanning, no camera, no interactivity — for capture flows, pair this
/// with a platform scanner plugin.
///
/// Colors come from the theme ([FwColorRole.text] on
/// [FwColorRole.surface]); [foregroundColor]/[backgroundColor] accept
/// roles, never raw colors. The quiet zone ([padding]) defaults to four
/// modules per the QR spec — keep it, scanners need it.
///
/// Semantics expose [semanticLabel] (or [data]) as an image.
class FwQrDisplay extends StatelessWidget {
  const FwQrDisplay({
    super.key,
    required this.data,
    this.size = 160,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
    this.foregroundRole = FwColorRole.text,
    this.backgroundRole = FwColorRole.surface,
    this.padding = 16,
    this.semanticLabel,
  }) : assert(data.length > 0, 'data must not be empty');

  /// The payload to encode (URL, text, vCard…).
  final String data;

  /// Widget size (square).
  final double size;

  /// Error-correction level. Higher survives more damage but holds less.
  final int errorCorrectionLevel;

  /// Theme roles for the modules and the background.
  final FwColorRole foregroundRole;
  final FwColorRole backgroundRole;

  /// Quiet zone around the code. The spec wants ≥ 4 modules; 16px at the
  /// default size satisfies that for typical payloads.
  final double padding;

  /// Accessible label. Defaults to announcing the raw [data].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.fwTheme.colors;
    return Semantics(
      image: true,
      label: semanticLabel ?? 'QR code: $data',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: colors.of(backgroundRole),
          borderRadius: BorderRadius.circular(
            context.fwTheme.radii.of(FwRadius.sm),
          ),
          border: Border.all(color: colors.of(FwColorRole.border)),
        ),
        child: ExcludeSemantics(
          child: QrImageView(
            data: data,
            errorCorrectionLevel: errorCorrectionLevel,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: colors.of(foregroundRole),
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: colors.of(foregroundRole),
            ),
          ),
        ),
      ),
    );
  }
}
