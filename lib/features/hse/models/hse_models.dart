/// Payloads of the HSE module (Mod 099) as the API expects them (`/api/v1/hse`).
///
/// The device only captures: the server hashes every signature together with the hand-over data (SHA-256), renders the
/// Verbale di Consegna and archives it, so none of that is computed here.
library;

import 'dart:convert';

/// Statutory regime of the tenant; it decides which legal notice the worker reads before signing.
enum HseJurisdiction {
  italy('IT'),
  switzerland('CH');

  const HseJurisdiction(this.wire);

  final String wire;

  static HseJurisdiction fromWire(String? value) =>
      value == 'CH' ? switzerland : italy;
}

/// The content of a PPE box label: `PPE:<product uuid>:<lot or serial number>`.
class PpeScan {
  const PpeScan({required this.productId, required this.lotOrSerial});

  final String productId;
  final String lotOrSerial;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Null when the code is not a PPE label (a worker badge or any other barcode).
  static PpeScan? parse(String code) {
    final parts = code.trim().split(':');
    if (parts.length < 3 ||
        parts.first.toUpperCase() != 'PPE' ||
        !_uuid.hasMatch(parts[1])) {
      return null;
    }
    final lot = parts.sublist(2).join(':').trim();
    if (lot.isEmpty) return null;
    return PpeScan(productId: parts[1], lotOrSerial: lot);
  }
}

/// One PPE hand-over waiting for its signature or already signed on glass.
class PpeHandOver {
  const PpeHandOver({
    required this.employeeId,
    required this.productId,
    required this.warehouseId,
    required this.lotOrSerial,
    required this.quantity,
    required this.signaturePayload,
    required this.locale,
    this.signatureImage,
    this.ceMarkingStandard,
    this.replacementDueAt,
    this.handedOverAt,
  });

  final String employeeId;
  final String productId;
  final String warehouseId;
  final String lotOrSerial;
  final double quantity;

  /// The strokes of the signature as JSON (see [SignatureController.toPayload]).
  final String signaturePayload;

  /// The signature as a base64 PNG, shown on the PDF.
  final String? signatureImage;
  final String locale;
  final String? ceMarkingStandard;
  final DateTime? replacementDueAt;
  final DateTime? handedOverAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'employee_id': employeeId,
    'product_id': productId,
    'warehouse_id': warehouseId,
    'lot_or_serial_id': lotOrSerial,
    'quantity': quantity,
    'signature_payload': signaturePayload,
    'signature_image': signatureImage,
    'locale': locale,
    if (ceMarkingStandard != null) 'ce_marking_standard': ceMarkingStandard,
    if (replacementDueAt != null)
      'replacement_due_at': _date(replacementDueAt!),
    'handed_over_at': (handedOverAt ?? DateTime.now())
        .toUtc()
        .toIso8601String(),
  };
}

/// A worker who signed a tool-box talk.
class ToolBoxAttendance {
  const ToolBoxAttendance({
    required this.employeeId,
    required this.signaturePayload,
    required this.signedAt,
    this.signatureImage,
  });

  final String employeeId;
  final String signaturePayload;
  final String? signatureImage;
  final DateTime signedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'employee_id': employeeId,
    'signature_payload': signaturePayload,
    'signature_image': signatureImage,
    'signed_at': signedAt.toUtc().toIso8601String(),
  };
}

/// A safety briefing with the signatures collected while the device went from hand to hand.
class ToolBoxTalk {
  const ToolBoxTalk({
    required this.topic,
    required this.conductedAt,
    required this.attendances,
    this.siteOrWorkCenter,
    this.checklistPoints = const <String>[],
    this.supervisorEmployeeId,
  });

  final String topic;
  final String? siteOrWorkCenter;
  final List<String> checklistPoints;
  final String? supervisorEmployeeId;
  final DateTime conductedAt;
  final List<ToolBoxAttendance> attendances;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'topic': topic,
    if (siteOrWorkCenter != null && siteOrWorkCenter!.isNotEmpty)
      'site_or_work_center': siteOrWorkCenter,
    'checklist_points': checklistPoints,
    if (supervisorEmployeeId != null)
      'supervisor_employee_id': supervisorEmployeeId,
    'conducted_at': conductedAt.toUtc().toIso8601String(),
    'attendances': attendances.map((a) => a.toJson()).toList(),
  };
}

/// The 30-second hazard report: what was seen and where.
class NearMissReport {
  const NearMissReport({
    required this.description,
    required this.reportedAt,
    this.siteTag,
    this.latitude,
    this.longitude,
    this.workCenterId,
    this.photos = const <String>[],
  });

  final String description;
  final DateTime reportedAt;

  /// Site or work center the reporter picked.
  final String? siteTag;
  final double? latitude;
  final double? longitude;
  final String? workCenterId;

  /// Base64 JPEG photos of the scene, at most [hseMaxPhotos].
  final List<String> photos;

  /// Where it happened: the site tag, with the coordinates of the phone when they are known.
  String? get location {
    final tag = siteTag?.trim();
    final hasFix = latitude != null && longitude != null;
    final fix = hasFix
        ? '${latitude!.toStringAsFixed(5)},${longitude!.toStringAsFixed(5)}'
        : null;
    if (tag != null && tag.isNotEmpty) return fix == null ? tag : '$tag @ $fix';
    return fix;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'incident_type': 'near_miss',
    'incident_date': reportedAt.toUtc().toIso8601String(),
    'description': description.trim(),
    if (location != null) 'location_or_site_id': location,
    if (workCenterId != null) 'work_center_id': workCenterId,
    if (photos.isNotEmpty) 'photos': photos,
  };
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

/// The content of a worker badge: `EMP:<employee uuid>` (printed as a QR code or stored on the NFC tag).
class HseBadge {
  const HseBadge(this.employeeId);

  final String employeeId;

  /// Null when the code is not a worker badge (a PPE box label or any other tag).
  static HseBadge? parse(String code) {
    final parts = code.trim().split(':');
    if (parts.length != 2 ||
        parts.first.toUpperCase() != 'EMP' ||
        !PpeScan._uuid.hasMatch(parts[1].trim())) {
      return null;
    }
    return HseBadge(parts[1].trim().toLowerCase());
  }
}

/// The text of an NFC Forum "Text" record payload: a status byte (bit 7 = UTF-16, low 6 bits = length of the language code),
/// the language code, then the text. Null for an empty or UTF-16 payload, which a badge never uses.
String? ndefTextFromPayload(List<int> payload) {
  if (payload.isEmpty) return null;
  final status = payload.first;
  if (status & 0x80 != 0) return null;
  final start = 1 + (status & 0x3F);
  if (start > payload.length) return null;
  final text = utf8.decode(payload.sublist(start), allowMalformed: true).trim();
  return text.isEmpty ? null : text;
}

/// Photos of a report are sent inline (the offline queue carries JSON only): at most this many, each a base64 JPEG.
const int hseMaxPhotos = 3;
