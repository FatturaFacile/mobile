import 'dart:ui' show PlatformDispatcher;

import 'package:material_ui/material_ui.dart';

import 'features/wms/data/wms_repository.dart';
import 'features/wms/ui/wms_app.dart';

/// Connection settings come from build-time defines until a sign-in flow exists:
/// `flutter run --dart-define=API_BASE_URL=https://host --dart-define=API_TOKEN=... --dart-define=TENANT_ID=...`
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
const _token = String.fromEnvironment('API_TOKEN');
const _tenantId = String.fromEnvironment('TENANT_ID');

void main() {
  runApp(
    WmsApp(
      repository: HttpWmsRepository(
        config: ApiConfig(
          baseUrl: _baseUrl,
          token: _token,
          tenantId: _tenantId,
          locale: PlatformDispatcher.instance.locale.languageCode,
        ),
      ),
    ),
  );
}
