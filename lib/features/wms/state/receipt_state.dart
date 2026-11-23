import 'package:flutter/foundation.dart';

import '../data/wms_repository.dart';
import '../models/transfer.dart';

/// Outcome the backend will reach for a given receipt (used for the live preview).
enum ReceiptOutcome { received, discrepancyPending, partiallyReceived }

/// Why a line entry is not acceptable.
enum LineIssue { negative, exceedsOutstanding }

/// Receipt entry of one transfer line. Immutable; edits return a new instance.
@immutable
class ReceiptLineDraft {
  const ReceiptLineDraft({
    required this.line,
    this.scanned = false,
    this.good = 0,
    this.damaged = 0,
    this.reason = '',
  });

  final TransferLine line;
  final bool scanned;
  final double good;
  final double damaged;
  final String reason;

  double get outstanding => line.outstandingQty;

  /// Quantity neither received in good condition nor reported damaged; never negative.
  double get shortage {
    final value = roundQty(outstanding - good - damaged);
    return value < 0 ? 0 : value;
  }

  LineIssue? get issue {
    if (good < 0 || damaged < 0) return LineIssue.negative;
    if (roundQty(good + damaged) > outstanding) {
      return LineIssue.exceedsOutstanding;
    }
    return null;
  }

  bool get isValid => issue == null;

  bool get hasDiscrepancy => shortage > 0 || damaged > 0;

  ReceiptLineDraft copyWith({
    bool? scanned,
    double? good,
    double? damaged,
    String? reason,
  }) => ReceiptLineDraft(
    line: line,
    scanned: scanned ?? this.scanned,
    good: good ?? this.good,
    damaged: damaged ?? this.damaged,
    reason: reason ?? this.reason,
  );
}

/// Pure state of the step 2 (receipt) form for a whole transfer.
@immutable
class ReceiptDraft {
  const ReceiptDraft({required this.lines, this.partial = false});

  /// Builds a draft for the lines that still have something outstanding.
  factory ReceiptDraft.forTransfer(Transfer transfer) => ReceiptDraft(
    lines: transfer.lines
        .where((l) => l.outstandingQty > 0)
        .map((l) => ReceiptLineDraft(line: l))
        .toList(),
  );

  final List<ReceiptLineDraft> lines;

  /// "Partial receipt" switch: the rest of the goods is still on its way, so the API gets final=false.
  final bool partial;

  bool get finalReceipt => !partial;

  bool get allScanned => lines.isNotEmpty && lines.every((l) => l.scanned);

  bool get allValid => lines.every((l) => l.isValid);

  /// Shortage of the lines already scanned; unscanned lines have no quantities entered yet.
  double get totalShortage => roundQty(
    lines.where((l) => l.scanned).fold(0.0, (sum, l) => sum + l.shortage),
  );

  double get totalDamaged =>
      roundQty(lines.fold(0.0, (sum, l) => sum + l.damaged));

  /// Confirm is allowed when every line was scanned and every quantity is consistent.
  bool get canSubmit => allScanned && allValid;

  /// Status the backend will assign. A final receipt with shortage or damage needs manager approval.
  ReceiptOutcome get expectedOutcome {
    if (partial) return ReceiptOutcome.partiallyReceived;
    if (totalShortage > 0 || totalDamaged > 0) {
      return ReceiptOutcome.discrepancyPending;
    }
    return ReceiptOutcome.received;
  }

  int indexOfLine(String lineId) =>
      lines.indexWhere((l) => l.line.id == lineId);

  /// Marks the line as scanned and, the first time, pre-fills the good quantity with the outstanding one.
  ReceiptDraft markScanned(String lineId) {
    final i = indexOfLine(lineId);
    if (i < 0) return this;
    final current = lines[i];
    final updated = current.scanned
        ? current
        : current.copyWith(
            scanned: true,
            good: current.outstanding,
            damaged: 0,
          );
    return _replace(i, updated);
  }

