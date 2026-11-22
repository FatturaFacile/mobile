import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../../hse/ui/signature_pad.dart';
import '../data/field_service_repository.dart';
import '../device/field_service_device_services.dart';
import '../domain/signature_svg.dart';
import '../l10n/field_service_strings.dart';
import '../models/field_service_models.dart';
import 'part_picker.dart' show formatQuantity;

/// The Rapportino d'Intervento / Servicerapport / Rapport d'intervention / Service Report: work performed, labor and travel
/// hours, km, call-out fee, meter readings, photos, GPS and the customer's signature on glass. Signing seals the report
/// (vector SVG + SHA-256 on the device), completes the work order locally and queues the report; nothing needs a signal.
class ServiceReportPage extends StatefulWidget {
  const ServiceReportPage({
    super.key,
    required this.repository,
    required this.workOrderId,
    this.device = const FieldServiceDeviceHooks(),
    this.clock,
  });

  final FieldServiceRepository repository;
  final String workOrderId;
  final FieldServiceDeviceHooks device;

  /// Test hook for the signing time.
  final DateTime Function()? clock;

  @override
  State<ServiceReportPage> createState() => _ServiceReportPageState();
}

class _ServiceReportPageState extends State<ServiceReportPage> {
  final TextEditingController _summary = TextEditingController();
  final TextEditingController _labor = TextEditingController();
  final TextEditingController _travelHours = TextEditingController();
  final TextEditingController _travelKm = TextEditingController();
  final TextEditingController _meterHours = TextEditingController();
  final TextEditingController _meterCycles = TextEditingController();
  final TextEditingController _signer = TextEditingController();
  final TextEditingController _role = TextEditingController();
  final SignatureController _signature = SignatureController();

