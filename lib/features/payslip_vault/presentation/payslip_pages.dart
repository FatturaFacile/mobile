import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../design/ff_tokens.dart';
import '../domain/payslip_models.dart';
import 'payslip_controller.dart';
import 'payslip_strings.dart';

/// RBAC module key of the employee confidential vault (own payslips and CU).
const String payslipVaultModule = 'italian_payroll_self';

/// Builds the in-memory PDF viewer; tests override it to avoid the native rasteriser.
final Provider<Widget Function(Uint8List bytes, String title)>
payslipViewerBuilderProvider =
    Provider<Widget Function(Uint8List bytes, String title)>(
      (Ref ref) =>
          (Uint8List bytes, String title) =>
              PayslipViewerPage(bytes: bytes, title: title),
    );

String payslipErrorMessage(PayslipStrings s, PayslipException e) =>
    switch (e.kind) {
      PayslipErrorKind.offline => s(PV.errorOffline),
      PayslipErrorKind.unauthorized => s(PV.errorUnauthorized),
      PayslipErrorKind.forbidden => s(PV.errorForbidden),
      PayslipErrorKind.notFound => s(PV.errorNotFound),
      PayslipErrorKind.biometricRequired => s(PV.biometricFailed),
      PayslipErrorKind.unknown => s(PV.errorUnknown),
    };

String _two(int n) => n.toString().padLeft(2, '0');

String _day(DateTime utc) {
  final DateTime l = utc.toLocal();
  return '${l.year}-${_two(l.month)}-${_two(l.day)}';
}

/// In-memory PDF viewer: no temp file, no cache, no print/share actions.
class PayslipViewerPage extends StatelessWidget {
  const PayslipViewerPage({
    required this.bytes,
    required this.title,
    super.key,
  });

  final Uint8List bytes;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: PdfPreview(
      build: (_) async => bytes,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
    ),
  );
}

/// Employee confidential vault: monthly payslips and annual CU, opened behind a biometric check.
class PayslipVaultPage extends ConsumerStatefulWidget {
  const PayslipVaultPage({super.key});

  @override
  ConsumerState<PayslipVaultPage> createState() => _PayslipVaultPageState();
}

