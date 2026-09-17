import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/shell/navigation_drag_geometry.dart';

void main() {
  test('navigation index follows horizontal item regions and clamps edges', () {
    expect(
      navigationIndexForDx(
        dx: -50,
        width: 500,
        itemCount: 5,
        fallbackIndex: 2,
      ),
      0,
    );
    expect(
      navigationIndexForDx(
        dx: 249,
        width: 500,
        itemCount: 5,
        fallbackIndex: 2,
      ),
      2,
    );
    expect(
      navigationIndexForDx(
        dx: 800,
        width: 500,
        itemCount: 5,
        fallbackIndex: 2,
      ),
      4,
    );
  });

  test('navigation index falls back for invalid geometry', () {
    expect(
      navigationIndexForDx(
        dx: 20,
        width: 0,
        itemCount: 5,
        fallbackIndex: 3,
      ),
      3,
    );
    expect(
      navigationIndexForDx(
        dx: 20,
        width: 500,
        itemCount: 0,
        fallbackIndex: 3,
      ),
      3,
    );
  });

  test('indicator follows the finger continuously inside a tab', () {
    expect(
      navigationIndicatorLeftForDx(dx: 50, width: 500, itemWidth: 100),
      5,
    );
    expect(
      navigationIndicatorLeftForDx(dx: 75, width: 500, itemWidth: 100),
      30,
    );
    expect(
      navigationIndicatorLeftForDx(dx: 125, width: 500, itemWidth: 100),
      80,
    );
  });

  test('indicator stays inside the navigation rail', () {
    expect(
      navigationIndicatorLeftForDx(dx: -100, width: 500, itemWidth: 100),
      5,
    );
    expect(
      navigationIndicatorLeftForDx(dx: 700, width: 500, itemWidth: 100),
      405,
    );
    expect(clampNavigationDx(-20, 500), 0);
    expect(clampNavigationDx(520, 500), 500);
  });
}
