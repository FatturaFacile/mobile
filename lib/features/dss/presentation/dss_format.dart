import '../../../l10n/gen/app_localizations.dart';
import '../domain/dss_models.dart';

/// Number and label formatting of the Executive DSS page. Separators follow the Swiss conventions of the supported languages.
abstract final class DssFormat {
  static String _group(String languageCode) => switch (languageCode) {
    'fr' => ' ',
    'en' => ',',
    _ => '’',
  };

  /// Whole number with thousands separators.
  static String integer(num value, String languageCode) {
    final String digits = value.abs().round().toString();
    final StringBuffer out = StringBuffer(
      value < 0 && value.round() != 0 ? '-' : '',
    );
    final String group = _group(languageCode);
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        out.write(group);
      }
      out.write(digits[i]);
    }
    return out.toString();
  }

  static String decimal(num value, int places, [String languageCode = 'en']) {
    final String fixed = value.toStringAsFixed(places);
    return languageCode == 'fr' ? fixed.replaceFirst('.', ',') : fixed;
  }

  /// Money for a card: 1.2M, 345K, or the whole amount below one thousand.
  static String compactAmount(
    double value,
    String currency,
    String languageCode,
  ) {
    final double abs = value.abs();
    final String sign = value < 0 ? '-' : '';
    if (abs >= 1e6) {
      return '$sign$currency ${decimal(abs / 1e6, 2, languageCode)}M';
    }
    if (abs >= 1e3) {
      return '$sign$currency ${decimal(abs / 1e3, 1, languageCode)}K';
    }
    return '$sign$currency ${integer(abs, languageCode)}';
  }

  static String amount(double value, String currency, String languageCode) =>
      '$currency ${integer(value, languageCode)}';

  static String percent(double value, String languageCode, {int places = 1}) =>
      '${decimal(value, places, languageCode)}%';

  static String signedPercent(double value, String languageCode) =>
      '${value > 0 ? '+' : ''}${decimal(value, 1, languageCode)}%';

  /// The value of an indicator in its own unit.
  static String kpiValue(
    AppLocalizations l,
    DssKpi kpi,
    String currency,
    String languageCode,
  ) {
    final double? value = kpi.value;
    if (!kpi.available || value == null) {
      return '–';
    }
    return switch (kpi.unit) {
      'currency' => compactAmount(value, currency, languageCode),
      'percent' => percent(value, languageCode),
      'days' => l.dssDays(decimal(value, 0, languageCode)),
      _ => decimal(value, 2, languageCode),
    };
  }

  static String kpiLabel(AppLocalizations l, String key) => switch (key) {
    'revenue' => l.dssKpiRevenue,
    'gross_margin_pct' => l.dssKpiGrossMargin,
    'ebitda' => l.dssKpiEbitda,
    'net_cash_flow' => l.dssKpiNetCash,
    'ccc_days' => l.dssKpiCcc,
    'dso_days' => l.dssKpiDso,
    _ => key,
  };

  static String periodLabel(AppLocalizations l, String preset) =>
      switch (preset) {
        'MTD' => l.dssPeriodMtd,
        'QTD' => l.dssPeriodQtd,
        'YTD' => l.dssPeriodYtd,
        'L12M' => l.dssPeriodL12m,
        _ => preset,
      };

  static String severityLabel(AppLocalizations l, String severity) =>
      switch (severity) {
        'CRITICAL' => l.dssSeverityCritical,
        'WARNING' => l.dssSeverityWarning,
        _ => l.dssSeverityInfo,
      };

  static String alertTitle(AppLocalizations l, String code) => switch (code) {
    'margin_erosion' => l.dssAlertMarginErosion,
    'dso_spike' => l.dssAlertDsoSpike,
    'customer_concentration' => l.dssAlertCustomerConcentration,
    'budget_overrun' => l.dssAlertBudgetOverrun,
    'statistical_outlier' => l.dssAlertOutlier,
    _ => code,
  };

  static String alertSummary(
    AppLocalizations l,
    DssAlert alert,
    String languageCode,
  ) {
    final String value = decimal(alert.value, 1, languageCode);
    final String threshold = decimal(alert.threshold, 1, languageCode);
    return switch (alert.code) {
      'margin_erosion' => l.dssAlertSummaryMarginErosion(value, threshold),
      'dso_spike' => l.dssAlertSummaryDsoSpike(value, threshold),
      'customer_concentration' => l.dssAlertSummaryCustomerConcentration(
        alert.label ?? '',
        value,
        threshold,
      ),
      'budget_overrun' => l.dssAlertSummaryBudgetOverrun(value, threshold),
      'statistical_outlier' => l.dssAlertSummaryOutlier(value, threshold),
      _ => alertTitle(l, alert.code),
    };
  }

  static String? rootCause(AppLocalizations l, String code) => switch (code) {
    'margin_erosion' => l.dssCauseMarginErosion,
    'dso_spike' => l.dssCauseDsoSpike,
    'customer_concentration' => l.dssCauseCustomerConcentration,
    'budget_overrun' => l.dssCauseBudgetOverrun,
    'statistical_outlier' => l.dssCauseOutlier,
    _ => null,
  };

  static String? recommendedAction(AppLocalizations l, String code) =>
      switch (code) {
        'margin_erosion' => l.dssActionMarginErosion,
        'dso_spike' => l.dssActionDsoSpike,
        'customer_concentration' => l.dssActionCustomerConcentration,
        'budget_overrun' => l.dssActionBudgetOverrun,
        'statistical_outlier' => l.dssActionOutlier,
        _ => null,
      };

  static String time(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}
