import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a downloaded statement file to the system share sheet (mail, print, save to files...).
abstract interface class StatementExporter {
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

/// Writes the file to the temporary directory and shares it with `share_plus`, as the shift planner does for `.ics`.
class PlatformStatementExporter implements StatementExporter {
  const PlatformStatementExporter();

  @override
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(file.path, mimeType: mimeType)]),
    );
  }
}

/// File name of a statement download: `statement-<customer>-<to>.pdf`, with anything unsafe removed.
String statementFileName(String customerKey, DateTime to, String extension) {
  final String safe = customerKey.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final String date =
      '${to.year.toString().padLeft(4, '0')}${to.month.toString().padLeft(2, '0')}${to.day.toString().padLeft(2, '0')}';
  return 'statement-$safe-$date.$extension';
}
