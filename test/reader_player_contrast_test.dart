import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/theme/app_theme.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('reader quick player keeps strong contrast in light theme', () {
    final scheme = AppTheme.light.colorScheme;

    expect(
      _contrastRatio(scheme.surfaceContainerHigh, scheme.onSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.primary, scheme.onPrimary),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('reader quick player keeps strong contrast in dark theme', () {
    final scheme = AppTheme.dark.colorScheme;

    expect(
      _contrastRatio(scheme.surfaceContainerHigh, scheme.onSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(scheme.primary, scheme.onPrimary),
      greaterThanOrEqualTo(4.5),
    );
  });
}
