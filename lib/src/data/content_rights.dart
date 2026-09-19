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

/// Conservative commercial/ad-supported release gate for translation content.
///
/// Technical availability is not rights evidence. PRODUCT_MASTER_SPEC requires
/// QuranEnc/KFGQPC to remain YELLOW until ad-supported commercial rights are
/// explicit, and per-edition rights remain independently reviewable.
ContentRightsDecision translationRightsFor(TranslationInfo info) {
  switch (info.provider) {
    case TranslationProvider.quranEnc:
      return const ContentRightsDecision(
        status: ContentRightsStatus.yellow,
        evidence:
            'QuranEnc permits download/re-publication under conditions, but explicit ad-supported commercial permission is not recorded.',
        attributionRequired: true,
        updateRequired: true,
        adsAllowed: false,
        redistributionAllowed: true,
        offlineAllowed: true,
      );
    case TranslationProvider.islamicNetwork:
      return const ContentRightsDecision(
        status: ContentRightsStatus.yellow,
        evidence:
            'Per-edition commercial/ad-supported redistribution permission is not recorded.',
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
