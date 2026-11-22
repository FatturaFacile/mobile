import '../models/field_service_models.dart';

/// What a work order's warranty or maintenance contract covers (billed at 0.00), computed on the phone so the technician sees
/// "covered" or "chargeable" on every part with no signal. It mirrors the server `CoveragePolicy`, which stays authoritative
/// when the operation is synced:
///
/// * warranty work orders: everything is covered;
/// * `labor_only`: labor is covered, parts, travel and call-out are chargeable;
/// * `parts_and_labor`: labor and parts are covered, travel and call-out are chargeable;
/// * `preventive_only`: like `parts_and_labor` for preventive work orders, nothing is covered for corrective ones;
/// * `full_comprehensive`: labor, parts, travel and call-out are all covered.
///
/// An inactive or missing contract covers nothing.
class CoveragePolicy {
  const CoveragePolicy();

  bool coversLabor(FsmWorkOrder workOrder) =>
      workOrder.isWarranty || _activeCoverage(workOrder) != null;

  bool coversParts(FsmWorkOrder workOrder) {
    if (workOrder.isWarranty) return true;
    final CoverageType? type = _activeCoverage(workOrder);
    return type == CoverageType.partsAndLabor ||
        type == CoverageType.preventiveOnly ||
        type == CoverageType.fullComprehensive;
  }

  bool coversTravelAndCallout(FsmWorkOrder workOrder) =>
      workOrder.isWarranty ||
      _activeCoverage(workOrder) == CoverageType.fullComprehensive;

  /// The three indicators of a work order at once.
  CoverageSummary summary(FsmWorkOrder workOrder) => CoverageSummary(
    labor: coversLabor(workOrder),
    parts: coversParts(workOrder),
    travelAndCallout: coversTravelAndCallout(workOrder),
    estimated: !workOrder.isWarranty && (workOrder.contract?.assumed ?? false),
  );

  CoverageType? _activeCoverage(FsmWorkOrder workOrder) {
    final ContractCoverage? contract = workOrder.contract;
    if (contract == null || !contract.active) return null;
    if (contract.type == CoverageType.preventiveOnly &&
        workOrder.workType != 'preventive') {
      return null;
    }
    return contract.type;
  }
}

/// The coverage of a work order, per cost item.
class CoverageSummary {
  const CoverageSummary({
    required this.labor,
    required this.parts,
    required this.travelAndCallout,
    this.estimated = false,
  });

  final bool labor;
  final bool parts;
  final bool travelAndCallout;

  /// True when the bundle carried no contract details and the server defaults were assumed.
  final bool estimated;

  bool get coversNothing => !labor && !parts && !travelAndCallout;
}
