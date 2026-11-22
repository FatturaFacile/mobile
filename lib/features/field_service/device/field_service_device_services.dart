import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../hse/device/hse_device_services.dart';
import '../domain/site_navigation.dart';
import '../models/field_service_models.dart';

/// Hook: position of the phone, null when unknown or refused.
typedef FsmLocate = Future<({double latitude, double longitude})?> Function();

/// Hook: a photo taken with the camera and saved on the phone, null when the user cancels or the camera is refused.
typedef FsmTakePhoto = Future<({String localPath, String name})?> Function();

/// Hook: opens the camera scanner and returns the first QR code or barcode read.
typedef FsmScanCode = Future<String?> Function(BuildContext context);

/// Hook: opens the customer site in the navigation app; false when nothing could handle it.
typedef FsmOpenNavigation = Future<bool> Function(FsmSite site, String? label);

/// The platform side of the Field Service screens. The screens only know these hooks (any may be null: the matching button
/// is then hidden), so tests inject fakes and [FieldServiceDeviceServices.live] is the one place that talks to the plugins.
class FieldServiceDeviceHooks {
  const FieldServiceDeviceHooks({
    this.locate,
    this.takePhoto,
    this.scanCode,
    this.openNavigation,
  });

  final FsmLocate? locate;
  final FsmTakePhoto? takePhoto;
  final FsmScanCode? scanCode;
  final FsmOpenNavigation? openNavigation;
}

class FieldServiceDeviceServices {
  const FieldServiceDeviceServices._();

  /// The hooks wired to the real plugins. GPS and the code scanner are shared with the HSE device services.
  static FieldServiceDeviceHooks live() => const FieldServiceDeviceHooks(
    locate: HseDeviceServices.locate,
    takePhoto: takePhoto,
    scanCode: HseDeviceServices.scanCode,
    openNavigation: openNavigation,
  );

  /// Takes a photo (1600 px, 70 % JPEG) and keeps it in the app documents folder until the report is acknowledged.
  static Future<({String localPath, String name})?> takePhoto() async {
    try {
      final XFile? shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 70,
      );
      if (shot == null) return null;
      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory folder = Directory(p.join(docs.path, 'fsm_photos'));
      await folder.create(recursive: true);
      final String name = '${const Uuid().v4()}.jpg';
      final String target = p.join(folder.path, name);
      await shot.saveTo(target);
      return (localPath: target, name: name);
    } on PlatformException {
      return null;
    }
  }

  /// Bytes of a photo saved by [takePhoto], read when the outbox uploads it; null when the file is gone.
  static Future<List<int>?> readPhoto(String path) async {
    final File file = File(path);
    return await file.exists() ? file.readAsBytes() : null;
  }

  /// Opens the site in the navigator: the `geo:` URI first on Android, then the web directions link.
  static Future<bool> openNavigation(FsmSite site, String? label) async {
    final List<Uri> candidates = SiteNavigation.candidates(
      site,
      android: defaultTargetPlatform == TargetPlatform.android,
      label: label,
    );
    for (final Uri uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } on PlatformException {
        // Try the next candidate.
      }
    }
    return false;
  }
}
