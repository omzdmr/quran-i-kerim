import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: .62);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
            child: Row(
              children: [
                _Tab('Bugün', 0),
                const SizedBox(width: 28),
                _Tab('Topluluk', 1),
              ],
            ),
          ),
          Expanded(
            child: tab == 0
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Günaydın',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const Icon(Icons.bolt_outlined, size: 30),
                          const SizedBox(width: 3),
                          const Text('12', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 18),
                          const Icon(Icons.notifications_none_rounded, size: 30),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _VerseCard(muted: muted),
                      const SizedBox(height: 18),
                      _InfoCard(
                        eyebrow: 'Hoş geldiniz',
                        title: 'Kuran ile bağlantı kurmanın dört yolunu keşfedelim.',
                        button: 'Devam',
                        trailing: _RoundBadge('1 / 4'),
                      ),
                      const SizedBox(height: 18),
                      _InfoCard(
                        eyebrow: 'Bugünün 5 Dakikası',
                        title: 'Bugün Kuran ile biraz zaman geçirin.',
                        button: '4–6 dakika',
                        trailing: const Icon(Icons.auto_awesome_outlined, size: 56),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Sizin için daha fazlası',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 18),
                      _InfoCard(
                        eyebrow: 'Başlayacak bir yere mi ihtiyacınız var?',
                        title: 'Kuran’da zaman geçirmenize yardımcı olacak bir plan seçin.',
                        button: 'Planlar Bul',
                        trailing: const Icon(Icons.route_outlined, size: 58),
                      ),
                    ],
                  )
                : _CommunityPlaceholder(muted: muted),
          ),
        ],
      ),
    );
  }

  Widget _Tab(String text, int index) {
    final selected = tab == index;
    return GestureDetector(
      onTap: () => setState(() => tab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : Colors.white54,
            ),
          ),
          const SizedBox(height: 9),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 88 : 0,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF70C9A9),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.muted});
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283A34), Color(0xFF1E2724)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Günün Ayeti', style: TextStyle(color: muted, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('İnşirah 94:6 · DİB',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          const Text(
            'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'serif', fontSize: 30, height: 1.7),
          ),
          const SizedBox(height: 10),
          const Text(
            'Meal metni burada seçilen çeviriye göre gösterilecek.',
            style: TextStyle(fontFamily: 'serif', fontSize: 21, height: 1.35),
          ),
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(Icons.favorite_border, 'Kaydet'),
              _Stat(Icons.chat_bubble_outline, 'Not'),
              _Stat(Icons.ios_share_outlined, 'Paylaş'),
              _Stat(Icons.more_horiz, 'Daha fazla'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.eyebrow,
    required this.title,
    required this.button,
    required this.trailing,
  });

  final String eyebrow;
  final String title;
  final String button;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF211F1F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow,
                    style: TextStyle(color: Colors.white.withValues(alpha: .62), fontSize: 15)),
                const SizedBox(height: 7),
                Text(title,
                    style: const TextStyle(fontSize: 23, height: 1.25, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B4949),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Text(button, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(width: 92, child: Center(child: trailing)),
        ],
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF70C9A9), width: 5),
        ),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      );
}

class _CommunityPlaceholder extends StatelessWidget {
  const _CommunityPlaceholder({required this.muted});
  final Color muted;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 72, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF211F1F),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kendini Çevrele', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 22),
                Text(
                  'Arkadaşlarla okuma planları ve özel gruplar daha sonraki sürümde burada olacak.',
                  style: TextStyle(color: muted, fontSize: 18, height: 1.45),
                ),
                const SizedBox(height: 22),
                FilledButton(onPressed: () {}, child: const Text('Arkadaş Ekle')),
              ],
            ),
          ),
        ],
      );
}