class _PayslipVaultPageState extends ConsumerState<PayslipVaultPage> {
  String? _openError;
  bool _opening = false;
  bool _biometric = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      ref.read(payslipListProvider.notifier).load();
      final bool bio = await ref
          .read(payslipOpenerProvider)
          .biometricAvailable();
      if (mounted) {
        setState(() => _biometric = bio);
      }
    });
  }

  Future<void> _open(PayslipEntry entry, PayslipKind kind) async {
    if (_opening) {
      return;
    }
    final PayslipStrings s = PayslipStrings(
      ref.read(requestContextProvider).languageCode,
    );
    final NavigatorState nav = Navigator.of(context);
    final Widget Function(Uint8List, String) viewer = ref.read(
      payslipViewerBuilderProvider,
    );
    setState(() {
      _opening = true;
      _openError = null;
    });
    try {
      final Uint8List bytes = await ref
          .read(payslipOpenerProvider)
          .open(entry, kind, reason: s(PV.biometricReason));
      if (!mounted) {
        return;
      }
      final String title =
          '${kind == PayslipKind.cu ? s(PV.cu) : s(PV.cedolino)} '
          '${entry.year}${kind == PayslipKind.cu ? '' : '-${_two(entry.month)}'}';
      await nav.push<void>(
        MaterialPageRoute<void>(builder: (_) => viewer(bytes, title)),
      );
      // The list shows the new first-opened date.
      await ref.read(payslipListProvider.notifier).load();
    } on PayslipException catch (e) {
      if (mounted) {
        setState(() => _openError = payslipErrorMessage(s, e));
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final PayslipStrings s = PayslipStrings(
      ref.watch(requestContextProvider).languageCode,
    );
    final PayslipListState state = ref.watch(payslipListProvider);
    final ThemeData theme = Theme.of(context);

    final List<PayslipEntry> monthly = <PayslipEntry>[
      for (final PayslipEntry e in state.entries)
        if (e.hasCedolino) e,
    ];
    final Set<int> seenYears = <int>{};
    final List<PayslipEntry> annual = <PayslipEntry>[
      for (final PayslipEntry e in state.entries)
        if (e.hasCu && seenYears.add(e.year)) e,
    ];

    final List<Widget> children = <Widget>[
      Text(s(PV.intro), style: theme.textTheme.bodyMedium),
      const SizedBox(height: FfSpace.space2),
      Text(
        s(PV.auditNotice),
        key: const Key('payslip-audit-notice'),
        style: theme.textTheme.bodySmall,
      ),
      if (!_biometric)
        Padding(
          padding: const EdgeInsets.only(top: FfSpace.space1),
          child: Text(
            s(PV.biometricUnavailableNotice),
            key: const Key('payslip-no-biometric'),
            style: theme.textTheme.bodySmall,
          ),
        ),
      const SizedBox(height: FfSpace.space3),
    ];

    final String? errorText =
        _openError ??
        (state.error == null ? null : payslipErrorMessage(s, state.error!));
    if (errorText != null) {
      children.add(
        Card(
          key: const Key('payslip-error'),
          child: Padding(
            padding: const EdgeInsets.all(FfSpace.space3),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(errorText)),
                TextButton(
                  key: const Key('payslip-retry'),
                  onPressed: () {
                    setState(() => _openError = null);
                    ref.read(payslipListProvider.notifier).load();
                  },
                  child: Text(s(PV.retry)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.loading && state.entries.isEmpty) {
      children.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.all(FfSpace.space5),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else if (state.entries.isEmpty && state.error == null) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(FfSpace.space5),
          child: Center(
            child: Text(s(PV.empty), key: const Key('payslip-empty')),
          ),
        ),
      );
    } else {
      if (monthly.isNotEmpty) {
        children
          ..add(_header(theme, s(PV.monthlyPayslips)))
          ..addAll(
            monthly.map((PayslipEntry e) => _row(s, e, PayslipKind.cedolino)),
          );
      }
      if (annual.isNotEmpty) {
        children
          ..add(_header(theme, s(PV.annualCu)))
          ..addAll(annual.map((PayslipEntry e) => _row(s, e, PayslipKind.cu)));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s(PV.title)),
        actions: <Widget>[
          IconButton(
            key: const Key('payslip-refresh'),
            tooltip: s(PV.refresh),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(payslipListProvider.notifier).load(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FfSpace.space4),
        children: children,
      ),
    );
  }

  Widget _header(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: FfSpace.space3, bottom: FfSpace.space1),
    child: Text(text, style: theme.textTheme.titleSmall),
  );

  Widget _row(PayslipStrings s, PayslipEntry e, PayslipKind kind) {
    final bool cu = kind == PayslipKind.cu;
    final String label = cu ? '${e.year}' : '${e.year}-${_two(e.month)}';
    final StringBuffer sub = StringBuffer();
    if (!cu && e.netAmount != null) {
      sub.write('${s(PV.netAmount)}: ${e.netAmount!.toStringAsFixed(2)}\n');
    }
    sub.write(
      e.firstViewedAt == null
          ? s(PV.neverOpened)
          : '${s(PV.firstOpened)} ${_day(e.firstViewedAt!)}',
    );
    return Card(
      key: Key('payslip-${kind.wire}-${e.distributionId}'),
      child: ListTile(
        leading: Icon(
          cu ? Icons.description_outlined : Icons.receipt_long_outlined,
        ),
        title: Text('${cu ? s(PV.cu) : s(PV.cedolino)} $label'),
        subtitle: Text(sub.toString()),
        isThreeLine: !cu && e.netAmount != null,
        trailing: FilledButton(
          key: Key('payslip-open-${kind.wire}-${e.distributionId}'),
          onPressed: _opening ? null : () => _open(e, kind),
          child: Text(s(PV.open)),
        ),
      ),
    );
  }
}