  ReceiptDraft setGood(String lineId, double value) =>
      _edit(lineId, (l) => l.copyWith(good: value));

  ReceiptDraft setDamaged(String lineId, double value) =>
      _edit(lineId, (l) => l.copyWith(damaged: value));

  ReceiptDraft setReason(String lineId, String value) =>
      _edit(lineId, (l) => l.copyWith(reason: value));

  ReceiptDraft withPartial(bool value) =>
      ReceiptDraft(lines: lines, partial: value);

  List<ReceiptLineInput> toInputs() => lines
      .map(
        (l) => ReceiptLineInput(
          lineId: l.line.id,
          receivedQty: l.good,
          damagedQty: l.damaged,
          reason: l.hasDiscrepancy ? l.reason : null,
        ),
      )
      .toList(growable: false);

  ReceiptDraft _edit(
    String lineId,
    ReceiptLineDraft Function(ReceiptLineDraft) change,
  ) {
    final i = indexOfLine(lineId);
    return i < 0 ? this : _replace(i, change(lines[i]));
  }

  ReceiptDraft _replace(int index, ReceiptLineDraft line) {
    final next = [...lines]..[index] = line;
    return ReceiptDraft(lines: next, partial: partial);
  }
}

/// Parses a quantity typed by the operator (accepts comma as decimal separator); empty means 0.
double? parseQuantityInput(String raw) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return 0;
  return double.tryParse(text);
}

enum ReceiptPhase { idle, scanning, submitting, submitted }

/// Drives the receipt screen: scans lines, edits quantities and posts the receipt.
class ReceiptController extends ChangeNotifier {
  ReceiptController({required this.repository, required Transfer transfer})
    : _transfer = transfer,
      _draft = ReceiptDraft.forTransfer(transfer);

  final WmsRepository repository;
  final Transfer _transfer;
  ReceiptDraft _draft;
  ReceiptPhase _phase = ReceiptPhase.idle;
  String? _error;
  Transfer? _result;

  Transfer get transfer => _transfer;
  ReceiptDraft get draft => _draft;
  ReceiptPhase get phase => _phase;
  String? get error => _error;

  /// The transfer returned by the API after a successful receipt (carries the new status).
  Transfer? get result => _result;

  bool get canSubmit =>
      _draft.canSubmit &&
      _phase != ReceiptPhase.submitting &&
      _phase != ReceiptPhase.submitted;

  Future<bool> scan(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || _phase == ReceiptPhase.submitted) return false;
    _phase = ReceiptPhase.scanning;
    _error = null;
    notifyListeners();
    try {
      final scanned = await repository.scan(_transfer.id, trimmed);
      final known = _draft.indexOfLine(scanned.line.id) >= 0;
      _draft = _draft.markScanned(scanned.line.id);
      _phase = ReceiptPhase.idle;
      notifyListeners();
      return known;
    } on ApiException catch (e) {
      _error = e.message;
      _phase = ReceiptPhase.idle;
      notifyListeners();
      return false;
    }
  }

  void setGood(String lineId, double value) =>
      _update(_draft.setGood(lineId, value));

  void setDamaged(String lineId, double value) =>
      _update(_draft.setDamaged(lineId, value));

  void setReason(String lineId, String value) =>
      _update(_draft.setReason(lineId, value));

  void setPartial(bool value) => _update(_draft.withPartial(value));

  Future<bool> submit() async {
    if (!canSubmit) return false;
    _phase = ReceiptPhase.submitting;
    _error = null;
    notifyListeners();
    try {
      _result = await repository.receive(
        _transfer.id,
        finalReceipt: _draft.finalReceipt,
        lines: _draft.toInputs(),
      );
      _phase = ReceiptPhase.submitted;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _phase = ReceiptPhase.idle;
      notifyListeners();
      return false;
    }
  }

  void _update(ReceiptDraft next) {
    _draft = next;
    notifyListeners();
  }
}
