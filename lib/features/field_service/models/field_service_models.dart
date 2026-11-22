/// Models of the Field Service technician workflow (Mod 17, #196/#202) as the API speaks them (`/api/v1/fsm`): the offline
/// bundle the technician downloads, the operations queued for `POST /fsm/mobile-sync` and the signed service report.
library;

import 'dart:convert';

/// Reads a JSON number that Laravel may serialise as a number or as a decimal string.
double? fsmNum(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value'.trim());
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');

List<String> _strings(Object? value) => <String>[
  for (final Object? v in (value as List<dynamic>? ?? const <dynamic>[])) '$v',
];

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Status of a work order along the technician journey. `completed` is reached by signing the service report.
enum FsmStatus {
  dispatched('dispatched'),
  enRoute('en_route'),
  onSite('on_site'),
  inProgress('in_progress'),
  completed('completed'),
  closed('closed'),
  invoiced('invoiced'),
  unknown('');

  const FsmStatus(this.wire);

  final String wire;

  static FsmStatus fromWire(String? value) => FsmStatus.values.firstWhere(
    (FsmStatus s) => s.wire == value && value != '',
    orElse: () => FsmStatus.unknown,
  );

  /// Position along the journey, like the server (`ProcessMobileSyncBatchHandler::journeyRank`).
  int get rank => switch (this) {
    FsmStatus.dispatched => 0,
    FsmStatus.enRoute => 1,
    FsmStatus.onSite => 2,
    FsmStatus.inProgress ||
    FsmStatus.completed ||
    FsmStatus.closed ||
    FsmStatus.invoiced => 3,
    FsmStatus.unknown => -1,
  };

  /// Statuses that stay in the technician's queue.
  bool get isOpen =>
      this == dispatched ||
      this == enRoute ||
      this == onSite ||
      this == inProgress;

  /// The next step of the journey the technician can queue, null once on site.
  FsmStatus? get nextStep => switch (this) {
    FsmStatus.dispatched => FsmStatus.enRoute,
    FsmStatus.enRoute => FsmStatus.onSite,
    _ => null,
  };

  /// `en_route` only from dispatched, `on_site` from dispatched or en route (`AdvanceFieldWorkOrderStatusHandler`).
  bool canMoveTo(FsmStatus target) => switch (target) {
    FsmStatus.enRoute => this == FsmStatus.dispatched,
    FsmStatus.onSite =>
      this == FsmStatus.dispatched || this == FsmStatus.enRoute,
    _ => false,
  };
}

/// Where the technician has to go: `{address, lat, lng}` of the work order location.
class FsmSite {
  const FsmSite({this.address, this.latitude, this.longitude});

  factory FsmSite.fromJson(Object? json) {
    final Map<String, dynamic> m = _map(json);
    final String address = '${m['address'] ?? ''}'.trim();
    return FsmSite(
      address: address.isEmpty ? null : address,
      latitude: fsmNum(m['lat'] ?? m['latitude']),
      longitude: fsmNum(m['lng'] ?? m['longitude']),
    );
  }

  final String? address;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isEmpty => !hasCoordinates && (address == null || address!.isEmpty);

  /// This site completed with [other] where a value is missing (the work order site with the equipment passport site).
  FsmSite orElse(FsmSite other) => FsmSite(
    address: address ?? other.address,
    latitude: hasCoordinates ? latitude : other.latitude,
    longitude: hasCoordinates ? longitude : other.longitude,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'address': address,
    'lat': latitude,
    'lng': longitude,
  };
}

/// What a maintenance contract covers (`CoveragePolicy` types of the API).
enum CoverageType {
  laborOnly('labor_only'),
  partsAndLabor('parts_and_labor'),
  preventiveOnly('preventive_only'),
  fullComprehensive('full_comprehensive');

  const CoverageType(this.wire);

  final String wire;

  static CoverageType fromWire(String? value) => CoverageType.values.firstWhere(
    (CoverageType t) => t.wire == value,
    // The server treats a contract without coverage_type as parts_and_labor.
    orElse: () => CoverageType.partsAndLabor,
  );
}

/// The contract of a work order as far as the coverage rules need it.
class ContractCoverage {
  const ContractCoverage({
    required this.contractId,
    this.type = CoverageType.partsAndLabor,
    this.active = true,
    this.assumed = false,
  });

  /// Reads `service_contract: {id, coverage_type, status}`, or the flat `contract_coverage_type` / `contract_status` keys.
  /// A bundle that only carries `service_contract_id` yields the server defaults (parts and labor, active) flagged
  /// [assumed], so the screens can say the indicator is an estimate.
  static ContractCoverage? fromWorkOrderJson(Map<String, dynamic> json) {
    final Map<String, dynamic> nested = _map(json['service_contract']);
    final String? id = json['service_contract_id'] == null
        ? (nested['id'] == null ? null : '${nested['id']}')
        : '${json['service_contract_id']}';
    if (id == null) return null;
    final Object? type =
        nested['coverage_type'] ?? json['contract_coverage_type'];
    final Object? status = nested['status'] ?? json['contract_status'];
    return ContractCoverage(
      contractId: id,
      type: CoverageType.fromWire(type == null ? null : '$type'),
      active: status == null || '$status' == 'active',
      assumed: nested['assumed'] == true || (type == null && status == null),
    );
  }

  final String contractId;
  final CoverageType type;
  final bool active;
  final bool assumed;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': contractId,
    'coverage_type': type.wire,
    'status': active ? 'active' : 'inactive',
    'assumed': assumed,
  };
}

