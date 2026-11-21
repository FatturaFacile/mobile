import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

/// Shared localized formatting and label helpers for Mod 061.
abstract final class MfgLabels {
  /// Locale-aware number with up to 2 decimals.
  static String number(BuildContext context, double value) {
    final String locale = Localizations.localeOf(context).languageCode;
    return NumberFormat('#,##0.##', locale).format(value);
  }

  static String telemetry(AppLocalizations l10n, String? status) {
    return switch (status) {
      'online' => l10n.mfgTelemetryOnline,
      'stale' => l10n.mfgTelemetryStale,
      _ => l10n.mfgTelemetryNever,
    };
  }

  /// Label of a six-big-losses category key.
  static String loss(AppLocalizations l10n, String key) {
    return switch (key) {
      'equipment_failure' => l10n.mfgLossEquipmentFailure,
      'setup_adjustment' => l10n.mfgLossSetupAdjustment,
      'minor_stops' => l10n.mfgLossMinorStops,
      'reduced_speed' => l10n.mfgLossReducedSpeed,
      'process_defects' => l10n.mfgLossProcessDefects,
      'startup_rejects' => l10n.mfgLossStartupRejects,
      _ => '',
    };
  }
}
