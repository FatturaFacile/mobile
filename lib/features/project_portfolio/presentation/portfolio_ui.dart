import 'package:material_ui/material_ui.dart';

import '../domain/project_portfolio_repository.dart';
import '../l10n/project_portfolio_strings.dart';
import 'project_portfolio_labels.dart';

/// Runs a local write and shows the reason in a snack bar when the repository refuses it. True when it went through.
Future<bool> guarded(
  BuildContext context,
  ProjectPortfolioStrings strings,
  Future<void> Function() action,
) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    return true;
  } on PortfolioException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(strings.error(e.kind))));
    return false;
  }
}

/// Parses a decimal typed by the user, accepting a comma as separator; null when it is not a number.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// Small label/value pair used by the summary cards.
class Metric extends StatelessWidget {
  const Metric({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: text.labelSmall),
        Text(value, style: text.titleSmall),
      ],
    );
  }
}