/// One work order of the offline queue.
class FsmWorkOrder {
  const FsmWorkOrder({
    required this.id,
    required this.number,
    required this.workType,
    required this.priority,
    required this.status,
    required this.title,
    this.problemDescription,
    this.customerId,
    this.equipmentId,
    this.serviceContractId,
    this.scheduledStart,
    this.scheduledEnd,
    this.site = const FsmSite(),
    this.requiredSkills = const <String>[],
    this.checklistTemplate = const <String>[],
    this.updatedAt,
    this.contract,
  });

  factory FsmWorkOrder.fromJson(Map<String, dynamic> json) {
    final List<dynamic> template =
        json['checklist_template'] as List<dynamic>? ?? const <dynamic>[];
    return FsmWorkOrder(
      id: '${json['id']}',
      number: '${json['work_order_number'] ?? ''}',
      workType: '${json['work_type'] ?? 'corrective'}',
      priority: '${json['priority'] ?? ''}',
      status: FsmStatus.fromWire('${json['status']}'),
      title: '${json['title'] ?? ''}',
      problemDescription: json['problem_description'] as String?,
      customerId: json['customer_id'] == null ? null : '${json['customer_id']}',
      equipmentId: json['equipment_passport_id'] == null
          ? null
          : '${json['equipment_passport_id']}',
      serviceContractId: json['service_contract_id'] == null
          ? null
          : '${json['service_contract_id']}',
      scheduledStart: _date(json['scheduled_start']),
      scheduledEnd: _date(json['scheduled_end']),
      site: FsmSite.fromJson(json['site']),
      requiredSkills: _strings(json['required_skills']),
      checklistTemplate: <String>[
        for (final dynamic row in template)
          if (row is Map && row['item'] != null) '${row['item']}',
      ],
      updatedAt: _date(json['updated_at']),
      contract: ContractCoverage.fromWorkOrderJson(json),
    );
  }

  final String id;
  final String number;

  /// `preventive`, `corrective`, `installation` or `warranty`.
  final String workType;
  final String priority;
  final FsmStatus status;
  final String title;
  final String? problemDescription;
  final String? customerId;
  final String? equipmentId;
  final String? serviceContractId;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final FsmSite site;
  final List<String> requiredSkills;

  /// The checklist item codes (`visual_inspection`, `fault_diagnosis`, ...) the technician answers on site.
  final List<String> checklistTemplate;
  final DateTime? updatedAt;
  final ContractCoverage? contract;

  bool get isWarranty => workType == 'warranty';

  FsmWorkOrder copyWith({FsmStatus? status}) => FsmWorkOrder(
    id: id,
    number: number,
    workType: workType,
    priority: priority,
    status: status ?? this.status,
    title: title,
    problemDescription: problemDescription,
    customerId: customerId,
    equipmentId: equipmentId,
    serviceContractId: serviceContractId,
    scheduledStart: scheduledStart,
    scheduledEnd: scheduledEnd,
    site: site,
    requiredSkills: requiredSkills,
    checklistTemplate: checklistTemplate,
    updatedAt: updatedAt,
    contract: contract,
  );

