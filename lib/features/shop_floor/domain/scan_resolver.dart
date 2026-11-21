import 'gs1_parser.dart';

/// What a scanned code means on the shop floor.
sealed class ScanResult {
  const ScanResult(this.raw);

  final String raw;
}

/// A production order traveller: `FF:PO:<uuid|order number>` or the bare order number.
final class OrderScan extends ScanResult {
  const OrderScan(super.raw, this.reference);

  final String reference;
}

/// A work centre / machine plate: `FF:WC:<work centre code>`.
final class WorkCenterScan extends ScanResult {
  const WorkCenterScan(super.raw, this.code);

  final String code;
}

/// A raw-material lot label: GS1-128 / DataMatrix with a lot (AI 10) or SSCC, or `FF:LOT:<stock lot uuid>[|<lot number>]`.
final class LotScan extends ScanResult {
  const LotScan(
    super.raw, {
    required this.lotNumber,
    this.lotId,
    this.gtin,
    this.quantity,
  });

  final String lotNumber;

  /// Stock lot id when the label carries it; the API accepts an issue without it.
  final String? lotId;
  final String? gtin;
  final double? quantity;
}

final class UnknownScan extends ScanResult {
  const UnknownScan(super.raw);
}

/// Classifies a scanned string. [knownOrderNumbers] lets a bare order number be recognised without a prefix.
abstract final class ScanResolver {
  static const String _order = 'FF:PO:';
  static const String _workCenter = 'FF:WC:';
  static const String _lot = 'FF:LOT:';
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static ScanResult resolve(
    String input, {
    Iterable<String> knownOrderNumbers = const <String>[],
  }) {
    final String code = input.trim();
    if (code.isEmpty) {
      return UnknownScan(input);
    }
    final String upper = code.toUpperCase();
    if (upper.startsWith(_order)) {
      final String ref = code.substring(_order.length).trim();
      return ref.isEmpty ? UnknownScan(input) : OrderScan(input, ref);
    }
    if (upper.startsWith(_workCenter)) {
      final String ref = code.substring(_workCenter.length).trim();
      return ref.isEmpty ? UnknownScan(input) : WorkCenterScan(input, ref);
    }
    if (upper.startsWith(_lot)) {
      final List<String> parts = code.substring(_lot.length).split('|');
      final String id = parts.first.trim();
      if (!_uuid.hasMatch(id)) {
        return UnknownScan(input);
      }
      final String number = parts.length > 1 && parts[1].trim().isNotEmpty
          ? parts[1].trim()
          : id;
      return LotScan(input, lotNumber: number, lotId: id);
    }
    for (final String number in knownOrderNumbers) {
      if (number.toUpperCase() == upper) {
        return OrderScan(input, number);
      }
    }
    final Gs1Data gs1 = Gs1Parser.parse(code);
    if (!gs1.isEmpty) {
      final String? lot = gs1.lot ?? gs1.sscc;
      if (lot != null) {
        return LotScan(
          input,
          lotNumber: lot,
          gtin: gs1.gtin,
          quantity: gs1.quantity,
        );
      }
    }
    return UnknownScan(input);
  }
}
