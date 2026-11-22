import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;

import '../../../design/ff_tokens.dart';
import '../../../l10n/ff_strings.dart';
import '../data/wms_repository.dart';
import '../models/transfer.dart';
import '../state/dispatch_state.dart';
import '../state/queue_state.dart';
import '../state/receipt_state.dart';
import 'dispatch_screen.dart';
import 'queue_screen.dart';
import 'receipt_screen.dart';
import 'scan_field.dart';

/// Root widget of the warehouse-operator app: queue -> dispatch (step 1) / receipt (step 2).
class WmsApp extends StatelessWidget {
  const WmsApp({
    super.key,
    required this.repository,
    this.cameraScanner,
    this.locale,
  });

  final WmsRepository repository;
  final CameraScanner? cameraScanner;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fattura Facile',
      theme: ffThemeData(),
      darkTheme: ffThemeData(brightness: Brightness.dark),
      locale: locale,
      supportedLocales: FfStrings.supportedLocales,
      localizationsDelegates: const [
        FfStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: WmsHome(repository: repository, cameraScanner: cameraScanner),
    );
  }
}

/// Owns the queue controller and pushes the dispatch / receipt screens.
class WmsHome extends StatefulWidget {
  const WmsHome({super.key, required this.repository, this.cameraScanner});

  final WmsRepository repository;
  final CameraScanner? cameraScanner;

  @override
  State<WmsHome> createState() => _WmsHomeState();
}

class _WmsHomeState extends State<WmsHome> {
  late final TransferQueueController _queue = TransferQueueController(
    repository: widget.repository,
  );

  @override
  void dispose() {
    _queue.dispose();
    super.dispose();
  }

  Future<void> _open(Transfer listed, TransferDirection direction) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final strings = FfStrings.of(context);
    Transfer fresh;
    try {
      fresh = await widget.repository.transfer(listed.id);
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.message.isEmpty ? strings.t(L.unexpectedError) : e.message,
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => direction == TransferDirection.outbound
            ? _DispatchRoute(
                repository: widget.repository,
                transfer: fresh,
                cameraScanner: widget.cameraScanner,
              )
            : _ReceiptRoute(
                repository: widget.repository,
                transfer: fresh,
                cameraScanner: widget.cameraScanner,
              ),
      ),
    );
    await _queue.refresh();
  }

  @override
  Widget build(BuildContext context) =>
      QueueScreen(controller: _queue, onOpen: _open);
}

class _DispatchRoute extends StatefulWidget {
  const _DispatchRoute({
    required this.repository,
    required this.transfer,
    this.cameraScanner,
  });

  final WmsRepository repository;
  final Transfer transfer;
  final CameraScanner? cameraScanner;

  @override
  State<_DispatchRoute> createState() => _DispatchRouteState();
}

class _DispatchRouteState extends State<_DispatchRoute> {
  late final DispatchController _controller = DispatchController(
    repository: widget.repository,
    transfer: widget.transfer,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DispatchScreen(
    controller: _controller,
    cameraScanner: widget.cameraScanner,
    onDone: () => Navigator.of(context).pop(),
  );
}

class _ReceiptRoute extends StatefulWidget {
  const _ReceiptRoute({
    required this.repository,
    required this.transfer,
    this.cameraScanner,
  });

  final WmsRepository repository;
  final Transfer transfer;
  final CameraScanner? cameraScanner;

  @override
  State<_ReceiptRoute> createState() => _ReceiptRouteState();
}

class _ReceiptRouteState extends State<_ReceiptRoute> {
  late final ReceiptController _controller = ReceiptController(
    repository: widget.repository,
    transfer: widget.transfer,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ReceiptScreen(
    controller: _controller,
    cameraScanner: widget.cameraScanner,
    onDone: () => Navigator.of(context).pop(),
  );
}
