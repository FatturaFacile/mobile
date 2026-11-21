/// Cost Center lookup option (Mod 019) for PR creation.
class CostCenterOption {
  const CostCenterOption({
    required this.id,
    required this.code,
    required this.name,
    this.currency = 'CHF',
  });

  final String id;
  final String code;
  final String name;
  final String currency;

  /// Display label combining code and name.
  String get displayLabel => code.isEmpty ? name : '$code · $name';
}

/// Project lookup option (Domain 09) for optional PR assignment.
class ProjectOption {
  const ProjectOption({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  /// Display label combining code and name.
  String get displayLabel => code.isEmpty ? name : '$code · $name';
}

/// Product / catalog item option used by Catalog Search and Barcode Scan.
class CatalogItemOption {
  const CatalogItemOption({
    required this.id,
    required this.sku,
    required this.name,
    required this.uom,
    required this.unitPrice,
    this.barcode,
  });

  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final String uom;
  final double unitPrice;
}
