/// Curated foundation API for the responsive Flutter UI framework.
library;

export 'package:fw_components/fw_components.dart';
export 'package:fw_core/fw_core.dart';
export 'package:fw_layout/fw_layout.dart';
// P3: fw_layout's FwBox is the plan-blessed padding primitive (P2.2); the
// legacy style-based FwBox stays available via package:fw_utilities directly.
export 'package:fw_utilities/fw_utilities.dart' hide FwBox;
