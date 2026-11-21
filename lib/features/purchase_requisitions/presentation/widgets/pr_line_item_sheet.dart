import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../../design/ff_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../wms/ui/scan_field.dart' show CameraScanner;
import '../../domain/entities/pr_reference_models.dart';
import '../../domain/entities/purchase_requisition.dart';
import 'pr_labels.dart';

/// Callback to search the offline/online catalog while the line-item bottom sheet is open.
typedef CatalogSearchCallback = Future<List<CatalogItemOption>> Function(
  String query,
);

/// Callback to resolve a scanned barcode or SKU against the catalog.
typedef CatalogBarcodeCallback = Future<CatalogItemOption?> Function(
  String code,
);

/// Fast-entry modal bottom sheet supporting Catalog Search (+ barcode scan) and Free-Text line items.
class PrLineItemSheet extends StatefulWidget {
  const PrLineItemSheet({
    required this.currency,
    required this.onSearchCatalog,
    required this.onLookupBarcode,
    this.cameraScanner,
    this.initialType = PrItemType.catalogItem,
    this.existingLine,
    super.key,
  });

  final PrCurrency currency;
  final CatalogSearchCallback onSearchCatalog;
  final CatalogBarcodeCallback onLookupBarcode;
  final CameraScanner? cameraScanner;
  final PrItemType initialType;
  final PurchaseRequisitionLine? existingLine;

  /// Opens the bottom sheet and returns the constructed [PurchaseRequisitionLine] or `null`.
  static Future<PurchaseRequisitionLine?> show(
    BuildContext context, {
    required PrCurrency currency,
    required CatalogSearchCallback onSearchCatalog,
    required CatalogBarcodeCallback onLookupBarcode,
    CameraScanner? cameraScanner,
    PrItemType initialType = PrItemType.catalogItem,
    PurchaseRequisitionLine? existingLine,
  }) {
    return showModalBottomSheet<PurchaseRequisitionLine>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PrLineItemSheet(
        currency: currency,
        onSearchCatalog: onSearchCatalog,
        onLookupBarcode: onLookupBarcode,
        cameraScanner: cameraScanner,
        initialType: initialType,
        existingLine: existingLine,
      ),
    );
  }

  @override
  State<PrLineItemSheet> createState() => _PrLineItemSheetState();
}

