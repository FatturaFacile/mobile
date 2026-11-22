import 'package:fattura_facile/features/field_service/data/field_service_outbox.dart';
import 'package:fattura_facile/features/field_service/data/field_service_repository.dart';
import 'package:fattura_facile/features/field_service/domain/coverage_policy.dart';
import 'package:fattura_facile/features/field_service/models/field_service_models.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// In-memory stand-in of the repository for the widget tests: it records every call and never touches SQLite or the network.
class FakeFsmRepository implements FieldServiceRepository {
  FakeFsmRepository({
    List<FsmQueueItem>? queue,
    FsmWorkOrderDetail? detail,
    List<VanStockItem>? van,
  }) : queue = queue ?? <FsmQueueItem>[queueItem()],
       detailValue = detail ?? detailFixture(),
       van = van ?? OfflineBundle.fromJson(bundleJson()).vanStock;

  List<FsmQueueItem> queue;
  FsmWorkOrderDetail? detailValue;
  List<VanStockItem> van;
  int pending = 0;
  List<FsmOperation> conflicts = <FsmOperation>[];

  final List<String> calls = <String>[];
  final Map<String, Map<String, dynamic>> drafts =
      <String, Map<String, dynamic>>{};
  ServiceReportDraft? signedDraft;
  FsmException? failWith;
  FsmFlushReport syncReport = const FsmFlushReport(applied: 1);
  FsmRefreshResult refreshResult = const FsmRefreshResult();
  ({VanStockItem item, double quantity, String? lot})? consumed;

  @override
  Stream<List<FsmQueueItem>> watchWorkQueue() =>
      Stream<List<FsmQueueItem>>.value(queue);

  @override
  Stream<FsmWorkOrderDetail?> watchDetail(String workOrderId) =>
      Stream<FsmWorkOrderDetail?>.value(detailValue);

  @override
  Stream<List<VanStockItem>> watchVanStock() =>
      Stream<List<VanStockItem>>.value(van);

  @override
  Stream<int> watchPending() => Stream<int>.value(pending);

  @override
  Stream<List<FsmOperation>> watchConflicts() =>
      Stream<List<FsmOperation>>.value(conflicts);

  @override
  Future<FsmRefreshResult> refresh() async {
    calls.add('refresh');
    return refreshResult;
  }

  @override
  Future<FsmFlushReport> sync() async {
    calls.add('sync');
    return syncReport;
  }

