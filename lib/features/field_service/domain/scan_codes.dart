import '../models/field_service_models.dart';

/// Reads what the technician scans on site: the label of the customer's machine and the label of a spare part.
abstract final class AssetScan {
  /// The serial number inside a scanned asset label: `SN:<serial>`, `ASSET:<serial>` or the bare serial number.
  static String serialOf(String code) {
    final String trimmed = code.trim();
    final int colon = trimmed.indexOf(':');
    if (colon > 0) {
      final String prefix = trimmed.substring(0, colon).toUpperCase();
      if (prefix == 'SN' || prefix == 'ASSET') {
        return trimmed.substring(colon + 1).trim();
      }
    }
    return trimmed;
  }

  /// True when the scanned label is the serial number of [equipment] (case and surrounding spaces are ignored).
  static bool matches(String code, FsmEquipment equipment) {
    final String serial = serialOf(code).toLowerCase();
    return serial.isNotEmpty &&
        serial == equipment.serialNumber.trim().toLowerCase();
  }
}

/// A scanned spare part: the product (uuid or SKU) and, optionally, the lot or serial number printed on the label.
class PartScan {
  const PartScan({required this.key, this.lotNumber});

  /// Product uuid or SKU.
  final String key;

  /// Lot or serial number (the API accepts up to 60 characters).
  final String? lotNumber;

  /// `PART:<product uuid or SKU>[:<lot>]`, or a bare product uuid / SKU. Null for an empty code.
  static PartScan? parse(String code) {
    final String trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final List<String> parts = trimmed.split(':');
    if (parts.length >= 2 && parts.first.toUpperCase() == 'PART') {
      final String key = parts[1].trim();
      if (key.isEmpty) return null;
      final String lot = parts.sublist(2).join(':').trim();
      return PartScan(
        key: key,
        lotNumber: lot.isEmpty
            ? null
            : (lot.length > 60 ? lot.substring(0, 60) : lot),
      );
    }
    return PartScan(key: trimmed);
  }

  /// The van product this label identifies, null when the van does not carry it.
  VanStockItem? resolve(List<VanStockItem> van) {
    final String wanted = key.toLowerCase();
    for (final VanStockItem item in van) {
      if (item.productId.toLowerCase() == wanted ||
          item.sku.toLowerCase() == wanted) {
        return item;
      }
    }
    return null;
  }
}