class _PrLineItemSheetState extends State<PrLineItemSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  late PrItemType _itemType;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _uomController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  CatalogItemOption? _selectedCatalogItem;
  List<CatalogItemOption> _catalogResults = <CatalogItemOption>[];
  bool _loadingCatalog = false;
  String? _barcodeError;

  @override
  void initState() {
    super.initState();
    final PurchaseRequisitionLine? existing = widget.existingLine;
    _itemType = existing?.itemType ?? widget.initialType;
    _descriptionController.text = existing?.description ?? '';
    _qtyController.text = existing != null ? _cleanNum(existing.quantity) : '1';
    _priceController.text = existing != null
        ? _cleanNum(existing.unitPrice)
        : '';
    _uomController.text = existing?.uom ?? 'pz';
    _notesController.text = existing?.notes ?? '';
    if (existing?.catalogItemId != null) {
      _selectedCatalogItem = CatalogItemOption(
        id: existing!.catalogItemId!,
        sku: existing.catalogSku ?? '',
        name: existing.description,
        uom: existing.uom,
        unitPrice: existing.unitPrice,
      );
    }
    _runSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _uomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() => _loadingCatalog = true);
    final List<CatalogItemOption> items = await widget.onSearchCatalog(query);
    if (!mounted) {
      return;
    }
    setState(() {
      _catalogResults = items;
      _loadingCatalog = false;
    });
  }

  Future<void> _scanCode([String? overrideCode]) async {
    final String code = (overrideCode ?? _barcodeController.text).trim();
    if (code.isEmpty) {
      return;
    }
    final CatalogItemOption? match = await widget.onLookupBarcode(code);
    if (!mounted) {
      return;
    }
    if (match == null) {
      setState(
        () =>
            _barcodeError = AppLocalizations.of(context)
                .prBarcodeNotFound(code),
      );
      return;
    }
    _barcodeController.clear();
    _selectCatalogItem(match);
  }

  Future<void> _openCamera() async {
    if (widget.cameraScanner == null) {
      return;
    }
    final String? scanned = await widget.cameraScanner!(context);
    if (scanned != null && mounted) {
      await _scanCode(scanned);
    }
  }

  void _selectCatalogItem(CatalogItemOption item) {
    setState(() {
      _selectedCatalogItem = item;
      _barcodeError = null;
      _descriptionController.text = item.name;
      _priceController.text = _cleanNum(item.unitPrice);
      _uomController.text = item.uom;
    });
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final double qty = _parseNumber(_qtyController.text)!;
    final double price = _parseNumber(_priceController.text)!;
    final String notes = _notesController.text.trim();

    final PurchaseRequisitionLine line = PurchaseRequisitionLine(
      localId: widget.existingLine?.localId ?? _uuid.v7(),
      remoteId: widget.existingLine?.remoteId,
      lineNumber: widget.existingLine?.lineNumber ?? 1,
      itemType:
          _itemType == PrItemType.catalogItem && _selectedCatalogItem != null
          ? PrItemType.catalogItem
          : PrItemType.freeText,
      catalogItemId: _itemType == PrItemType.catalogItem
          ? _selectedCatalogItem?.id
          : null,
      catalogSku: _itemType == PrItemType.catalogItem
          ? _selectedCatalogItem?.sku
          : null,
      description: _descriptionController.text.trim(),
      quantity: qty,
      unitPrice: price,
      uom: _uomController.text.trim().isEmpty
          ? 'pz'
          : _uomController.text.trim(),
      notes: notes.isEmpty ? null : notes,
    );

    Navigator.of(context).pop(line);
  }

  @override
  Widget build(BuildContext context) {
    final FfColors colors =
        Theme.of(context).extension<FfColors>() ?? FfColors.light;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final EdgeInsets insets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          FfSpace.space4,
          FfSpace.space4,
          FfSpace.space4,
          FfSpace.space4 + insets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SegmentedButton<PrItemType>(
                key: const Key('pr-line-type-segment'),
                segments: <ButtonSegment<PrItemType>>[
                  ButtonSegment<PrItemType>(
                    value: PrItemType.catalogItem,
                    label: Text(l10n.prLineTypeCatalog),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                  ButtonSegment<PrItemType>(
                    value: PrItemType.freeText,
                    label: Text(l10n.prLineTypeFreeText),
                    icon: const Icon(Icons.edit_note_outlined),
                  ),
                ],
                selected: <PrItemType>{_itemType},
                onSelectionChanged: (Set<PrItemType> selection) {
                  setState(() => _itemType = selection.first);
                },
              ),
              const SizedBox(height: FfSpace.space3),
              if (_itemType == PrItemType.catalogItem) ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        key: const Key('pr-catalog-barcode-input'),
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: l10n.prScanBarcodeAction,
                          prefixIcon: const Icon(Icons.qr_code_scanner),
                          border: const OutlineInputBorder(),
                          errorText: _barcodeError,
                        ),
                        onSubmitted: (_) => _scanCode(),
                      ),
                    ),
                    if (widget.cameraScanner != null)
                      IconButton(
                        key: const Key('pr-catalog-camera-button'),
                        tooltip: l10n.prScanBarcodeAction,
                        onPressed: _openCamera,
                        icon: const Icon(Icons.photo_camera_outlined),
                      ),
                    const SizedBox(width: FfSpace.space2),
                    OutlinedButton(
                      key: const Key('pr-catalog-barcode-submit'),
                      onPressed: _scanCode,
                      child: Text(l10n.prScanBarcodeAction),
                    ),
                  ],
                ),
                const SizedBox(height: FfSpace.space2),
                TextField(
                  key: const Key('pr-catalog-search-input'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.prCatalogSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _runSearch,
                ),
                const SizedBox(height: FfSpace.space2),
                if (_loadingCatalog)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: FfSpace.space2),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_catalogResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: FfSpace.space2,
                    ),
                    child: Text(
                      l10n.prCatalogEmpty,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FfFont.sm,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _catalogResults.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: colors.borderSubtle),
                      itemBuilder: (BuildContext context, int index) {
                        final CatalogItemOption item = _catalogResults[index];
                        final bool selected =
                            _selectedCatalogItem?.id == item.id;
                        return ListTile(
                          key: Key('pr-catalog-item-${item.id}'),
                          dense: true,
                          selected: selected,
                          selectedTileColor: colors.selected,
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item.sku} · ${PrLabels.formatAmount(context, item.unitPrice, widget.currency)} / ${item.uom}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: FfFont.xs,
                            ),
                          ),
                          trailing: selected
                              ? Icon(Icons.check_circle, color: colors.primary)
                              : null,
                          onTap: () => _selectCatalogItem(item),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: FfSpace.space3),
              ],
              TextFormField(
                key: const Key('pr-line-description-input'),
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.prLineDescriptionLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? l10n.prFieldRequired
                    : null,
              ),
              const SizedBox(height: FfSpace.space3),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      key: const Key('pr-line-qty-input'),
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.prLineQuantityLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (String? v) =>
                          _validatePositiveNumber(l10n, v, allowZero: false),
                    ),
                  ),
                  const SizedBox(width: FfSpace.space2),
                  Expanded(
                    child: TextFormField(
                      key: const Key('pr-line-price-input'),
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${l10n.prLineUnitPriceLabel} (${widget.currency.wireValue})',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (String? v) =>
                          _validatePositiveNumber(l10n, v, allowZero: true),
                    ),
                  ),
                  const SizedBox(width: FfSpace.space2),
                  SizedBox(
                    width: 84,
                    child: TextFormField(
                      key: const Key('pr-line-uom-input'),
                      controller: _uomController,
                      decoration: InputDecoration(
                        labelText: l10n.prLineUomLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (String? v) => (v == null || v.trim().isEmpty)
                          ? l10n.prFieldRequired
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FfSpace.space3),
              TextFormField(
                key: const Key('pr-line-notes-input'),
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.prLineNotesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: FfSpace.space4),
              FilledButton(
                key: const Key('pr-line-add-confirm'),
                onPressed: _confirm,
                child: Text(l10n.prLineAddConfirm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePositiveNumber(
    AppLocalizations l10n,
    String? raw, {
    required bool allowZero,
  }) {
    if (raw == null || raw.trim().isEmpty) {
      return l10n.prFieldRequired;
    }
    final double? parsed = _parseNumber(raw);
    if (parsed == null) {
      return l10n.prInvalidNumber;
    }
    if (allowZero ? parsed < 0 : parsed <= 0) {
      return l10n.prMustBePositive;
    }
    return null;
  }

  double? _parseNumber(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  String _cleanNum(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