  /// The stored form: the bundle row plus the coverage details, so a reload gives the same object back.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'work_order_number': number,
    'work_type': workType,
    'priority': priority,
    'status': status.wire,
    'title': title,
    'problem_description': problemDescription,
    'customer_id': customerId,
    'equipment_passport_id': equipmentId,
    'service_contract_id': serviceContractId,
    'scheduled_start': scheduledStart?.toUtc().toIso8601String(),
    'scheduled_end': scheduledEnd?.toUtc().toIso8601String(),
    'site': site.toJson(),
    'required_skills': requiredSkills,
    'checklist_template': <Map<String, String>>[
      for (final String item in checklistTemplate)
        <String, String>{'item': item},
    ],
    'updated_at': updatedAt?.toUtc().toIso8601String(),
    if (contract != null) 'service_contract': contract!.toJson(),
  };
}

class FsmCustomer {
  const FsmCustomer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory FsmCustomer.fromJson(Map<String, dynamic> json) => FsmCustomer(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
  );

  final String id;
  final String name;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
  };
}

/// One of the last service reports of an asset.
class FsmHistoryEntry {
  const FsmHistoryEntry({
    required this.reportNumber,
    required this.signedAt,
    required this.summary,
    this.meterHours,
    this.meterCycles,
  });

  factory FsmHistoryEntry.fromJson(Map<String, dynamic> json) =>
      FsmHistoryEntry(
        reportNumber: '${json['report_number'] ?? ''}',
        signedAt: _date(json['signed_at']),
        summary: '${json['summary'] ?? ''}',
        meterHours: fsmNum(json['meter_reading_hours']),
        meterCycles: fsmNum(json['meter_reading_cycles'])?.toInt(),
      );

  final String reportNumber;
  final DateTime? signedAt;
  final String summary;
  final double? meterHours;
  final int? meterCycles;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'report_number': reportNumber,
    'signed_at': signedAt?.toUtc().toIso8601String(),
    'summary': summary,
    'meter_reading_hours': meterHours,
    'meter_reading_cycles': meterCycles,
  };
}

/// A customer asset (equipment passport) with its meters and recent history.
class FsmEquipment {
  const FsmEquipment({
    required this.id,
    required this.serialNumber,
    this.productId,
    this.siteAddress,
    this.siteLatitude,
    this.siteLongitude,
    this.operatingHours = 0,
    this.cycleCount = 0,
    this.lastServiceDate,
    this.history = const <FsmHistoryEntry>[],
  });

  factory FsmEquipment.fromJson(Map<String, dynamic> json) => FsmEquipment(
    id: '${json['id']}',
    serialNumber: '${json['serial_number'] ?? ''}',
    productId: json['product_id'] == null ? null : '${json['product_id']}',
    siteAddress: json['site_address'] as String?,
    siteLatitude: fsmNum(json['site_latitude']),
    siteLongitude: fsmNum(json['site_longitude']),
    operatingHours: fsmNum(json['current_operating_hours']) ?? 0,
    cycleCount: fsmNum(json['current_cycle_count'])?.toInt() ?? 0,
    lastServiceDate: json['last_service_date'] as String?,
    history: <FsmHistoryEntry>[
      for (final dynamic h
          in (json['history'] as List<dynamic>? ?? const <dynamic>[]))
        FsmHistoryEntry.fromJson(_map(h)),
    ],
  );

  final String id;
  final String serialNumber;
  final String? productId;
  final String? siteAddress;
  final double? siteLatitude;
  final double? siteLongitude;
  final double operatingHours;
  final int cycleCount;
  final String? lastServiceDate;
  final List<FsmHistoryEntry> history;

  FsmSite get site => FsmSite(
    address: siteAddress,
    latitude: siteLatitude,
    longitude: siteLongitude,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'serial_number': serialNumber,
    'product_id': productId,
    'site_address': siteAddress,
    'site_latitude': siteLatitude,
    'site_longitude': siteLongitude,
    'current_operating_hours': operatingHours,
    'current_cycle_count': cycleCount,
    'last_service_date': lastServiceDate,
    'history': history.map((FsmHistoryEntry h) => h.toJson()).toList(),
  };
}

/// A product of the technician's van with the quantity on board.
class VanStockItem {
  const VanStockItem({
    required this.productId,
    required this.sku,
    required this.name,
    required this.available,
    this.unitPrice = 0,
  });

