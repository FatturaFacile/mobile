import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/shift_repository.dart';

/// Shares the `.ics` file through the system share sheet (any calendar app can import it) and opens Google Calendar in
/// the browser or the app.
class PlatformCalendarExport implements CalendarExportService {
  const PlatformCalendarExport();

  @override
  Future<void> shareIcs({
    required String fileName,
    required String content,
  }) async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(file.path, mimeType: 'text/calendar')]),
    );
  }

  @override
  Future<bool> openGoogleCalendar(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
