import 'package:flutter/foundation.dart';

import '../data/wms_repository.dart';
import '../models/transfer.dart';

enum QueuePhase { idle, loading, loaded, failed }

/// Drives the transfer queue: warehouse selection, direction tab and the list to work through.
class TransferQueueController extends ChangeNotifier {
  TransferQueueController({
    required this.repository,
    String? initialWarehouseId,
  }) : _warehouseId = initialWarehouseId;

  final WmsRepository repository;

  List<Warehouse> _warehouses = const [];
  String? _warehouseId;
  TransferDirection _direction = TransferDirection.outbound;
  List<Transfer> _transfers = const [];
  QueuePhase _phase = QueuePhase.idle;
  String? _error;
  int _requestSeq = 0;

  List<Warehouse> get warehouses => _warehouses;
  String? get warehouseId => _warehouseId;
  TransferDirection get direction => _direction;
  List<Transfer> get transfers => _transfers;
  QueuePhase get phase => _phase;
  String? get error => _error;

  /// Loads the warehouses and, when none is selected yet, picks the first one.
  Future<void> init() async {
    _phase = QueuePhase.loading;
    _error = null;
    notifyListeners();
    try {
      _warehouses = await repository.warehouses();
    } on ApiException catch (e) {
      _fail(e);
      return;
    }
    if (_warehouseId == null && _warehouses.isNotEmpty)
      _warehouseId = _warehouses.first.id;
    await refresh();
  }

  Future<void> selectWarehouse(String id) async {
    if (id == _warehouseId) return;
    _warehouseId = id;
    await refresh();
  }

  Future<void> setDirection(TransferDirection direction) async {
    if (direction == _direction) return;
    _direction = direction;
    await refresh();
  }

  Future<void> refresh() async {
    final warehouse = _warehouseId;
    if (warehouse == null) {
      _transfers = const [];
      _phase = QueuePhase.loaded;
      notifyListeners();
      return;
    }
    final seq = ++_requestSeq;
    _phase = QueuePhase.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await repository.queue(
        warehouseId: warehouse,
        direction: _direction,
      );
      if (seq != _requestSeq) return; // a newer request superseded this one
      _transfers = result;
      _phase = QueuePhase.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      if (seq != _requestSeq) return;
      _fail(e);
    }
  }

  void _fail(ApiException e) {
    _error = e.message;
    _phase = QueuePhase.failed;
    notifyListeners();
  }
}
