import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../data/hse_repository.dart';
import '../l10n/hse_strings.dart';
import '../models/hse_models.dart';

/// Location hook: returns the (latitude, longitude) of the device, or null when it is unknown or refused. The platform
/// plugin is wired in the app shell.
typedef LocationProvider = Future<({double latitude, double longitude})?> Function();

/// Quick near-miss reporter: what and where in a few taps, optionally with the position of the phone. The report is queued on
/// the device first, so it works with no signal on a site. (Photo capture needs an attachment endpoint on the API and is not
/// offered until that exists, so no photo is ever taken and then silently dropped.)
class NearMissScreen extends StatefulWidget {
  const NearMissScreen({super.key, required this.repository, this.locate, this.workCenterId, this.onDone});

  final HseRepository repository;
  final LocationProvider? locate;
  final String? workCenterId;
  final VoidCallback? onDone;

  @override
  State<NearMissScreen> createState() => _NearMissScreenState();
}

class _NearMissScreenState extends State<NearMissScreen> {
  final TextEditingController _what = TextEditingController();
  final TextEditingController _where = TextEditingController();
  ({double latitude, double longitude})? _fix;
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
    if (mounted && fix != null) setState(() => _fix = fix);
  }

  Future<void> _send() async {
    final s = HseStrings.of(context);
    if (_what.text.trim().isEmpty) return setState(() => _message = s.t(H.descriptionRequired));

    setState(() => _saving = true);
    await widget.repository.queueNearMiss(NearMissReport(
      description: _what.text,
      reportedAt: DateTime.now(),
      siteTag: _where.text,
      latitude: _fix?.latitude,
      longitude: _fix?.longitude,
      workCenterId: widget.workCenterId,
    ));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = s.t(H.nearMissQueued);
      _what.clear();
      _fix = null;
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
          TextField(key: const Key('nm-what'), controller: _what, maxLines: 4, decoration: InputDecoration(labelText: s.t(H.nearMissWhat))),
          TextField(key: const Key('nm-where'), controller: _where, decoration: InputDecoration(labelText: s.t(H.nearMissWhere))),
          const SizedBox(height: FfSpace.space3),
          if (widget.locate != null) OutlinedButton(key: const Key('nm-locate'), onPressed: _position, child: Text(s.t(H.useLocation))),
          if (_message != null) Text(_message!, key: const Key('nm-message')),
          const SizedBox(height: FfSpace.space3),
          FilledButton(key: const Key('nm-send'), onPressed: _saving ? null : _send, child: Text(s.t(H.sendReport))),
        ],
      ),
    );
  }
}
