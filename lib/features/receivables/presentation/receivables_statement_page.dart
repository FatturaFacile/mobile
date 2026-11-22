import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../domain/receivables_models.dart';
import 'receivables_controller.dart';
import 'receivables_strings.dart';
import 'receivables_widgets.dart';

/// Customer statement for a period: opening and closing balance, the movements and the open items totals, readable
/// offline, with PDF and XLSX export through the share sheet.
class CustomerStatementPage extends ConsumerStatefulWidget {
  const CustomerStatementPage({
    required this.customerId,
    this.customerName = '',
    super.key,
  });

  final String customerId;
  final String customerName;

  @override
  ConsumerState<CustomerStatementPage> createState() =>
      _CustomerStatementPageState();
}

class _CustomerStatementPageState extends ConsumerState<CustomerStatementPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(statementProvider.notifier).load(widget.customerId),
    );
  }

  String? _exportText(ReceivablesStrings s, ExportResult? result) =>
      switch (result) {
        ExportResult.shared => s.t(RC.exportShared),
        ExportResult.offline => s.t(RC.exportOffline),
        ExportResult.failed => s.t(RC.exportFailed),
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final StatementState st = ref.watch(statementProvider);
    final StatementController ctrl = ref.read(statementProvider.notifier);
    ref.listen<StatementState>(statementProvider, (
      StatementState? prev,
      StatementState next,
    ) {
      final String? text = _exportText(s, next.export);
      if (text != null && next.export != prev?.export) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
        ctrl.clearExport();
      }
    });
    final CustomerStatement? stmt = st.statement;
    final String currency = stmt?.currency ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customerName.isEmpty
              ? s.t(RC.statement)
              : '${s.t(RC.statement)} · ${widget.customerName}',
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('export-pdf'),
            tooltip: s.t(RC.exportPdf),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: st.exporting
                ? null
                : () => ctrl.export(StatementFormat.pdf),
          ),
          IconButton(
            key: const Key('export-xlsx'),
            tooltip: s.t(RC.exportXlsx),
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: st.exporting
                ? null
                : () => ctrl.export(StatementFormat.xlsx),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space3),
        children: <Widget>[
          if (st.loading || st.exporting) const LinearProgressIndicator(),
          if (st.fromCache && !st.loading && stmt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: FfSpace.space2),
              child: Text(
                s.t(RC.offlineCopy),
                key: const Key('statement-offline'),
              ),
            ),
          if (st.error != null &&
              st.error!.kind != ReceivablesErrorKind.offline &&
              !st.loading)
            Padding(
              padding: const EdgeInsets.only(bottom: FfSpace.space2),
              child: Text(
                s.error(st.error!),
                key: const Key('statement-error'),
              ),
            ),
          if (stmt != null) ...<Widget>[
            Text(
              s.f(RC.statementPeriod, <String, Object>{
                'from': s.date(stmt.from ?? st.from),
                'to': s.date(stmt.to ?? st.to),
              }),
              key: const Key('statement-period'),
            ),
            const SizedBox(height: FfSpace.space2),
            LabeledAmount(
              key: const Key('statement-opening'),
              label: s.t(RC.openingBalance),
              value: s.money(stmt.openingBalance, currency),
            ),
            LabeledAmount(
              key: const Key('statement-closing'),
              label: s.t(RC.closingBalance),
              value: s.money(stmt.closingBalance, currency),
              emphasis: true,
            ),
            LabeledAmount(
              label: s.t(RC.totalOpen),
              value: s.money(stmt.totalOpen, currency),
            ),
            LabeledAmount(
              label: s.t(RC.totalOverdue),
              value: s.money(stmt.totalOverdue, currency),
            ),
            const SizedBox(height: FfSpace.space3),
            Text(
              s.t(RC.movements),
              style: const TextStyle(
                fontSize: FfFont.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (stmt.movements.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: FfSpace.space2),
                child: Text(
                  s.t(RC.noMovements),
                  key: const Key('statement-empty'),
                ),
              ),
            for (int i = 0; i < stmt.movements.length; i++)
              _MovementRow(
                key: Key('movement-$i'),
                movement: stmt.movements[i],
                currency: currency,
              ),
          ],
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.movement,
    required this.currency,
    super.key,
  });

  final LedgerMovement movement;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ReceivablesStrings s = ReceivablesStrings.of(context);
    final FfColors c = receivablesColors(context);
    final bool isDebit = movement.debit.isPositive;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        <String>[
          s.date(movement.date),
          movement.reference,
        ].where((String t) => t.isNotEmpty).join(' · '),
      ),
      subtitle: Text(
        '${s.t(RC.balance)} ${s.money(movement.balance, currency)}',
      ),
      trailing: Text(
        isDebit
            ? s.money(movement.debit, currency)
            : s.money(-movement.credit, currency),
        style: TextStyle(
          color: isDebit ? c.text : c.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
