import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../data/hse_repository.dart';
import '../l10n/hse_strings.dart';
import '../models/hse_models.dart';

/// Location hook: returns the (latitude, longitude) of the device, or null when it is unknown or refused. The platform
/// plugin is wired in the app shell.
typedef LocationProvider =
    Future<({double latitude, double longitude})?> Function();

/// Photo hook: returns a base64 JPEG taken with the camera, or null when the user cancels or the camera is refused.
typedef PhotoCapture = Future<String?> Function();

/// Quick near-miss reporter: what and where in a few taps, optionally with the position of the phone. The report is queued on
/// the device first, so it works with no signal on a site. Up to three photos travel inline with the report (the offline queue
/// carries JSON only) and the API stores them with the incident.
class NearMissScreen extends StatefulWidget {
  const NearMissScreen({
    super.key,
    required this.repository,
    this.locate,
    this.capturePhoto,
    this.workCenterId,
    this.onDone,
  });

  final HseRepository repository;
  final LocationProvider? locate;
  final PhotoCapture? capturePhoto;
  final String? workCenterId;
  final VoidCallback? onDone;

  @override
  State<NearMissScreen> createState() => _NearMissScreenState();
}

class _NearMissScreenState extends State<NearMissScreen> {
  final TextEditingController _what = TextEditingController();
  final TextEditingController _where = TextEditingController();
  ({double latitude, double longitude})? _fix;
  final List<String> _photos = <String>[];
  String? _message;
  bool _saving = false;

  @override
  void dispose() {
    _what.dispose();
    _where.dispose();
    super.dispose();
  }

  Future<void> _position() async {
    final fix = await widget.locate!();
    if (!mounted) return;
    final s = HseStrings.of(context);
    setState(() {
      _fix = fix;
      _message = fix == null
          ? s.t(H.locationUnavailable)
          : fill(s.t(H.locationTagged), {
              'lat': fix.latitude.toStringAsFixed(5),
              'lng': fix.longitude.toStringAsFixed(5),
            });
    });
  }

  Future<void> _addPhoto() async {
    final photo = await widget.capturePhoto!();
    if (mounted && photo != null && _photos.length < hseMaxPhotos)
      setState(() => _photos.add(photo));
  }

  Future<void> _send() async {
    final s = HseStrings.of(context);
    if (_what.text.trim().isEmpty)
      return setState(() => _message = s.t(H.descriptionRequired));

    setState(() => _saving = true);
    await widget.repository.queueNearMiss(
      NearMissReport(
        description: _what.text,
        reportedAt: DateTime.now(),
        siteTag: _where.text,
        latitude: _fix?.latitude,
        longitude: _fix?.longitude,
        workCenterId: widget.workCenterId,
        photos: List<String>.unmodifiable(_photos),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = s.t(H.nearMissQueued);
      _what.clear();
      _fix = null;
      _photos.clear();
    });
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = HseStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t(H.nearMissTitle))),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: [
          TextField(
            key: const Key('nm-what'),
            controller: _what,
            maxLines: 4,
            decoration: InputDecoration(labelText: s.t(H.nearMissWhat)),
          ),
          TextField(
            key: const Key('nm-where'),
            controller: _where,
            decoration: InputDecoration(labelText: s.t(H.nearMissWhere)),
          ),
          const SizedBox(height: FfSpace.space3),
          if (widget.locate != null)
            OutlinedButton(
              key: const Key('nm-locate'),
              onPressed: _position,
              child: Text(s.t(H.useLocation)),
            ),
          if (widget.capturePhoto != null) ...[
            const SizedBox(height: FfSpace.space2),
            OutlinedButton(
              key: const Key('nm-photo'),
              onPressed: _photos.length < hseMaxPhotos ? _addPhoto : null,
              child: Text(s.t(H.addPhoto)),
            ),
            Text(
              fill(s.t(H.photosCount), {
                'count': _photos.length,
                'max': hseMaxPhotos,
              }),
              key: const Key('nm-photos-count'),
            ),
            Wrap(
              spacing: FfSpace.space2,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  Stack(
                    children: [
                      Image.memory(
                        base64Decode(_photos[i]),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          key: Key('nm-photo-remove-$i'),
                          tooltip: s.t(H.removePhoto),
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _photos.removeAt(i)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (_message != null) Text(_message!, key: const Key('nm-message')),
          const SizedBox(height: FfSpace.space3),
          FilledButton(
            key: const Key('nm-send'),
            onPressed: _saving ? null : _send,
            child: Text(s.t(H.sendReport)),
          ),
        ],
      ),
    );
  }
}
