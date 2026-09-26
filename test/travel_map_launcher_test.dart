import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_map_launcher.dart';

void main() {
  test('map handoff preserves non-Latin meeting point address', () {
    const launcher = TravelMapLauncher();
    final uri = launcher.uriForAddress('北京市 朝阳区');
    expect(uri.toString(), contains(Uri.encodeComponent('北京市 朝阳区')));
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      expect(uri.host, 'www.openstreetmap.org');
    }
  });

  test('blank address is rejected before platform handoff', () {
    const launcher = TravelMapLauncher();
    expect(() => launcher.uriForAddress('   '), throwsArgumentError);
  });
}