  factory VanStockItem.fromJson(Map<String, dynamic> json) => VanStockItem(
    productId: '${json['product_id']}',
    sku: '${json['sku'] ?? ''}',
    name: '${json['name'] ?? ''}',
    available: fsmNum(json['available']) ?? 0,
    unitPrice: fsmNum(json['unit_price']) ?? 0,
  );

  final String productId;
  final String sku;
  final String name;
  final double available;

  /// List sale price; the server bills 0.00 when the work order is covered.
  final double unitPrice;

  VanStockItem withAvailable(double value) => VanStockItem(
    productId: productId,
    sku: sku,
    name: name,
    available: value,
    unitPrice: unitPrice,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'product_id': productId,
    'sku': sku,
    'name': name,
    'available': available,
    'unit_price': unitPrice,
  };
}

class FsmTechnician {
  const FsmTechnician({
    required this.id,
    required this.name,
    this.skills = const <String>[],
    this.vanWarehouseId,
  });

  factory FsmTechnician.fromJson(Map<String, dynamic> json) => FsmTechnician(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    skills: _strings(json['skills']),
    vanWarehouseId: json['van_warehouse_id'] == null
        ? null
        : '${json['van_warehouse_id']}',
  );

  final String id;
  final String name;
  final List<String> skills;
  final String? vanWarehouseId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'skills': skills,
    'van_warehouse_id': vanWarehouseId,
  };
}

/// `GET /fsm/technicians/{id}/offline-bundle` (data envelope content).
class OfflineBundle {
  const OfflineBundle({
    required this.serverTime,
    required this.technician,
    required this.openWorkOrderIds,
    required this.workOrders,
    required this.customers,
    required this.equipment,
    required this.vanStock,
  });

  factory OfflineBundle.fromJson(Map<String, dynamic> json) => OfflineBundle(
    serverTime: '${json['server_time'] ?? ''}',
    technician: FsmTechnician.fromJson(_map(json['technician'])),
    openWorkOrderIds: _strings(json['open_work_order_ids']),
    workOrders: <FsmWorkOrder>[
      for (final dynamic w
          in (json['work_orders'] as List<dynamic>? ?? const <dynamic>[]))
        FsmWorkOrder.fromJson(_map(w)),
    ],
    customers: <FsmCustomer>[
      for (final dynamic c
          in (json['customers'] as List<dynamic>? ?? const <dynamic>[]))
        FsmCustomer.fromJson(_map(c)),
    ],
    equipment: <FsmEquipment>[
      for (final dynamic e
          in (json['equipment'] as List<dynamic>? ?? const <dynamic>[]))
        FsmEquipment.fromJson(_map(e)),
    ],
    vanStock: <VanStockItem>[
      for (final dynamic v
          in (json['van_stock'] as List<dynamic>? ?? const <dynamic>[]))
        VanStockItem.fromJson(_map(v)),
    ],
  );

  /// Pass back as `since` on the next call.
  final String serverTime;
  final FsmTechnician technician;

  /// Every open assignment, to drop the ones that left the queue.
  final List<String> openWorkOrderIds;
  final List<FsmWorkOrder> workOrders;
  final List<FsmCustomer> customers;
  final List<FsmEquipment> equipment;
  final List<VanStockItem> vanStock;
}

/// Answer of one checklist point (`pass`, `fail`, `na`) or still `pending`.
enum ChecklistResult {
  pending('pending'),
  pass('pass'),
  fail('fail'),
  na('na');

  const ChecklistResult(this.wire);

  final String wire;

  static ChecklistResult fromWire(String? value) =>
      ChecklistResult.values.firstWhere(
        (ChecklistResult r) => r.wire == value,
        orElse: () => ChecklistResult.pending,
      );
}

class ChecklistEntry {
  const ChecklistEntry({
    required this.item,
    this.result = ChecklistResult.pending,
    this.notes,
  });

  final String item;
  final ChecklistResult result;
  final String? notes;

  bool get answered => result != ChecklistResult.pending;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item': item,
    'result': result.wire,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

/// Moment of the intervention a photo documents (`stage` of the photo upload).
enum FsmPhotoStage {
  before('before'),
  during('during'),
  after('after');

  const FsmPhotoStage(this.wire);

  final String wire;

  static FsmPhotoStage? fromWire(String? value) {
    for (final FsmPhotoStage s in FsmPhotoStage.values) {
      if (s.wire == value) return s;
    }
    return null;
  }
}

/// Where the file of a photo stands on its way to the server.
enum FsmPhotoUpload {
  /// Waiting in the outbox (first attempt or a transient retry).
  queued,

