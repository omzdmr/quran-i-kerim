import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class TravelMapLauncher {
  const TravelMapLauncher();

  Uri uriForAddress(String address) {
    final query = address.trim();
    if (query.isEmpty) throw ArgumentError.value(address, 'address', 'Address cannot be empty.');
    if (Platform.isIOS || Platform.isMacOS) {
      return Uri.https('maps.apple.com', '/', <String, String>{'q': query});
    }
    if (Platform.isAndroid) {
      return Uri(scheme: 'geo', path: '0,0', queryParameters: <String, String>{'q': query});
    }
    return Uri.https('www.openstreetmap.org', '/search', <String, String>{'query': query});
  }

  Future<bool> openAddress(String address) async {
    final uri = uriForAddress(address);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}