  @override
  Future<void> advanceStatus(
    String workOrderId,
    FsmStatus target, {
    DateTime? at,
  }) async {
    calls.add('advance:${target.wire}');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> setChecklistResult(
    String workOrderId,
    String item,
    ChecklistResult result, {
    String? notes,
  }) async {
    calls.add('check:$item:${result.wire}');
  }

  @override
  Future<FsmPartLine> consumePart(
    String workOrderId,
    VanStockItem item,
    double quantity, {
    String? lotNumber,
    String? lotOrSerialId,
  }) async {
    if (failWith != null) throw failWith!;
    consumed = (item: item, quantity: quantity, lot: lotNumber);
    calls.add('consume:${item.sku}:$quantity');
    return FsmPartLine(
      clientUuid: 'part-1',
      workOrderId: workOrderId,
      productId: item.productId,
      sku: item.sku,
      name: item.name,
      quantity: quantity,
      unitPrice: item.unitPrice,
      covered: true,
      createdAt: DateTime.utc(2030),
    );
  }

  @override
  Future<void> removePart(String workOrderId, String clientUuid) async {
    calls.add('remove-part:$clientUuid');
  }

  @override
  Future<ReportPhoto> addPhoto(
    String workOrderId, {
    required String localPath,
    required String name,
    DateTime? takenAt,
  }) async {
    calls.add('photo:$name:$localPath');
    return ReportPhoto(
      id: 'ph-1',
      path: 'fsm/$workOrderId/$name',
      name: name,
      takenAt: DateTime.utc(2030),
      localPath: localPath,
    );
  }

  @override
  Future<void> removePhoto(String workOrderId, String photoId) async {
    calls.add('remove-photo:$photoId');
  }

  @override
  Future<Map<String, dynamic>> loadDraft(String workOrderId) async =>
      drafts[workOrderId] ?? <String, dynamic>{};

  @override
  Future<void> saveDraft(String workOrderId, Map<String, dynamic> draft) async {
    drafts[workOrderId] = draft;
  }

  @override
  Future<StoredReport> signAndClose(
    String workOrderId,
    ServiceReportDraft draft,
  ) async {
    if (failWith != null) throw failWith!;
    signedDraft = draft;
    calls.add('sign');
    return StoredReport(
      workOrderId: workOrderId,
      clientUuid: 'rep-1',
      signatureSha256: 'hash',
      signedAt: draft.signedAt,
      payload: draft.toPayload(),
    );
  }

  @override
  Future<void> retryOperation(String clientUuid) async {
    calls.add('retry:$clientUuid');
  }

  @override
  Future<void> discardOperation(String clientUuid) async {
    calls.add('discard:$clientUuid');
  }
}

FsmQueueItem queueItem({
  String id = woCorrective,
  String workType = 'corrective',
  FsmStatus status = FsmStatus.dispatched,
}) {
  final FsmWorkOrder wo = FsmWorkOrder.fromJson(
    workOrderJson(id: id, status: status.wire, workType: workType),
  );
  return FsmQueueItem(
    workOrder: wo,
    customerName: 'Rossi SA',
    equipmentSerial: 'SN-4711',
    site: wo.site,
  );
}

FsmWorkOrderDetail detailFixture({
  FsmStatus status = FsmStatus.dispatched,
  String workType = 'corrective',
  bool withContract = true,
  List<FsmPartLine> parts = const <FsmPartLine>[],
  StoredReport? report,
  int pending = 0,
  bool withEquipment = true,
}) {
  final FsmWorkOrder wo = FsmWorkOrder.fromJson(
    workOrderJson(
      status: status.wire,
      workType: workType,
      contract: withContract ? contractId : null,
    ),
  );
  final OfflineBundle bundle = OfflineBundle.fromJson(bundleJson());
  return FsmWorkOrderDetail(
    workOrder: wo,
    coverage: const CoveragePolicy().summary(wo),
    site: wo.site,
    customer: bundle.customers.single,
    equipment: withEquipment ? bundle.equipment.single : null,
    parts: parts,
    checklist: <ChecklistEntry>[
      for (final String item in wo.checklistTemplate)
        ChecklistEntry(item: item),
    ],
    report: report,
    pendingOperations: pending,
  );
}

FsmPartLine partLine({
  bool covered = true,
  String uuid = 'p-1',
  double quantity = 2,
}) => FsmPartLine(
  clientUuid: uuid,
  workOrderId: woCorrective,
  productId: productFilter,
  sku: 'FLT-1',
  name: 'Air filter',
  quantity: quantity,
  unitPrice: 25,
  covered: covered,
  createdAt: DateTime.utc(2030),
  lotNumber: 'LOT-9',
);

FsmOperation conflict({
  String uuid = 'c1',
  FsmOperationType type = FsmOperationType.serviceReport,
}) => FsmOperation(
  sequence: 1,
  clientUuid: uuid,
  tenantId: tenant,
  workOrderId: woCorrective,
  type: type,
  payload: const <String, dynamic>{},
  state: FsmOutboxState.rejected,
  attempts: 1,
  createdAt: DateTime.utc(2030),
  errors: const <String, List<String>>{
    'work_order': <String>['report_exists'],
  },
);

/// A host app with a button that opens [page], so `Navigator.pop` has somewhere to go.
Widget hostApp(Widget page, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      localizationsDelegates: testDelegates,
      locale: locale,
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open-page'),
              onPressed: () => Navigator.of(context)
                  .push<void>(MaterialPageRoute<void>(builder: (_) => page)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

/// A phone-tall surface so long forms are fully on screen.
void tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Material and widget strings for the languages the screens are tested in.
const List<LocalizationsDelegate<dynamic>> testDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];
