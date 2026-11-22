import '../models/field_service_models.dart';

/// URIs that open the customer site in the phone's navigation app (url_launcher).
abstract final class SiteNavigation {
  static String _coord(double v) => v.toStringAsFixed(6);

  /// `geo:` URI handled by the maps/navigator apps of Android: a pin on the coordinates, or a search for the address.
  /// Null when the site has neither.
  static Uri? geoUri(FsmSite site, {String? label}) {
    if (site.hasCoordinates) {
      final String point =
          '${_coord(site.latitude!)},${_coord(site.longitude!)}';
      final String pin = label == null || label.isEmpty
          ? point
          : '$point(${Uri.encodeComponent(label)})';
      return Uri.parse('geo:$point?q=$pin');
    }
    final String? address = site.address;
    if (address == null || address.isEmpty) return null;
    return Uri.parse('geo:0,0?q=${Uri.encodeQueryComponent(address)}');
  }

  /// Turn-by-turn directions link that every platform opens (Google Maps app or browser).
  static Uri? webUri(FsmSite site) {
    final String? destination = site.hasCoordinates
        ? '${_coord(site.latitude!)},${_coord(site.longitude!)}'
        : (site.address == null || site.address!.isEmpty ? null : site.address);
    if (destination == null) return null;
    return Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': destination,
    });
  }

  /// The URIs to try, best first: `geo:` on Android, then the web link everywhere.
  static List<Uri> candidates(
    FsmSite site, {
    required bool android,
    String? label,
  }) => <Uri>[if (android) ?geoUri(site, label: label), ?webUri(site)];
}
