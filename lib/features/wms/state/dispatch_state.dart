import 'package:flutter/foundation.dart';

import '../data/wms_repository.dart';
import '../models/transfer.dart';

/// Pure state of the step 1 (dispatch) checklist: which lines have been scanned.
@immutable
class DispatchChecklist {
  const DispatchChecklist({required this.lines, this.scannedLineIds = const {}});

  final List<TransferLine> lines;
  final Set<String> scannedLineIds;

  bool isScanned(String lineId) => scannedLineIds.contains(lineId);

  int get scannedCount => lines.where((l) => scannedLineIds.contains(l.id)).length;

  /// Dispatch can only be confirmed once every line has been scanned.
  bool get isReady => lines.isNotEmpty && scannedCount == lines.length;

  /// Ticks the line, or returns this checklist unchanged when it is not part of the transfer.
  DispatchChecklist markScanned(String lineId) {
    if (!lines.any((l) => l.id == lineId)) return this;
    return DispatchChecklist(lines: lines, scannedLineIds: {...scannedLineIds, lineId});
  }
}

enum DispatchPhase { idle, scanning, shipping, shipped }

/// Drives the dispatch screen: scans lines through the API and confirms the shipment.
class DispatchController extends ChangeNotifier {
  DispatchController({required this.repository, required Transfer transfer})
      : _transfer = transfer,
        _checklist = DispatchChecklist(lines: transfer.lines);

  final WmsRepository repository;
  Transfer _transfer;
  DispatchChecklist _checklist;
  DispatchPhase _phase = DispatchPhase.idle;
  String? _error;
  TransferLine? _lastScanned;

  Transfer get transfer => _transfer;
  DispatchChecklist get checklist => _checklist;
  DispatchPhase get phase => _phase;
  String? get error => _error;
  TransferLine? get lastScanned => _lastScanned;
  bool get canConfirm => _checklist.isReady && _phase != DispatchPhase.shipping && _phase != DispatchPhase.shipped;

  /// Resolves [code] on the server and ticks the matching line. Returns true on a match.
  Future<bool> scan(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || _phase == DispatchPhase.shipped) return false;
    _phase = DispatchPhase.scanning;
    _error = null;
    notifyListeners();
    try {
      final result = await repository.scan(_transfer.id, trimmed);
      _checklist = _checklist.markScanned(result.line.id);
      _lastScanned = _transfer.lineById(result.line.id) ?? result.line;
      _phase = DispatchPhase.idle;
      notifyListeners();
      return _checklist.isScanned(result.line.id);
    } on ApiException catch (e) {
      _error = e.message;
      _phase = DispatchPhase.idle;
      notifyListeners();
      return false;
    }
  }

  /// Confirms the dispatch. Does nothing while some line is still unscanned.
  Future<bool> confirm([ShipmentInput shipment = const ShipmentInput()]) async {
    if (!canConfirm) return false;
    _phase = DispatchPhase.shipping;
    _error = null;
    notifyListeners();
    try {
      _transfer = await repository.ship(_transfer.id, shipment);
      _phase = DispatchPhase.shipped;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _phase = DispatchPhase.idle;
      notifyListeners();
      return false;
    }
  }
}
