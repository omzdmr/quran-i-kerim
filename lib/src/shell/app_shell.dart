import 'dart:ui';
import 'package:flutter/material.dart';
import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/plans/plans_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reader/quran_reader_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    QuranReaderScreen(),
    PlansScreen(),
    DiscoverScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xE82A2A2A)
                    : const Color(0xEEF3F2ED),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: scheme.outline.withValues(alpha: .72)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .16 : .08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Ana Sayfa'),
                  _navItem(1, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Kuran'),
                  _navItem(
                    2,
                    Icons.library_add_check_outlined,
                    Icons.library_add_check_rounded,
                    'Planlar',
                  ),
                  _navItem(3, Icons.search_rounded, Icons.search_rounded, 'Keşfedin'),
                  _navItem(
                    4,
                    Icons.account_circle_outlined,
                    Icons.account_circle,
                    'Siz',
                  ),
                ],
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

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
            borderRadius: BorderRadius.circular(29),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 26,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? scheme.primary : scheme.onSurface,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
