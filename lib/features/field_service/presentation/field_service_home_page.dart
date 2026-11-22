import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../data/field_service_repository.dart';
import 'field_service_providers.dart';
import 'work_queue_page.dart';

/// RBAC module keys that open the technician work queue.
const Set<String> fieldServiceModules = <String>{
  'field_service',
  'field_service_mobile',
  'fsm_technician',
  'service_technician',
};

/// Entry point of the module: the offline work queue wired to the local store, the sync outbox and the phone hardware.
/// While it is open the queue is flushed when the connection comes back and every [syncEvery].
class FieldServiceHomePage extends ConsumerStatefulWidget {
  const FieldServiceHomePage({
    required this.tenantId,
    required this.technicianId,
    this.syncEvery = const Duration(minutes: 2),
    super.key,
  });

  final String tenantId;

  /// The `service_technicians.id` of the signed-in technician.
  final String technicianId;
  final Duration syncEvery;

  @override
  ConsumerState<FieldServiceHomePage> createState() =>
      _FieldServiceHomePageState();
}

class _FieldServiceHomePageState extends ConsumerState<FieldServiceHomePage> {
  Timer? _timer;

  FieldServiceRepository get _repository => ref.read(
    fieldServiceRepositoryProvider((
      tenantId: widget.tenantId,
      technicianId: widget.technicianId,
    )),
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      widget.syncEvery,
      (_) => unawaited(_repository.sync()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (
      AsyncValue<bool>? previous,
      AsyncValue<bool> next,
    ) {
      if (next.value == true && previous?.value != true) {
        unawaited(_repository.sync());
      }
    });
    return WorkQueuePage(
      repository: ref.watch(
        fieldServiceRepositoryProvider((
          tenantId: widget.tenantId,
          technicianId: widget.technicianId,
        )),
      ),
      device: ref.watch(fieldServiceDeviceProvider),
    );
  }
}
