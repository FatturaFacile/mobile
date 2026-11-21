import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show PlatformException;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import '../models/hse_models.dart';

/// The platform side of the HSE capture screens: the camera, the NFC reader and the position of the phone. The screens only
/// know the hooks ([HseDeviceServices.locate], [HseDeviceServices.takePhoto], [HseDeviceServices.readBadge], [HseDeviceServices.scanCode]);
/// this file is the one place that talks to the plugins, so every failure (permission refused, hardware off, user cancelled)
/// is turned into "no value" and the screen carries on.
class HseDeviceServices {
  const HseDeviceServices._();

  /// Position of the phone, or null when location is off, refused or does not answer in 15 seconds.
  static Future<({double latitude, double longitude})?> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on TimeoutException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// A photo taken with the camera as base64 JPEG, reduced to 1600 px and 70 % quality so it stays well under the 3 MB the API
  /// accepts. Null when the user cancels or the camera is refused.
  static Future<String?> takePhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600, imageQuality: 70);
      return file == null ? null : base64Encode(await file.readAsBytes());
    } on PlatformException {
      return null;
    }
  }

  /// Reads a worker badge held to the phone: the text of the first NDEF record (`EMP:<uuid>`). Null when NFC is missing or
  /// switched off, the tag carries no text, or nothing is presented within 30 seconds.
  static Future<String?> readBadge() async {
    try {
      if (await NfcManager.instance.checkAvailability() != NfcAvailability.enabled) return null;
    } on PlatformException {
      return null;
    }

    final read = Completer<String?>();
    await NfcManager.instance.startSession(
      pollingOptions: <NfcPollingOption>{NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        if (!read.isCompleted) read.complete(_badgeText(tag));
        await NfcManager.instance.stopSession();
      },
    );

    return read.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () async {
        await NfcManager.instance.stopSession();
        return null;
      },
    );
  }

  static String? _badgeText(NfcTag tag) {
    final message = Platform.isIOS ? NdefIos.from(tag)?.cachedNdefMessage : NdefAndroid.from(tag)?.cachedNdefMessage;
    for (final record in message?.records ?? const <NdefRecord>[]) {
      final isText = record.typeNameFormat == TypeNameFormat.wellKnown && record.type.length == 1 && record.type.first == 0x54;
      final text = isText ? ndefTextFromPayload(record.payload) : utf8.decode(record.payload, allowMalformed: true).trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  /// Full-screen camera scanner for QR codes and barcodes (PPE box labels, worker badges). Returns the first code read.
  static Future<String?> scanCode(BuildContext context) =>
      Navigator.of(context).push<String>(MaterialPageRoute<String>(builder: (_) => const _ScannerPage()));
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: MobileScanner(
      onDetect: (BarcodeCapture capture) {
        final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
        if (_done || code == null) return;
        _done = true;
        Navigator.of(context).pop(code);
      },
    ),
  );
}
