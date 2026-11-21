import 'package:material_ui/material_ui.dart';

import 'permission_models.dart';
import 'permission_service.dart';

/// Shows [child] only while the user holds [permission]; otherwise [fallback] (nothing by default). Deny by default.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.service,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final PermissionService service;
  final String permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (BuildContext context, Widget? _) =>
          service.isGranted(permission) ? child : fallback,
    );
  }
}

/// A text that follows the field policies: a masked value is shown with a "reserved" marker, a hidden one not at all. The
/// raw figure is never kept: pass the value as received from the API, where the server already masked it.
class MaskedText extends StatelessWidget {
  const MaskedText({
    super.key,
    required this.service,
    required this.resource,
    required this.field,
    required this.value,
    required this.reservedLabel,
    this.style,
  });

  final PermissionService service;
  final String resource;
  final String field;
  final Object? value;

  /// The localized "Reserved" badge text.
  final String reservedLabel;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (BuildContext context, Widget? _) {
        final FieldVisibility visibility = service.visibilityOf(
          resource,
          field,
        );
        final String? text = FieldMask.render(
          value,
          visibility,
          service.kindOf(resource, field),
        );
        if (text == null) {
          return const SizedBox.shrink();
        }
        if (visibility != FieldVisibility.masked) {
          return Text(text, style: style);
        }
        return Tooltip(
          message: reservedLabel,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(text, style: style),
              const SizedBox(width: 6),
              Chip(
                label: Text(reservedLabel),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }
}
