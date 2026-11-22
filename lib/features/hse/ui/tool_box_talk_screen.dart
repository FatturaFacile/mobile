import 'package:material_ui/material_ui.dart';

import '../../../design/ff_tokens.dart';
import '../data/hse_repository.dart';
import '../l10n/hse_strings.dart';
import '../models/hse_models.dart';
import 'signature_pad.dart';

/// Tool-box talk: the supervisor fills topic, place and checklist points, then passes the device around; each worker types or
/// scans the employee id and signs on glass. Sending queues the briefing with all its signatures as one batch.
class ToolBoxTalkScreen extends StatefulWidget {
  const ToolBoxTalkScreen({
    super.key,
    required this.repository,
    this.supervisorEmployeeId,
    this.onDone,
  });

  final HseRepository repository;
  final String? supervisorEmployeeId;
  final VoidCallback? onDone;

  @override
  State<ToolBoxTalkScreen> createState() => _ToolBoxTalkScreenState();
}

class _ToolBoxTalkScreenState extends State<ToolBoxTalkScreen> {
  final TextEditingController _topic = TextEditingController();
  final TextEditingController _site = TextEditingController();
  final TextEditingController _point = TextEditingController();
  final TextEditingController _worker = TextEditingController();
  final SignatureController _signature = SignatureController();
  final List<String> _points = <String>[];
  final List<ToolBoxAttendance> _signed = <ToolBoxAttendance>[];
  final DateTime _startedAt = DateTime.now();
  String? _message;
  bool _saving = false;

  @override
  void dispose() {
    _topic.dispose();
    _site.dispose();
    _point.dispose();
    _worker.dispose();
    _signature.dispose();
    super.dispose();
  }

  void _addPoint() {
    final text = _point.text.trim();
    if (text.isEmpty) return;
    setState(() => _points.add(text));
    _point.clear();
  }

  /// Stores the signature of the current worker and clears the pad for the next one. A worker who signs twice keeps the first.
  Future<void> _nextWorker() async {
    final s = HseStrings.of(context);
    final id = _worker.text.trim();
    if (id.isEmpty) return setState(() => _message = s.t(H.workerRequired));
    if (_signature.isEmpty)
      return setState(() => _message = s.t(H.signatureRequired));

    final image = await _signature.toPngBase64();
    if (!mounted) return;
    setState(() {
      if (_signed.every((a) => a.employeeId != id)) {
        _signed.add(
          ToolBoxAttendance(
            employeeId: id,
            signaturePayload: _signature.toPayload(),
            signatureImage: image,
            signedAt: DateTime.now(),
          ),
        );
      }
      _worker.clear();
      _signature.clear();
      _message = null;
    });
  }

  Future<void> _finish() async {
    final s = HseStrings.of(context);
    if (_signed.isEmpty) return setState(() => _message = s.t(H.noAttendees));

    setState(() => _saving = true);
    await widget.repository.queueToolBoxTalk(
      ToolBoxTalk(
        topic: _topic.text.trim(),
        siteOrWorkCenter: _site.text.trim(),
        checklistPoints: List<String>.of(_points),
        supervisorEmployeeId: widget.supervisorEmployeeId,
        conductedAt: _startedAt,
        attendances: List<ToolBoxAttendance>.of(_signed),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = s.t(H.briefingQueued);
      _signed.clear();
      _points.clear();
      _topic.clear();
    });
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = HseStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t(H.toolBoxTitle))),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: [
          TextField(
            key: const Key('tbt-topic'),
            controller: _topic,
            decoration: InputDecoration(labelText: s.t(H.topic)),
          ),
          TextField(
            key: const Key('tbt-site'),
            controller: _site,
            decoration: InputDecoration(labelText: s.t(H.siteOrWorkCenter)),
          ),
          const SizedBox(height: FfSpace.space3),
          Text(
            s.t(H.checklistPoints),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final point in _points) Text('• $point'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('tbt-point'),
                  controller: _point,
                  decoration: InputDecoration(labelText: s.t(H.addPoint)),
                ),
              ),
              IconButton(
                key: const Key('tbt-add-point'),
                onPressed: _addPoint,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(height: FfSpace.space6),
          TextField(
            key: const Key('tbt-worker'),
            controller: _worker,
            decoration: InputDecoration(labelText: s.t(H.workerSigns)),
          ),
          const SizedBox(height: FfSpace.space2),
          SignaturePad(controller: _signature),
          Row(
            children: [
              TextButton(
                onPressed: _signature.clear,
                child: Text(s.t(H.clearSignature)),
              ),
              const Spacer(),
              OutlinedButton(
                key: const Key('tbt-next'),
                onPressed: _nextWorker,
                child: Text(s.t(H.nextWorker)),
              ),
            ],
          ),
          Text(
            fill(s.t(H.signedBy), {'count': _signed.length}),
            key: const Key('tbt-count'),
          ),
          if (_message != null) Text(_message!, key: const Key('tbt-message')),
          const SizedBox(height: FfSpace.space3),
          FilledButton(
            key: const Key('tbt-finish'),
            onPressed: _saving ? null : _finish,
            child: Text(s.t(H.finishBriefing)),
          ),
        ],
      ),
    );
  }
}
