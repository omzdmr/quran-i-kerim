import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/strings/qada_fasting_strings.dart';
import '../../navigation/app_navigation.dart';
import '../prayer/application/prayer_calculation_explanation_loader.dart';
import '../prayer/presentation/prayer_calculation_inspector_sheet.dart';
import '../prayer/presentation/prayer_screen.dart';
import '../prayer/presentation/qibla_launcher_screen.dart';
import '../profile/downloads_screen.dart';
import 'dhikr_counter_screen.dart';
import 'qada_fasting_screen.dart';
import 'travel_tools_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    void push(Widget screen) {
      HapticFeedback.selectionClick();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    Future<void> openPrayerCalculationDetails() async {
      HapticFeedback.selectionClick();
      final explanation = await PrayerCalculationExplanationLoader.load();
      if (!context.mounted) return;
      await showPrayerCalculationInspector(context: context, explanation: explanation);
    }

    void openPlans() { HapticFeedback.selectionClick(); AppNavigation.instance.openPlans(); }
    void openQuran() { HapticFeedback.selectionClick(); AppNavigation.instance.openQuran(); }

    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20,44,20,120), children: [
      Text(l10n.text('discoverTitle'), style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height:26),
      _PrayerFeatureCard(onTap:()=>push(const PrayerScreen()),title:l10n.text('prayerTimes'),subtitle:l10n.text('prayerSubtitle')), const SizedBox(height:12),
      _Shortcut(Icons.calculate_outlined,l10n.text('calculationMethod'),onTap:openPrayerCalculationDetails), const SizedBox(height:12),
      _Shortcut(Icons.explore_outlined,l10n.text('qibla'),onTap:()=>push(const QiblaLauncherScreen())), const SizedBox(height:12),
      _Shortcut(Icons.touch_app_outlined,l10n.text('dhikrCounter'),onTap:()=>push(const DhikrCounterScreen())), const SizedBox(height:12),
      _Shortcut(Icons.event_repeat_rounded,qadaFastingText(locale,'title'),onTap:()=>push(const QadaFastingScreen())), const SizedBox(height:12),
      _Shortcut(Icons.luggage_outlined,_travelLabels[locale]??_travelLabels['en']!,onTap:()=>push(const TravelToolsScreen())), const SizedBox(height:12),
      Row(children:[Expanded(child:_Shortcut(Icons.library_add_check_outlined,l10n.text('readingPlans'),onTap:openPlans)),const SizedBox(width:12),Expanded(child:_Shortcut(Icons.menu_book_outlined,l10n.text('verses'),onTap:openQuran))]), const SizedBox(height:12),
      _Shortcut(Icons.headphones_outlined,l10n.text('audioQuran'),onTap:()=>push(const DownloadsScreen())),
    ]));
  }
}

const _travelLabels=<String,String>{'tr':'Seyahat araçları','en':'Travel tools','fr':'Outils de voyage','ar':'أدوات السفر','az':'Səyahət alətləri','ru':'Инструменты поездки'};

class _PrayerFeatureCard extends StatelessWidget {
  const _PrayerFeatureCard({required this.onTap,required this.title,required this.subtitle});
  final VoidCallback onTap; final String title,subtitle;
  @override Widget build(BuildContext context){final scheme=Theme.of(context).colorScheme;return Material(color:scheme.surfaceContainer,borderRadius:BorderRadius.circular(24),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(24),child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:scheme.primaryContainer,borderRadius:BorderRadius.circular(16)),child:Icon(Icons.schedule_rounded,color:scheme.primary)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(subtitle,style:Theme.of(context).textTheme.bodyMedium?.copyWith(color:scheme.onSurfaceVariant))])),Icon(Icons.chevron_right_rounded,color:scheme.onSurfaceVariant)]))));}
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon,this.label,{required this.onTap}); final IconData icon; final String label; final VoidCallback onTap;
  @override Widget build(BuildContext context){final scheme=Theme.of(context).colorScheme;return Semantics(button:true,label:label,onTap:onTap,child:ExcludeSemantics(child:Material(color:scheme.surfaceContainer,borderRadius:BorderRadius.circular(18),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:18),child:Row(children:[Icon(icon,color:scheme.primary),const SizedBox(width:12),Expanded(child:Text(label,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w700)))]))))));}
}
