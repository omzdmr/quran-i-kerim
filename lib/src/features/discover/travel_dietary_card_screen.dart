import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'travel_dietary_card_store.dart';

class TravelDietaryCardScreen extends StatefulWidget {
  const TravelDietaryCardScreen({super.key, this.store = const TravelDietaryCardStore()});
  final TravelDietaryCardStore store;
  @override State<TravelDietaryCardScreen> createState() => _TravelDietaryCardScreenState();
}

class _TravelDietaryCardScreenState extends State<TravelDietaryCardScreen> {
  final _language = TextEditingController();
  final _staffText = TextEditingController();
  final _note = TextEditingController();
  bool _loading = true;
  bool _present = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _language.dispose(); _staffText.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _load() async {
    final card = await widget.store.load();
    if (!mounted) return;
    if (card != null) { _language.text = card.languageLabel; _staffText.text = card.staffText; _note.text = card.note; }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final c = _Copy.forLocale(Localizations.localeOf(context));
    if (_staffText.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.required))); return; }
    await widget.store.save(TravelDietaryCard(languageLabel: _language.text, staffText: _staffText.text, note: _note.text));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _present = true);
  }

  @override Widget build(BuildContext context) {
    final c = _Copy.forLocale(Localizations.localeOf(context));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(c.title), actions: [IconButton(onPressed: _loading ? null : _save, icon: const Icon(Icons.save_outlined), tooltip: c.save)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(20), children: [
        Text(c.explanation, style: theme.textTheme.bodyLarge), const SizedBox(height: 18),
        if (!_present) ...[
          TextField(controller: _language, maxLength: 80, decoration: InputDecoration(labelText: c.language)),
          TextField(controller: _staffText, maxLength: 1200, minLines: 5, maxLines: 10, decoration: InputDecoration(labelText: c.staffText, helperText: c.staffHelp)),
          TextField(controller: _note, maxLength: 300, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: c.note)),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.badge_outlined), label: Text(c.present)),
        ] else ...[
          Semantics(container: true, label: '${c.staffText}: ${_staffText.text}', child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_language.text.trim().isNotEmpty) Text(_language.text.trim(), style: theme.textTheme.labelLarge),
            const SizedBox(height: 12), SelectableText(_staffText.text.trim(), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.45)),
            if (_note.text.trim().isNotEmpty) ...[const Divider(height: 32), Text(_note.text.trim())],
          ]))),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => setState(() => _present = false), icon: const Icon(Icons.edit_outlined), label: Text(c.edit)),
        ],
        const SizedBox(height: 18), Text(c.trust, style: theme.textTheme.bodySmall),
      ]),
    );
  }
}

class _Copy {
  const _Copy(this.title,this.explanation,this.language,this.staffText,this.staffHelp,this.note,this.save,this.present,this.edit,this.required,this.trust);
  final String title, explanation, language, staffText, staffHelp, note, save, present, edit, required, trust;
  static _Copy forLocale(Locale locale) => _all[locale.languageCode] ?? _all['en']!;
}
const _all = <String,_Copy>{
 'tr': _Copy('Yemek iletişim kartı','Restoran çalışanına göstermek istediğiniz, doğruluğunu bildiğiniz metni cihazda saklayın. İnternetsiz çalışır.','Dil / bölge','Çalışana gösterilecek metin','Metni kendiniz veya güvendiğiniz bir çeviriden girin.','Kendinize not','Kaydet','Kartı göster','Düzenle','Gösterilecek metin boş olamaz.','Bu kart bir restoranı veya yemeği helal olarak onaylamaz; yalnızca sizin yazdığınız isteği gösterir.'),
 'en': _Copy('Dietary communication card','Keep text you trust on-device and show it to restaurant staff offline.','Language / region','Text shown to staff','Enter your own text or a translation you trust.','Private note','Save','Show card','Edit','Staff-facing text cannot be empty.','This card does not certify a restaurant or dish as halal; it only displays the request you entered.'),
 'fr': _Copy('Carte de communication alimentaire','Conservez sur l’appareil un texte fiable à montrer au personnel, même hors ligne.','Langue / région','Texte à montrer au personnel','Saisissez votre texte ou une traduction de confiance.','Note privée','Enregistrer','Afficher la carte','Modifier','Le texte à afficher ne peut pas être vide.','Cette carte ne certifie ni un restaurant ni un plat halal ; elle affiche uniquement votre demande.'),
 'ar': _Copy('بطاقة التواصل الغذائي','احفظ على الجهاز نصًا تثق به لعرضه على موظفي المطعم دون اتصال.','اللغة / المنطقة','النص المعروض للموظف','أدخل نصك أو ترجمة تثق بها.','ملاحظة خاصة','حفظ','عرض البطاقة','تعديل','لا يمكن أن يكون النص فارغًا.','هذه البطاقة لا تصدّق مطعمًا أو طبقًا على أنه حلال؛ بل تعرض فقط الطلب الذي أدخلته.'),
 'az': _Copy('Qida ünsiyyət kartı','Etibar etdiyiniz mətni cihazda saxlayın və oflayn halda işçiyə göstərin.','Dil / bölgə','İşçiyə göstəriləcək mətn','Öz mətninizi və ya etibar etdiyiniz tərcüməni daxil edin.','Şəxsi qeyd','Yadda saxla','Kartı göstər','Düzəlt','Göstəriləcək mətn boş ola bilməz.','Bu kart restoranı və ya yeməyi halal kimi təsdiqləmir; yalnız daxil etdiyiniz tələbi göstərir.'),
 'ru': _Copy('Карточка питания','Храните доверенный текст на устройстве и показывайте персоналу без интернета.','Язык / регион','Текст для персонала','Введите свой текст или перевод, которому доверяете.','Личная заметка','Сохранить','Показать карточку','Изменить','Текст для персонала не может быть пустым.','Карточка не подтверждает халяльность ресторана или блюда; она лишь показывает введённую вами просьбу.'),
};
