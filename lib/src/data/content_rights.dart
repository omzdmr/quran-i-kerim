import 'translation_catalog.dart';

enum ContentRightsStatus { green, yellow, blocked }

class ContentRightsDecision {
  const ContentRightsDecision({
    required this.status,
    required this.evidence,
    required this.attributionRequired,
    required this.updateRequired,
    required this.adsAllowed,
    required this.redistributionAllowed,
    required this.offlineAllowed,
  });

  final ContentRightsStatus status;
  final String evidence;
  final bool attributionRequired;
  final bool updateRequired;
  final bool adsAllowed;
  final bool redistributionAllowed;
  final bool offlineAllowed;

  bool get productionAllowed =>
      status == ContentRightsStatus.green &&
      adsAllowed &&
      redistributionAllowed &&
      offlineAllowed;
}

/// Commercial/ad-supported release gate for translation content.
///
/// This is deliberately provider-policy based only where the provider publishes
/// redistribution terms that apply to its translation catalogue. A provider
/// being technically reachable is never treated as permission to redistribute.
ContentRightsDecision translationRightsFor(TranslationInfo info) {
  switch (info.provider) {
    case TranslationProvider.quranEnc:
      return const ContentRightsDecision(
        status: ContentRightsStatus.green,
        evidence: 'https://quranenc.com/en/home/about/terms-and-conditions',
        attributionRequired: true,
        updateRequired: true,
        adsAllowed: true,
        redistributionAllowed: true,
        offlineAllowed: true,
      );
    case TranslationProvider.islamicNetwork:
      return const ContentRightsDecision(
        status: ContentRightsStatus.yellow,
        evidence: 'Per-edition commercial/ad-supported redistribution permission not recorded.',
        attributionRequired: true,
        updateRequired: false,
        adsAllowed: false,
        redistributionAllowed: false,
        offlineAllowed: false,
      );
  }
}

bool translationProductionAllowed(TranslationInfo info) =>
    translationRightsFor(info).productionAllowed;
