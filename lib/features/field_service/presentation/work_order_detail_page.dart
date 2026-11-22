import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../data/field_service_repository.dart';
import '../device/field_service_device_services.dart';
import '../domain/coverage_policy.dart';
import '../domain/scan_codes.dart';
import '../l10n/field_service_strings.dart';
import '../models/field_service_models.dart';
import 'part_picker.dart';
import 'service_report_page.dart';

/// One work order on the phone: journey status (queued offline), navigation to the site, asset scan, history, coverage,
/// checklist, van parts and the entry to the signed service report. Reads only from the local store.
class WorkOrderDetailPage extends StatefulWidget {
  const WorkOrderDetailPage({
    super.key,
    required this.repository,
    required this.workOrderId,
    this.device = const FieldServiceDeviceHooks(),
  });

  final FieldServiceRepository repository;
  final String workOrderId;
  final FieldServiceDeviceHooks device;

  @override
  State<WorkOrderDetailPage> createState() => _WorkOrderDetailPageState();
}

class _WorkOrderDetailPageState extends State<WorkOrderDetailPage> {
  String? _message;
  bool _messageIsError = false;
  late final Stream<FsmWorkOrderDetail?> _detail = widget.repository
      .watchDetail(widget.workOrderId);

  void _say(String text, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _messageIsError = error;
    });
  }

  Future<void> _advance(FsmStatus target) async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    try {
      await widget.repository.advanceStatus(widget.workOrderId, target);
      _say(s.t(FsmText.statusQueued));
    } on FsmException catch (e) {
      _say(s.error(e.errors.keys.first, e.errors.values.first), error: true);
    }
  }

  Future<void> _navigate(FsmWorkOrderDetail detail) async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final bool opened = await widget.device.openNavigation!(
      detail.site,
      detail.workOrder.title,
    );
    if (!opened) _say(s.t(FsmText.navigationUnavailable), error: true);
  }

  Future<void> _scanAsset(FsmEquipment equipment) async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final String? code = await widget.device.scanCode!(context);
    if (!mounted || code == null) return;
    if (AssetScan.matches(code, equipment)) {
      _say(
        fill(s.t(FsmText.assetMatches), <String, Object>{
          'serial': equipment.serialNumber,
        }),
      );
    } else {
      _say(
        fill(s.t(FsmText.assetMismatch), <String, Object>{
          'scanned': AssetScan.serialOf(code),
          'serial': equipment.serialNumber,
        }),
        error: true,
      );
    }
  }

  Future<void> _addPart(FsmWorkOrder workOrder) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => PartPicker(
        repository: widget.repository,
        workOrder: workOrder,
        device: widget.device,
      ),
    );
  }

  Future<void> _removePart(FsmPartLine line) async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    try {
      await widget.repository.removePart(widget.workOrderId, line.clientUuid);
    } on FsmException catch (e) {
      _say(s.error(e.errors.keys.first, e.errors.values.first), error: true);
    }
  }

  Future<void> _openReport() => Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => ServiceReportPage(
        repository: widget.repository,
        workOrderId: widget.workOrderId,
        device: widget.device,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    return StreamBuilder<FsmWorkOrderDetail?>(
      stream: _detail,
      builder: (BuildContext context, AsyncSnapshot<FsmWorkOrderDetail?> snap) {
        final FsmWorkOrderDetail? detail = snap.data;
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(title: Text(s.t(FsmText.workQueueTitle))),
            body: snap.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          );
        }
        final FsmWorkOrder wo = detail.workOrder;
        final FsmStatus? next = wo.status.nextStep;
        return Scaffold(
          appBar: AppBar(title: Text(wo.number)),
          body: ListView(
            padding: const EdgeInsets.all(FfSpace.space4),
            children: <Widget>[
              Text(wo.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: FfSpace.space2),
              Wrap(
                spacing: FfSpace.space2,
                children: <Widget>[
                  Chip(
                    key: const Key('fsm-status'),
                    label: Text(s.status(wo.status)),
                  ),
                  Chip(label: Text(s.workType(wo.workType))),
                  if (detail.pendingOperations > 0)
                    Chip(
                      key: const Key('fsm-waiting-sync'),
                      avatar: const Icon(Icons.sync, size: 16),
                      label: Text(s.t(FsmText.waitingSync)),
                    ),
                ],
              ),
              if (wo.scheduledStart != null)
                _Line(
                  label: s.t(FsmText.scheduled),
                  value: _when(wo.scheduledStart!),
                ),
              if (detail.customer != null)
                _Line(
                  label: s.t(FsmText.customer),
                  value: <String>[
                    detail.customer!.name,
                    if ((detail.customer!.phone ?? '').isNotEmpty)
                      detail.customer!.phone!,
                  ].join(' · '),
                ),
              if ((wo.problemDescription ?? '').isNotEmpty)
                _Line(
                  label: s.t(FsmText.problem),
                  value: wo.problemDescription!,
                ),
              _siteSection(s, detail),
              _equipmentSection(s, detail),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: FfSpace.space2),
                  child: Text(
                    _message!,
                    key: const Key('fsm-message'),
                    style: TextStyle(
                      color: _messageIsError
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              if (next != null && !detail.signed)
                FilledButton(
                  key: const Key('fsm-next-step'),
                  onPressed: () => _advance(next),
                  child: Text(
                    s.t(
                      next == FsmStatus.enRoute
                          ? FsmText.startTravel
                          : FsmText.arriveOnSite,
                    ),
                  ),
                ),
              const SizedBox(height: FfSpace.space4),
              _coverageSection(s, detail.coverage),
              const SizedBox(height: FfSpace.space4),
              _checklistSection(s, detail),
              const SizedBox(height: FfSpace.space4),
              _partsSection(s, detail),
              const SizedBox(height: FfSpace.space4),
              _historySection(s, detail),
              const SizedBox(height: FfSpace.space5),
              if (detail.signed)
                _signedSection(s, detail.report!)
              else
                FilledButton.icon(
                  key: const Key('fsm-open-report'),
                  icon: const Icon(Icons.draw),
                  onPressed: wo.status.isOpen ? _openReport : null,
                  label: Text(s.t(FsmText.openReport)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _siteSection(FieldServiceStrings s, FsmWorkOrderDetail detail) {
    final FsmSite site = detail.site;
    final String where = <String>[
      if (site.address != null) site.address!,
      if (site.hasCoordinates)
        '${site.latitude!.toStringAsFixed(5)}, ${site.longitude!.toStringAsFixed(5)}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Line(
          label: s.t(FsmText.site),
          value: site.isEmpty ? s.t(FsmText.noSite) : where,
        ),
        if (widget.device.openNavigation != null && !site.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('fsm-navigate'),
              icon: const Icon(Icons.navigation),
              onPressed: () => _navigate(detail),
              label: Text(s.t(FsmText.navigate)),
            ),
          ),
      ],
    );
  }

  Widget _equipmentSection(FieldServiceStrings s, FsmWorkOrderDetail detail) {
    final FsmEquipment? eq = detail.equipment;
    if (eq == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Line(
          label: s.t(FsmText.equipment),
          value: '${s.t(FsmText.serialNumber)} ${eq.serialNumber}',
        ),
        if (widget.device.scanCode != null && !detail.signed)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('fsm-scan-asset'),
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _scanAsset(eq),
              label: Text(s.t(FsmText.scanAsset)),
            ),
          ),
      ],
    );
  }

  Widget _coverageSection(FieldServiceStrings s, CoverageSummary c) {
    Widget row(String label, bool covered, Key key) => Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        Chip(
          key: key,
          label: Text(s.t(covered ? FsmText.covered : FsmText.chargeable)),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.t(FsmText.coverageTitle),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        row(
          s.t(FsmText.coverageLabor),
          c.labor,
          const Key('fsm-coverage-labor'),
        ),
        row(
          s.t(FsmText.coverageParts),
          c.parts,
          const Key('fsm-coverage-parts'),
        ),
        row(
          s.t(FsmText.coverageTravel),
          c.travelAndCallout,
          const Key('fsm-coverage-travel'),
        ),
        if (c.estimated)
          Text(
            s.t(FsmText.coverageEstimated),
            key: const Key('fsm-coverage-estimated'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _checklistSection(FieldServiceStrings s, FsmWorkOrderDetail detail) {
    if (detail.checklist.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.t(FsmText.checklistTitle),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final ChecklistEntry entry in detail.checklist)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FfSpace.space1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.checklistItem(entry.item)),
                Wrap(
                  spacing: FfSpace.space2,
                  children: <Widget>[
                    for (final ChecklistResult r in <ChecklistResult>[
                      ChecklistResult.pass,
                      ChecklistResult.fail,
                      ChecklistResult.na,
                    ])
                      ChoiceChip(
                        key: Key('fsm-check-${entry.item}-${r.wire}'),
                        label: Text(
                          s.t(switch (r) {
                            ChecklistResult.pass => FsmText.resultPass,
                            ChecklistResult.fail => FsmText.resultFail,
                            _ => FsmText.resultNa,
                          }),
                        ),
                        selected: entry.result == r,
                        onSelected: detail.signed
                            ? null
                            : (_) => widget.repository.setChecklistResult(
                                widget.workOrderId,
                                entry.item,
                                r,
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _partsSection(FieldServiceStrings s, FsmWorkOrderDetail detail) {
    final double chargeable = detail.parts.fold<double>(
      0,
      (double sum, FsmPartLine p) => sum + p.chargeable,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.t(FsmText.partsTitle),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (detail.parts.isEmpty)
          Text(s.t(FsmText.noParts), key: const Key('fsm-no-parts')),
        for (final FsmPartLine p in detail.parts)
          ListTile(
            key: Key('fsm-part-${p.clientUuid}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${formatQuantity(p.quantity)} × ${p.sku} · ${p.name}'),
            subtitle: Text(
              <String>[
                if (p.lotNumber != null) p.lotNumber!,
                fill(s.t(FsmText.unitPrice), <String, Object>{
                  'price': p.unitPrice.toStringAsFixed(2),
                }),
              ].join(' · '),
            ),
            leading: Chip(
              key: Key('fsm-part-flag-${p.clientUuid}'),
              label: Text(
                s.t(p.covered ? FsmText.covered : FsmText.chargeable),
              ),
            ),
            trailing: detail.signed
                ? null
                : IconButton(
                    key: Key('fsm-part-remove-${p.clientUuid}'),
                    tooltip: s.t(FsmText.removePart),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removePart(p),
                  ),
          ),
        if (detail.parts.isNotEmpty) ...<Widget>[
          Text(
            fill(s.t(FsmText.chargeableTotal), <String, Object>{
              'amount': chargeable.toStringAsFixed(2),
            }),
            key: const Key('fsm-chargeable-total'),
          ),
          Text(
            s.t(FsmText.currencyNote),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (!detail.signed)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('fsm-add-part'),
              icon: const Icon(Icons.add),
              onPressed: () => _addPart(detail.workOrder),
              label: Text(s.t(FsmText.addPart)),
            ),
          ),
      ],
    );
  }

  Widget _historySection(FieldServiceStrings s, FsmWorkOrderDetail detail) {
    final List<FsmHistoryEntry> history =
        detail.equipment?.history ?? const <FsmHistoryEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.t(FsmText.history),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (history.isEmpty) Text(s.t(FsmText.noHistory)),
        for (final FsmHistoryEntry h in history)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              <String>[
                h.reportNumber,
                if (h.signedAt != null) _when(h.signedAt!),
              ].join(' · '),
            ),
            subtitle: Text(h.summary),
          ),
      ],
    );
  }

  Widget _signedSection(FieldServiceStrings s, StoredReport report) => Column(
    key: const Key('fsm-signed'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        s.t(FsmText.alreadySigned),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        fill(s.t(FsmText.reportSigned), <String, Object>{
          'at': _when(report.signedAt),
        }),
      ),
      if (report.reportNumber != null)
        Text(
          fill(s.t(FsmText.reportNumber), <String, Object>{
            'number': report.reportNumber!,
          }),
        ),
      Text(
        fill(s.t(FsmText.signatureHash), <String, Object>{
          'hash': report.signatureSha256,
        }),
        key: const Key('fsm-signature-hash'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

String _two(int v) => v.toString().padLeft(2, '0');

String _when(DateTime t) {
  final DateTime l = t.toLocal();
  return '${l.year}-${_two(l.month)}-${_two(l.day)} ${_two(l.hour)}:${_two(l.minute)}';
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: FfSpace.space1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value),
      ],
    ),
  );
}