  late final Stream<FsmWorkOrderDetail?> _detail = widget.repository
      .watchDetail(widget.workOrderId);
  bool _callout = false;
  bool _draftLoaded = false;
  bool _done = false;
  bool _saving = false;
  double _padWidth = 480;
  ({double latitude, double longitude})? _fix;
  String? _gpsMessage;
  String? _photoMessage;
  Map<String, String> _errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_restoreDraft());
  }

  @override
  void dispose() {
    if (_draftLoaded && !_done) {
      unawaited(widget.repository.saveDraft(widget.workOrderId, _draft()));
    }
    for (final TextEditingController c in <TextEditingController>[
      _summary,
      _labor,
      _travelHours,
      _travelKm,
      _meterHours,
      _meterCycles,
      _signer,
      _role,
    ]) {
      c.dispose();
    }
    _signature.dispose();
    super.dispose();
  }

  Map<String, dynamic> _draft() => <String, dynamic>{
    'summary': _summary.text,
    'labor': _labor.text,
    'travel_hours': _travelHours.text,
    'travel_km': _travelKm.text,
    'callout': _callout,
    'meter_hours': _meterHours.text,
    'meter_cycles': _meterCycles.text,
    'signer': _signer.text,
    'role': _role.text,
  };

  Future<void> _restoreDraft() async {
    final Map<String, dynamic> d = await widget.repository.loadDraft(
      widget.workOrderId,
    );
    if (!mounted) return;
    setState(() {
      _summary.text = '${d['summary'] ?? ''}';
      _labor.text = '${d['labor'] ?? ''}';
      _travelHours.text = '${d['travel_hours'] ?? ''}';
      _travelKm.text = '${d['travel_km'] ?? ''}';
      _callout = d['callout'] == true;
      _meterHours.text = '${d['meter_hours'] ?? ''}';
      _meterCycles.text = '${d['meter_cycles'] ?? ''}';
      _signer.text = '${d['signer'] ?? ''}';
      _role.text = '${d['role'] ?? ''}';
      _draftLoaded = true;
    });
  }

  /// A decimal number typed with a dot or a comma; null when blank, [double.nan] when not a number.
  double? _number(TextEditingController c) {
    final String text = c.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text) ?? double.nan;
  }

  Future<void> _locate() async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final ({double latitude, double longitude})? fix =
        await widget.device.locate!();
    if (!mounted) return;
    setState(() {
      _fix = fix;
      _gpsMessage = fix == null
          ? s.t(FsmText.gpsUnavailable)
          : fill(s.t(FsmText.gpsTagged), <String, Object>{
              'lat': fix.latitude.toStringAsFixed(5),
              'lng': fix.longitude.toStringAsFixed(5),
            });
    });
  }

  Future<void> _addPhoto() async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final ({String localPath, String name})? shot =
        await widget.device.takePhoto!();
    if (!mounted || shot == null) return;
    try {
      await widget.repository.addPhoto(
        widget.workOrderId,
        localPath: shot.localPath,
        name: shot.name,
      );
      if (mounted) setState(() => _photoMessage = null);
    } on FsmException catch (e) {
      if (mounted) {
        setState(
          () => _photoMessage = s.error(
            e.errors.keys.first,
            e.errors.values.first,
          ),
        );
      }
    }
  }

  Future<void> _sign(FsmWorkOrderDetail detail) async {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    final Map<String, String> errors = <String, String>{};

    final double? labor = _number(_labor);
    final double? travelHours = _number(_travelHours);
    final double? travelKm = _number(_travelKm);
    final double? meterHours = _number(_meterHours);
    final double? meterCycles = _number(_meterCycles);
    if (labor == null || labor.isNaN) errors['labor_hours'] = 'required';
    if (travelHours != null && travelHours.isNaN)
      errors['travel_hours'] = 'invalid';
    if (travelKm != null && travelKm.isNaN) errors['travel_km'] = 'invalid';
    if (meterHours != null && meterHours.isNaN)
      errors['meter_reading_hours'] = 'invalid';
    if (meterCycles != null &&
        (meterCycles.isNaN || meterCycles != meterCycles.roundToDouble())) {
      errors['meter_reading_cycles'] = 'invalid';
    }

    final String? svg = SignatureSvg.fromStrokes(
      _signature.strokes,
      width: _padWidth,
    );
    if (svg == null) errors['signature_svg'] = 'required';

    if (errors.isNotEmpty) {
      return setState(() => _errors = errors);
    }

    final ServiceReportDraft draft = ServiceReportDraft(
      workPerformedSummary: _summary.text,
      checklist: detail.checklist,
      laborHours: labor!,
      travelHours: travelHours ?? 0,
      travelKm: travelKm ?? 0,
      applyCalloutFee: _callout,
      meterReadingHours: meterHours,
      meterReadingCycles: meterCycles?.toInt(),
      signerName: _signer.text,
      signerRole: _role.text,
      signatureSvg: svg!,
      signedAt: (widget.clock ?? DateTime.now)(),
      latitude: _fix?.latitude,
      longitude: _fix?.longitude,
      photos: detail.photos,
      locale: s.tag,
    );

    setState(() {
      _saving = true;
      _errors = <String, String>{};
    });
    try {
      await widget.repository.signAndClose(widget.workOrderId, draft);
      _done = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.t(FsmText.reportQueued))));
      Navigator.of(context).pop(true);
    } on FsmException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errors = e.errors;
      });
    }
  }

  String? _fieldError(FieldServiceStrings s, String field) {
    final String? code = _errors[field];
    if (code == null) return null;
    return s.error(field, code);
  }

  @override
  Widget build(BuildContext context) {
    final FieldServiceStrings s = FieldServiceStrings.of(context);
    return StreamBuilder<FsmWorkOrderDetail?>(
      stream: _detail,
      builder: (BuildContext context, AsyncSnapshot<FsmWorkOrderDetail?> snap) {
        final FsmWorkOrderDetail? detail = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(s.t(FsmText.reportTitle))),
          body: detail == null || !_draftLoaded
              ? const Center(child: CircularProgressIndicator())
              : detail.signed
              ? Center(
                  child: Text(
                    s.t(FsmText.alreadySigned),
                    key: const Key('fsm-report-signed'),
                  ),
                )
              : _form(context, s, detail),
        );
      },
    );
  }

  Widget _form(
    BuildContext context,
    FieldServiceStrings s,
    FsmWorkOrderDetail detail,
  ) {
    const Set<String> shownOnFields = <String>{
      'work_performed_summary',
      'labor_hours',
      'travel_hours',
      'travel_km',
      'meter_reading_hours',
      'meter_reading_cycles',
      'customer_signer_name',
      'customer_signer_role',
    };
    final List<String> generalErrors = <String>[
      for (final MapEntry<String, String> e in _errors.entries)
        if (!shownOnFields.contains(e.key)) s.error(e.key, e.value),
    ];
    final double chargeable = detail.parts.fold<double>(
      0,
      (double sum, FsmPartLine p) => sum + p.chargeable,
    );
    final Color errorColor = Theme.of(context).colorScheme.error;

    return ListView(
      padding: const EdgeInsets.all(FfSpace.space4),
      children: <Widget>[
        Text(
          '${detail.workOrder.number} · ${detail.workOrder.title}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: FfSpace.space3),
        TextField(
          key: const Key('fsm-summary'),
          controller: _summary,
          maxLines: 4,
          maxLength: 5000,
          decoration: InputDecoration(
            labelText: s.t(FsmText.workPerformed),
            errorText: _fieldError(s, 'work_performed_summary'),
          ),
        ),
        TextField(
          key: const Key('fsm-labor'),
          controller: _labor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.t(FsmText.laborHours),
            errorText: _fieldError(s, 'labor_hours'),
            suffixText: detail.coverage.labor
                ? s.t(FsmText.covered)
                : s.t(FsmText.chargeable),
          ),
        ),
        TextField(
          key: const Key('fsm-travel-hours'),
          controller: _travelHours,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.t(FsmText.travelHours),
            errorText: _fieldError(s, 'travel_hours'),
          ),
        ),
        TextField(
          key: const Key('fsm-travel-km'),
          controller: _travelKm,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.t(FsmText.travelKm),
            errorText: _fieldError(s, 'travel_km'),
          ),
        ),
        SwitchListTile(
          key: const Key('fsm-callout'),
          contentPadding: EdgeInsets.zero,
          title: Text(s.t(FsmText.applyCallout)),
          subtitle: Text(
            '${s.t(FsmText.calloutFee)} · '
            '${s.t(detail.coverage.travelAndCallout ? FsmText.covered : FsmText.chargeable)}',
          ),
          value: _callout,
          onChanged: (bool v) => setState(() => _callout = v),
        ),
        if (detail.equipment != null) ...<Widget>[
          TextField(
            key: const Key('fsm-meter-hours'),
            controller: _meterHours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.t(FsmText.meterHours),
              helperText: formatQuantity(detail.equipment!.operatingHours),
              errorText: _fieldError(s, 'meter_reading_hours'),
            ),
          ),
          TextField(
            key: const Key('fsm-meter-cycles'),
            controller: _meterCycles,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: s.t(FsmText.meterCycles),
              helperText: '${detail.equipment!.cycleCount}',
              errorText: _fieldError(s, 'meter_reading_cycles'),
            ),
          ),
        ],
        if (detail.parts.isNotEmpty) ...<Widget>[
          const SizedBox(height: FfSpace.space2),
          Text(
            fill(s.t(FsmText.chargeableTotal), <String, Object>{
              'amount': chargeable.toStringAsFixed(2),
            }),
            key: const Key('fsm-parts-total'),
          ),
          Text(
            s.t(FsmText.currencyNote),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: FfSpace.space4),
        Text(
          s.t(FsmText.photosTitle),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.device.takePhoto != null)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('fsm-add-photo'),
              icon: const Icon(Icons.photo_camera),
              onPressed: detail.photos.length < 20 ? _addPhoto : null,
              label: Text(s.t(FsmText.addPhoto)),
            ),
          ),
        Text(
          fill(s.t(FsmText.photosCount), <String, Object>{
            'count': detail.photos.length,
            'max': 20,
          }),
          key: const Key('fsm-photos-count'),
        ),
        if (_photoMessage != null)
          Text(_photoMessage!, style: TextStyle(color: errorColor)),
        for (final ReportPhoto photo in detail.photos)
          ListTile(
            key: Key('fsm-photo-${photo.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined),
            title: Text(photo.name),
            trailing: IconButton(
              key: Key('fsm-photo-remove-${photo.id}'),
              tooltip: s.t(FsmText.removePhoto),
              icon: const Icon(Icons.close),
              onPressed: () =>
                  widget.repository.removePhoto(widget.workOrderId, photo.id),
            ),
          ),
        if (widget.device.locate != null) ...<Widget>[
          OutlinedButton.icon(
            key: const Key('fsm-locate'),
            icon: const Icon(Icons.my_location),
            onPressed: _locate,
            label: Text(s.t(FsmText.gpsTag)),
          ),
          if (_gpsMessage != null)
            Text(_gpsMessage!, key: const Key('fsm-gps-message')),
        ],
        const SizedBox(height: FfSpace.space4),
        TextField(
          key: const Key('fsm-signer'),
          controller: _signer,
          decoration: InputDecoration(
            labelText: s.t(FsmText.signerName),
            errorText: _fieldError(s, 'customer_signer_name'),
          ),
        ),
        TextField(
          key: const Key('fsm-signer-role'),
          controller: _role,
          decoration: InputDecoration(labelText: s.t(FsmText.signerRole)),
        ),
        const SizedBox(height: FfSpace.space3),
        Text(
          s.t(FsmText.signHere),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            _padWidth = box.maxWidth.isFinite ? box.maxWidth : 480;
            return SignaturePad(controller: _signature);
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('fsm-clear-signature'),
            onPressed: _signature.clear,
            child: Text(s.t(FsmText.clearSignature)),
          ),
        ),
        for (var i = 0; i < generalErrors.length; i++)
          Text(
            generalErrors[i],
            key: Key('fsm-error-$i'),
            style: TextStyle(color: errorColor),
          ),
        const SizedBox(height: FfSpace.space3),
        FilledButton(
          key: const Key('fsm-sign'),
          onPressed: _saving ? null : () => _sign(detail),
          child: Text(s.t(FsmText.signAndClose)),
        ),
      ],
    );
  }
}