  /// The server stored it and answered its id.
  uploaded,

  /// The server refused it or the file is gone from the phone: a conflict to retry or discard.
  failed,
}

/// A photo taken on site. [path] is the legacy reference sent with the report (`photos.*.path`), [localPath] the file on the
/// phone, [serverId] the id the photo endpoint answered once [upload] is [FsmPhotoUpload.uploaded].
class ReportPhoto {
  const ReportPhoto({
    required this.id,
    required this.path,
    required this.name,
    required this.takenAt,
    this.localPath,
    this.stage,
    this.caption,
    this.serverId,
    this.upload = FsmPhotoUpload.queued,
  });

  /// Also the `client_uuid` of the upload operation, so a retry is idempotent.
  final String id;
  final String path;
  final String name;
  final DateTime takenAt;
  final String? localPath;
  final FsmPhotoStage? stage;
  final String? caption;
  final String? serverId;
  final FsmPhotoUpload upload;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'name': name,
    'taken_at': takenAt.toUtc().toIso8601String(),
  };

  /// The `payload` of the `photo_upload` operation: what the multipart request needs at send time.
  Map<String, dynamic> toUploadPayload() => <String, dynamic>{
    'local_path': localPath,
    'name': name,
    'captured_at': takenAt.toUtc().toIso8601String(),
    if (stage != null) 'stage': stage!.wire,
    if (caption != null && caption!.trim().isNotEmpty)
      'caption': caption!.trim(),
  };
}

/// A van part consumed on a work order, with the indicator computed offline.
class FsmPartLine {
  const FsmPartLine({
    required this.clientUuid,
    required this.workOrderId,
    required this.productId,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.covered,
    required this.createdAt,
    this.lotNumber,
    this.lotOrSerialId,
  });

  factory FsmPartLine.fromJson(Map<String, dynamic> json) => FsmPartLine(
    clientUuid: '${json['client_uuid']}',
    workOrderId: '${json['work_order_id']}',
    productId: '${json['product_id']}',
    sku: '${json['sku'] ?? ''}',
    name: '${json['name'] ?? ''}',
    quantity: fsmNum(json['quantity']) ?? 0,
    unitPrice: fsmNum(json['unit_price']) ?? 0,
    covered: json['covered'] == true || json['covered'] == 1,
    createdAt:
        _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    lotNumber: json['lot_number'] as String?,
    lotOrSerialId: json['lot_or_serial_id'] as String?,
  );

  final String clientUuid;
  final String workOrderId;
  final String productId;
  final String sku;
  final String name;
  final double quantity;

  /// List price per unit.
  final double unitPrice;

  /// Covered by warranty or contract: billed at 0.00.
  final bool covered;
  final DateTime createdAt;
  final String? lotNumber;
  final String? lotOrSerialId;

  /// What the customer pays for the line.
  double get chargeable => covered ? 0 : quantity * unitPrice;

  /// The `payload` of the `part_consumption` operation (`client_uuid` travels on the operation).
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    if (lotNumber != null && lotNumber!.isNotEmpty) 'lot_number': lotNumber,
    if (lotOrSerialId != null) 'lot_or_serial_id': lotOrSerialId,
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'client_uuid': clientUuid,
    'work_order_id': workOrderId,
    'product_id': productId,
    'sku': sku,
    'name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
    'covered': covered,
    'created_at': createdAt.toUtc().toIso8601String(),
    'lot_number': lotNumber,
    'lot_or_serial_id': lotOrSerialId,
  };
}

/// The locales of the report (`locale` field of the service report rules).
const List<String> fsmReportLocales = <String>[
  'it-IT',
  'it-CH',
  'de-CH',
  'fr-CH',
  'en',
];

/// The service report as the technician fills it in and the customer signs it. Validation mirrors
/// `SignServiceReportRules` so the server never rejects what passed here.
class ServiceReportDraft {
  const ServiceReportDraft({
    required this.workPerformedSummary,
    required this.laborHours,
    required this.signerName,
    required this.signatureSvg,
    required this.signedAt,
    this.checklist = const <ChecklistEntry>[],
    this.travelHours = 0,
    this.travelKm = 0,
    this.applyCalloutFee = false,
    this.meterReadingHours,
    this.meterReadingCycles,
    this.signerRole,
    this.latitude,
    this.longitude,
    this.photos = const <ReportPhoto>[],
    this.locale = 'it-IT',
  });

