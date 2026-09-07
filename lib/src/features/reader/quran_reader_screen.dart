import 'package:flutter/material.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  String code = 'DİB';

  final translations = const [
    ('DİB', 'Diyanet İşleri Başkanlığı', 'Türkçe'),
    ('KRY', 'Kur’an Yolu', 'Türkçe'),
    ('YAZ', 'Elmalılı Hamdi Yazır', 'Türkçe'),
    ('AZE', 'Azərbaycan dili örneği', 'Azərbaycan dili'),
    ('RUS', 'Русский перевод örneği', 'Русский'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 15, 10),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252424),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _Segment('Bakara 2', _showSurahs),
                      Container(width: 1, height: 48, color: const Color(0xFF111111)),
                      _Segment(code, _showTranslations),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded, size: 30),
                ),
                IconButton(
                  onPressed: _showReaderMenu,
                  icon: const Icon(Icons.more_horiz_rounded, size: 30),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 54, 28, 140),
              children: const [
                Text(
                  'Bakara',
                  style: TextStyle(fontFamily: 'serif', fontSize: 36, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 32),
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'serif', fontSize: 28, height: 2),
                ),
                SizedBox(height: 26),
                _Verse(
                  n: 1,
                  arabic: 'الم',
                  tr: 'Meal metni burada seçilen çeviriden gösterilecek.',
                ),
                _Verse(
                  n: 2,
                  arabic: 'ذَٰلِكَ الْكِتَابُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ',
                  tr: 'Gerçek veri bağlandığında seçtiğiniz meal burada akıcı bir kitap görünümünde yer alacak.',
                ),
                _Verse(
                  n: 3,
                  arabic: 'الَّذِينَ يُؤْمِنُونَ بِالْغَيْبِ وَيُقِيمُونَ الصَّلَاةَ',
                  tr: 'Ayete dokununca kaydetme, not, dinleme, paylaşma, karşılaştırma ve tefsir seçenekleri açılacak.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _Segment(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      );

  void _showReaderMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(130, 90, 18, 0),
      items: const [
        PopupMenuItem(child: ListTile(leading: Icon(Icons.compare_arrows_rounded), title: Text('İlgili İçerik'))),
        PopupMenuItem(child: ListTile(leading: Icon(Icons.text_fields_rounded), title: Text('Yazı Tipleri ve Ayarlar'))),
      ],
    );
  }

  Future<void> _showSurahs() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      builder: (context) => FractionallySizedBox(
        heightFactor: .9,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    const Spacer(),
                    const Text('Sureler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: const [
                    _SurahRow('1', 'Fatiha', 'الفاتحة', '7 ayet'),
                    _SurahRow('2', 'Bakara', 'البقرة', '286 ayet', selected: true),
                    _SurahRow('3', 'Âl-i İmrân', 'آل عمران', '200 ayet'),
                    _SurahRow('4', 'Nisâ', 'النساء', '176 ayet'),
                    _SurahRow('5', 'Mâide', 'المائدة', '120 ayet'),
                    _SurahRow('6', 'En’âm', 'الأنعام', '165 ayet'),
                    _SurahRow('7', 'A’râf', 'الأعراف', '206 ayet'),
                    _SurahRow('8', 'Enfâl', 'الأنفال', '75 ayet'),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Son Okunanlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      SizedBox(height: 10),
                      Text('Bakara 2 · DİB', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTranslations() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      builder: (context) => FractionallySizedBox(
        heightFactor: .82,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mealler', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Meal veya dil ara',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFF292727),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('TÜRKÇE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    children: [
                      for (final t in translations)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context, t.$1),
                          leading: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B3733),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                          title: Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(t.$3),
                          trailing: t.$1 == code
                              ? const Icon(Icons.check_circle, color: Color(0xFF70C9A9))
                              : IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined)),
                        ),
                      const Divider(),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.language),
                        title: Text('Daha Fazla Dil', style: TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('Azərbaycan dili, Русский, English ve diğerleri'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => code = picked);
  }
}

class _Verse extends StatelessWidget {
  const _Verse({required this.n, required this.arabic, required this.tr});
  final int n;
  final String arabic;
  final String tr;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'serif', fontSize: 29, height: 2.05),
              ),
              const SizedBox(height: 12),
              Text(
                tr,
                style: const TextStyle(fontFamily: 'serif', fontSize: 22, height: 1.55),
              ),
              const SizedBox(height: 6),
              Text('2:$n', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
}

class _SurahRow extends StatelessWidget {
  const _SurahRow(this.no, this.name, this.arabic, this.count, {this.selected = false});
  final String no, name, arabic, count;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        color: selected ? const Color(0xFF3B3737) : Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Text(no, style: const TextStyle(color: Colors.white60)),
          title: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          subtitle: Text(count),
          trailing: Text(arabic, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'serif', fontSize: 21)),
        ),
      );
}
