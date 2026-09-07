import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/plans/plans_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reader/quran_reader_screen.dart';
import '../l10n/app_localizations.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _draggingNavigation = false;

  static const _screens = [
    HomeScreen(),
    QuranReaderScreen(),
    PlansScreen(),
    DiscoverScreen(),
    ProfileScreen(),
  ];

  void _selectTab(int next, {bool haptic = true}) {
    final safe = next.clamp(0, _screens.length - 1).toInt();
    if (safe == _index) return;
    setState(() => _index = safe);
    if (haptic) HapticFeedback.selectionClick();
  }

  int _indexForDx(double dx, double width) {
    if (width <= 0) return _index;
    final itemWidth = width / _screens.length;
    return (dx / itemWidth)
        .floor()
        .clamp(0, _screens.length - 1)
        .toInt();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            // Tek blur katmanı kullanıyoruz. Beş ayrı blur güzel görünür ama eski
            // Android telefonları gereksiz yere sobaya çevirebilir.
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xB82A2A2A)
                    : const Color(0xC9F5F4EF),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: .15)
                      : Colors.white.withValues(alpha: .72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .20 : .10),
                    blurRadius: 26,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final itemWidth = width / _screens.length;

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (details) {
                      setState(() => _draggingNavigation = true);
                      _selectTab(_indexForDx(details.localPosition.dx, width));
                    },
                    onHorizontalDragUpdate: (details) {
                      _selectTab(_indexForDx(details.localPosition.dx, width));
                    },
                    onHorizontalDragEnd: (_) {
                      if (mounted) setState(() => _draggingNavigation = false);
                    },
                    onHorizontalDragCancel: () {
                      if (mounted) setState(() => _draggingNavigation = false);
                    },
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: reduceMotion
                              ? Duration.zero
                              : Duration(milliseconds: _draggingNavigation ? 105 : 260),
                          curve: _draggingNavigation
                              ? Curves.easeOut
                              : Curves.easeOutBack,
                          left: (_index * itemWidth) + 5,
                          top: 5,
                          width: itemWidth - 10,
                          height: 64,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          Colors.white.withValues(alpha: .14),
                                          scheme.surfaceContainerHighest.withValues(alpha: .80),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: .86),
                                          scheme.surfaceContainerHighest.withValues(alpha: .72),
                                        ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: isDark ? .10 : .62),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? .16 : .07),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _navItem(0, Icons.home_outlined, Icons.home_rounded, l10n.navHome),
                            _navItem(1, Icons.menu_book_outlined, Icons.menu_book_rounded, l10n.navQuran),
                            _navItem(
                              2,
                              Icons.library_add_check_outlined,
                              Icons.library_add_check_rounded,
                              l10n.navPlans,
                            ),
                            _navItem(3, Icons.search_rounded, Icons.search_rounded, l10n.navDiscover),
                            _navItem(
                              4,
                              Icons.account_circle_outlined,
                              Icons.account_circle,
                              l10n.navProfile,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _index == index;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Expanded(
      child: _PressScale(
        enabled: !_draggingNavigation,
        onTap: () => _selectTab(index),
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 26,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: selected ? scheme.primary : scheme.onSurface,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({
    required this.child,
    required this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? .94 : 1,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 105),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
