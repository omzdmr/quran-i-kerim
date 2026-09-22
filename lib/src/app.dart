import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/onboarding/presentation/onboarding_app_root.dart';
import 'features/prayer/application/prayer_schedule_auto_repair.dart';
import 'l10n/app_localizations.dart';
import 'l10n/generated/generated_app_localizations.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

class QuranModernApp extends StatefulWidget {
  const QuranModernApp({required this.settings, this.prayerScheduleRepair, super.key});
  final AppSettings settings;
  final PrayerScheduleAutoRepair? prayerScheduleRepair;
  @override
  State<QuranModernApp> createState() => _QuranModernAppState();
}

class _QuranModernAppState extends State<QuranModernApp> with WidgetsBindingObserver {
  static const _defaultPrayerScheduleRepair = PrayerScheduleAutoRepair();
  bool _repairRunning = false;
  bool _repairRequested = false;
  String? _observedLocaleCode;
  PrayerScheduleAutoRepair get _prayerScheduleRepair => widget.prayerScheduleRepair ?? _defaultPrayerScheduleRepair;

  @override
  void initState() {
    super.initState();
    _observedLocaleCode = widget.settings.locale?.languageCode;
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _repairPrayerSchedule());
  }

  @override
  void didUpdateWidget(covariant QuranModernApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.removeListener(_onSettingsChanged);
      widget.settings.addListener(_onSettingsChanged);
      _observedLocaleCode = widget.settings.locale?.languageCode;
      _repairPrayerSchedule();
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onSettingsChanged() {
    final localeCode = widget.settings.locale?.languageCode;
    if (localeCode == _observedLocaleCode) return;
    _observedLocaleCode = localeCode;
    // Notification titles are localized and locale participates in the prayer
    // schedule fingerprint, so language changes need an immediate recheck.
    _repairPrayerSchedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _repairPrayerSchedule();
  }

  Future<void> _repairPrayerSchedule() async {
    if (_repairRunning) {
      _repairRequested = true;
      return;
    }
    _repairRunning = true;
    try {
      await _prayerScheduleRepair.repairIfNeeded();
    } catch (_) {
      // App startup/settings remain usable. Diagnostics retains the local
      // failure receipt and explicit retry path.
    } finally {
      _repairRunning = false;
      if (_repairRequested && mounted) {
        _repairRequested = false;
        _repairPrayerSchedule();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) => AppSettingsScope(
        settings: widget.settings,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => GeneratedAppLocalizations.of(context)!.appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: widget.settings.themeMode,
          locale: widget.settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: (deviceLocales, supportedLocales) {
            if (widget.settings.locale != null) return widget.settings.locale;
            for (final deviceLocale in deviceLocales ?? const <Locale>[]) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale.languageCode) return supported;
              }
            }
            return const Locale('en');
          },
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final currentScale = mediaQuery.textScaler.scale(16) / 16;
            final minimumScale = widget.settings.minimumInterfaceTextScale;
            if (minimumScale <= 1 || currentScale >= minimumScale) return child ?? const SizedBox.shrink();
            return MediaQuery(data: mediaQuery.copyWith(textScaler: TextScaler.linear(minimumScale)), child: child ?? const SizedBox.shrink());
          },
          localizationsDelegates: const [GeneratedAppLocalizations.delegate, AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          home: OnboardingAppRoot(settings: widget.settings),
        ),
      ),
    );
  }
}