  final String workPerformedSummary;
  final List<ChecklistEntry> checklist;
  final double laborHours;
  final double travelHours;
  final double travelKm;
  final bool applyCalloutFee;
  final double? meterReadingHours;
  final int? meterReadingCycles;
  final String signerName;
  final String? signerRole;

  /// Vector signature, starts with `<svg`.
  final String signatureSvg;
  final DateTime signedAt;
  final double? latitude;
  final double? longitude;
  final List<ReportPhoto> photos;
  final String locale;

  static final RegExp _svgStart = RegExp(
    r'^\s*<svg[\s>]',
    caseSensitive: false,
  );
  static final RegExp _svgUnsafe = RegExp(
    r'''<\s*script|[\s"']on[a-z]+\s*=|javascript:''',
    caseSensitive: false,
  );

  /// The SVG size ceiling of the server (`SignAndCloseServiceReportHandler::SvgMaxBytes`).
  static const int svgMaxBytes = 262144;

  /// Field -> error code, empty when the report can be signed. Keys are the API field names.
  Map<String, String> validate() {
    final Map<String, String> errors = <String, String>{};
    if (workPerformedSummary.trim().isEmpty) {
      errors['work_performed_summary'] = 'required';
    } else if (workPerformedSummary.length > 5000) {
      errors['work_performed_summary'] = 'max';
    }
    if (laborHours < 0 || laborHours > 999) errors['labor_hours'] = 'range';
    if (travelHours < 0 || travelHours > 999) errors['travel_hours'] = 'range';
    if (travelKm < 0 || travelKm > 99999) errors['travel_km'] = 'range';
    if (meterReadingHours != null && meterReadingHours! < 0) {
      errors['meter_reading_hours'] = 'range';
    }
    if (meterReadingCycles != null && meterReadingCycles! < 0) {
      errors['meter_reading_cycles'] = 'range';
    }
    if (signerName.trim().isEmpty) {
      errors['customer_signer_name'] = 'required';
    } else if (signerName.length > 150) {
      errors['customer_signer_name'] = 'max';
    }
    if ((signerRole ?? '').length > 100) errors['customer_signer_role'] = 'max';
    if (!_svgStart.hasMatch(signatureSvg) ||
        _svgUnsafe.hasMatch(signatureSvg)) {
      errors['signature_svg'] = 'required';
    } else if (utf8.encode(signatureSvg).length > svgMaxBytes) {
      errors['signature_svg'] = 'max';
    }
    if (latitude != null && (latitude! < -90 || latitude! > 90)) {
      errors['gps_latitude'] = 'range';
    }
    if (longitude != null && (longitude! < -180 || longitude! > 180)) {
      errors['gps_longitude'] = 'range';
    }
    if (photos.length > 20) errors['photos'] = 'max';
    if (checklist.length > 100 ||
        checklist.any((ChecklistEntry c) => !c.answered)) {
      errors['checklist'] = 'unanswered';
    }
    if (!fsmReportLocales.contains(locale)) errors['locale'] = 'invalid';
    return errors;
  }

  /// The `payload` of the `service_report` operation (`client_uuid` travels on the operation).
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'work_performed_summary': workPerformedSummary.trim(),
    'checklist': checklist.map((ChecklistEntry c) => c.toJson()).toList(),
    'labor_hours': laborHours,
    'travel_hours': travelHours,
    'travel_km': travelKm,
    'apply_callout_fee': applyCalloutFee,
    if (meterReadingHours != null) 'meter_reading_hours': meterReadingHours,
    if (meterReadingCycles != null) 'meter_reading_cycles': meterReadingCycles,
    'customer_signer_name': signerName.trim(),
    if (signerRole != null && signerRole!.trim().isNotEmpty)
      'customer_signer_role': signerRole!.trim(),
    'signature_svg': signatureSvg,
    'signed_at': signedAt.toUtc().toIso8601String(),
    if (latitude != null) 'gps_latitude': latitude,
    if (longitude != null) 'gps_longitude': longitude,
    if (photos.isNotEmpty)
      'photos': photos.map((ReportPhoto p) => p.toJson()).toList(),
    'locale': locale,
  };
}

