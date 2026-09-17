int navigationIndexForDx({
  required double dx,
  required double width,
  required int itemCount,
  required int fallbackIndex,
}) {
  if (width <= 0 || itemCount <= 0) return fallbackIndex;
  final itemWidth = width / itemCount;
  return (dx / itemWidth).floor().clamp(0, itemCount - 1).toInt();
}

double clampNavigationDx(double dx, double width) {
  if (width <= 0) return 0;
  return dx.clamp(0.0, width).toDouble();
}

double navigationIndicatorLeftForDx({
  required double dx,
  required double width,
  required double itemWidth,
  double edgeInset = 5,
}) {
  final indicatorWidth = itemWidth - (edgeInset * 2);
  final minLeft = edgeInset;
  final maxLeft = width - indicatorWidth - edgeInset;
  if (indicatorWidth <= 0 || maxLeft <= minLeft) return minLeft;
  return (dx - indicatorWidth / 2).clamp(minLeft, maxLeft).toDouble();
}
