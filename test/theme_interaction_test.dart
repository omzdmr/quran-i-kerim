import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/theme/app_theme.dart';

void main() {
  test('light theme uses restrained ripple press feedback', () {
    expect(AppTheme.light.splashFactory, same(InkRipple.splashFactory));
  });

  test('dark theme uses restrained ripple press feedback', () {
    expect(AppTheme.dark.splashFactory, same(InkRipple.splashFactory));
  });
}
