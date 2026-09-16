class LearnReferenceDefinition {
  const LearnReferenceDefinition({
    required this.id,
    required this.titleKey,
    required this.summaryKey,
    required this.bodyKey,
    this.sourceUrl,
  });

  final String id;
  final String titleKey;
  final String summaryKey;
  final String bodyKey;
  final String? sourceUrl;
}

const LearnReferenceDefinition tanzilTextReference = LearnReferenceDefinition(
  id: 'quran-text-tanzil-v1',
  titleKey: 'learnReferenceTanzilTitleV1',
  summaryKey: 'learnReferenceTanzilSummaryV1',
  bodyKey: 'learnReferenceTanzilBodyV1',
  sourceUrl: 'https://tanzil.net/docs/Text_License',
);

const LearnReferenceDefinition quranEncReference = LearnReferenceDefinition(
  id: 'translations-quranenc-v1',
  titleKey: 'learnReferenceQuranEncTitleV1',
  summaryKey: 'learnReferenceQuranEncSummaryV1',
  bodyKey: 'learnReferenceQuranEncBodyV1',
  sourceUrl: 'https://quranenc.com/en/home/about/terms-and-conditions',
);

const LearnReferenceDefinition learnSourcePolicyReference =
    LearnReferenceDefinition(
      id: 'learn-source-policy-v1',
      titleKey: 'learnReferenceMethodTitleV1',
      summaryKey: 'learnReferenceMethodSummaryV1',
      bodyKey: 'learnReferenceMethodBodyV1',
    );

const List<LearnReferenceDefinition> curatedLearnReferences =
    <LearnReferenceDefinition>[
      tanzilTextReference,
      quranEncReference,
      learnSourcePolicyReference,
    ];