/// Types of the `operations[].type` of `POST /fsm/mobile-sync`.
enum FsmOperationType {
  statusTransition('status_transition'),
  partConsumption('part_consumption'),
  serviceReport('service_report'),

  /// Not part of `POST /fsm/mobile-sync`: sent as multipart to `POST /fsm/work-orders/{id}/photos`.
  photoUpload('photo_upload');

  const FsmOperationType(this.wire);

  final String wire;

  static FsmOperationType fromWire(String value) => FsmOperationType.values
      .firstWhere((FsmOperationType t) => t.wire == value);
}

/// States of an outbox row.
abstract final class FsmOutboxState {
  /// Waiting for its first or next attempt.
  static const int pending = 0;

  /// Transient failure (offline server error, 429, 5xx): retried after the backoff.
  static const int failed = 1;

  /// Rejected by the server with field errors (a conflict): kept for the technician, never resent on its own.
  static const int rejected = 2;

  /// Acknowledged as `applied` or `duplicate`.
  static const int done = 3;
}

/// One queued operation.
class FsmOperation {
  const FsmOperation({
    required this.sequence,
    required this.clientUuid,
    required this.tenantId,
    required this.workOrderId,
    required this.type,
    required this.payload,
    required this.state,
    required this.attempts,
    required this.createdAt,
    this.lastError,
    this.errors = const <String, List<String>>{},
    this.replayed = false,
    this.nextAttemptAt,
    this.result = const <String, dynamic>{},
  });

  final int sequence;

  /// Idempotency key: generated once and resent unchanged on every retry.
  final String clientUuid;
  final String tenantId;
  final String workOrderId;
  final FsmOperationType type;
  final Map<String, dynamic> payload;
  final int state;
  final int attempts;
  final DateTime createdAt;
  final String? lastError;

  /// Field errors of a rejection (`errors` of the sync result).
  final Map<String, List<String>> errors;

  /// Acknowledged as `duplicate`: the server had already applied it.
  final bool replayed;
  final DateTime? nextAttemptAt;

  /// Extra values of the acknowledgement (`report_number`, `signature_sha256_hash`, `consumption_id`...).
  final Map<String, dynamic> result;

  bool get isActive =>
      state == FsmOutboxState.pending || state == FsmOutboxState.failed;

  /// One entry of `operations` in the batch.
  Map<String, dynamic> toWire() => <String, dynamic>{
    'client_uuid': clientUuid,
    'type': type.wire,
    'work_order_id': workOrderId,
    'payload': payload,
  };
}

/// Result of one operation in the sync answer.
class FsmSyncResult {
  const FsmSyncResult({
    required this.clientUuid,
    required this.status,
    this.errors = const <String, List<String>>{},
    this.extra = const <String, dynamic>{},
  });

  factory FsmSyncResult.fromJson(Map<String, dynamic> json) {
    final Map<String, List<String>> errors = <String, List<String>>{};
    final Object? raw = json['errors'];
    if (raw is Map) {
      raw.forEach((Object? k, Object? v) {
        errors['$k'] = v is List
            ? v.map((Object? e) => '$e').toList()
            : <String>['$v'];
      });
    }
    return FsmSyncResult(
      clientUuid: '${json['client_uuid'] ?? ''}',
      status: '${json['status'] ?? ''}',
      errors: errors,
      extra: Map<String, dynamic>.from(json)
        ..removeWhere(
          (String k, dynamic _) =>
              k == 'client_uuid' ||
              k == 'type' ||
              k == 'status' ||
              k == 'errors',
        ),
    );
  }

  final String clientUuid;

  /// `applied`, `duplicate` or `rejected`.
  final String status;
  final Map<String, List<String>> errors;
  final Map<String, dynamic> extra;

  bool get rejected => status == 'rejected';
  bool get duplicate => status == 'duplicate';
}

/// The signed report kept on the phone until (and after) the server acknowledges it.
class StoredReport {
  const StoredReport({
    required this.workOrderId,
    required this.clientUuid,
    required this.signatureSha256,
    required this.signedAt,
    required this.payload,
    this.reportNumber,
    this.serverSealHash,
  });

  final String workOrderId;
  final String clientUuid;

  /// SHA-256 of the signature SVG, computed on the device when the customer signs.
  final String signatureSha256;
  final DateTime signedAt;
  final Map<String, dynamic> payload;

  /// Filled when the server acknowledges the report.
  final String? reportNumber;
  final String? serverSealHash;
}
