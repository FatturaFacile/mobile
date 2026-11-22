import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/field_service_outbox.dart';
import '../data/field_service_repository.dart';
import '../data/field_service_store.dart';
import '../device/field_service_device_services.dart';

/// Who the Field Service data belongs to: the tenant and the technician whose bundle is downloaded.
typedef FieldServiceScope = ({String tenantId, String technicianId});

final Provider<FieldServiceStore> fieldServiceStoreProvider =
    Provider<FieldServiceStore>((Ref ref) {
      final FieldServiceStore store = FieldServiceStore(
        ref.watch(databaseProvider),
      );
      ref.onDispose(store.dispose);
      return store;
    });

final Provider<FieldServiceOutbox> fieldServiceOutboxProvider =
    Provider<FieldServiceOutbox>(
      (Ref ref) => FieldServiceOutbox(
        ref.watch(fieldServiceStoreProvider),
        ref.watch(dioProvider),
        readPhoto: FieldServiceDeviceServices.readPhoto,
      ),
    );

final fieldServiceRepositoryProvider =
    Provider.family<FieldServiceRepository, FieldServiceScope>(
      (Ref ref, FieldServiceScope scope) => LocalFieldServiceRepository(
        store: ref.watch(fieldServiceStoreProvider),
        dio: ref.watch(dioProvider),
        outbox: ref.watch(fieldServiceOutboxProvider),
        tenantId: scope.tenantId,
        technicianId: scope.technicianId,
      ),
    );

/// Camera, GPS, scanner and navigator of the phone; tests override it with fakes.
final Provider<FieldServiceDeviceHooks> fieldServiceDeviceProvider =
    Provider<FieldServiceDeviceHooks>(
      (Ref ref) => FieldServiceDeviceServices.live(),
    );
