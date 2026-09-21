import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'travel_dietary_card_store.dart';

class TravelDietaryCardScreen extends StatefulWidget {
  const TravelDietaryCardScreen({super.key, this.store = const TravelDietaryCardStore()});
  final TravelDietaryCardStore store;
  @override State<TravelDietaryCardScreen> createState()=>_TravelDietaryCardScreenState();
}

class _TravelDietaryCardScreenState extends State<TravelDietaryCardScreen> {
  final _language=TextEditingController(), _staffText=TextEditingController(), _note=TextEditingController();
  bool _loading=true, _present=false, _hasSaved=false;
  @override void initState(){super.initState();_load();}
  @override void dispose(){_language.dispose();_staffText.dispose();_note.dispose();super.dispose();}

  Future<void> _load() async {
    final card=await widget.store.load(); if(!mounted)return;
    if(card!=null){_language.text=card.languageLabel;_staffText.text=card.staffText;_note.text=card.note;}
    setState((){_hasSaved=card!=null;_loading=false;});
  }

  Future<void> _save() async {
    final c=_Copy.forLocale(Localizations.localeOf(context));
    if(_staffText.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(c.required)));return;}
    await widget.store.save(TravelDietaryCard(languageLabel:_language.text,staffText:_staffText.text,note:_note.text));
    if(!mounted)return; HapticFeedback.mediumImpact(); setState((){_present=true;_hasSaved=true;});
  }

  Future<void> _clear() async {
    final c=_Copy.forLocale(Localizations.localeOf(context));
    final confirmed=await showDialog<bool>(context:context,builder:(dialogContext)=>AlertDialog(title:Text(c.clearTitle),content:Text(c.clearBody),actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:Text(c.cancel)),FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:Text(c.clear))]));
    if(confirmed!=true)return;
    await widget.store.clear(); if(!mounted)return;
    _language.clear();_staffText.clear();_note.clear(); HapticFeedback.mediumImpact(); setState((){_hasSaved=false;_present=false;});
  }

  Future<void> _copyStaffText(_Copy c) async {await Clipboard.setData(ClipboardData(text:_staffText.text.trim()));if(!mounted)return;HapticFeedback.selectionClick();ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(c.copied)));}

  @override Widget build(BuildContext context){
    final c=_Copy.forLocale(Localizations.localeOf(context)); final theme=Theme.of(context);
    return Scaffold(
      appBar:AppBar(title:Text(c.title),actions:[if(_hasSaved)IconButton(onPressed:_clear,icon:const Icon(Icons.delete_outline_rounded),tooltip:c.clear),IconButton(onPressed:_loading?null:_save,icon:const Icon(Icons.save_outlined),tooltip:c.save)]),
      body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
        Text(c.explanation,style:theme.textTheme.bodyLarge),const SizedBox(height:18),
        if(!_present)...[
          TextField(controller:_language,maxLength:TravelDietaryCard.maxLanguageLength,decoration:InputDecoration(labelText:c.language)),
          TextField(controller:_staffText,maxLength:TravelDietaryCard.maxStaffTextLength,minLines:5,maxLines:10,decoration:InputDecoration(labelText:c.staffText,helperText:c.staffHelp)),
          TextField(controller:_note,maxLength:TravelDietaryCard.maxNoteLength,minLines:2,maxLines:4,decoration:InputDecoration(labelText:c.note,helperText:c.noteHelp)),
          FilledButton.icon(onPressed:_save,icon:const Icon(Icons.badge_outlined),label:Text(c.present)),
        ]else...[
          Semantics(container:true,label:'${c.staffText}: ${_staffText.text}',child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(_language.text.trim().isNotEmpty)Text(_language.text.trim(),style:theme.textTheme.labelLarge),const SizedBox(height:12),SelectableText(_staffText.text.trim(),textAlign:TextAlign.center,style:theme.textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800,height:1.45))]))),
          const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[OutlinedButton.icon(onPressed:()=>_copyStaffText(c),icon:const Icon(Icons.copy_rounded),label:Text(c.copy)),OutlinedButton.icon(onPressed:()=>setState(()=>_present=false),icon:const Icon(Icons.edit_outlined),label:Text(c.edit))]),
          if(_note.text.trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(c.privateNoteSaved,style:theme.textTheme.bodySmall)),
        ],
        const SizedBox(height:18),Text(c.trust,style:theme.textTheme.bodySmall),
      ]),
    );
  }
}

class _Copy {
  const _Copy(this.title,this.explanation,this.language,this.staffText,this.staffHelp,this.note,this.noteHelp,this.save,this.present,this.edit,this.copy,this.copied,this.privateNoteSaved,this.required,this.trust,this.clear,this.clearTitle,this.clearBody,this.cancel);
  final String title,explanation,language,staffText,staffHelp,note,noteHelp,save,present,edit,copy,copied,privateNoteSaved,required,trust,clear,clearTitle,clearBody,cancel;
  static _Copy forLocale(Locale locale)=>_all[locale.languageCode]??_all['en']!;
}
const _all=<String,_Copy>{
 'tr':_Copy('Yemek iletişim kartı','Restoran çalışanına göstermek istediğiniz, doğruluğunu bildiğiniz metni cihazda saklayın. İnternetsiz çalışır.','Dil / bölge','Çalışana gösterilecek metin','Metni kendiniz veya güvendiğiniz bir çeviriden girin.','Kendinize not','Bu not kart gösterilirken gizli kalır.','Kaydet','Kartı göster','Düzenle','Metni kopyala','Metin kopyalandı','Özel not kaydedildi; çalışan kartında gösterilmiyor.','Gösterilecek metin boş olamaz.','Bu kart bir restoranı veya yemeği helal olarak onaylamaz; yalnızca sizin yazdığınız isteği gösterir.','Sil','Kart silinsin mi?','Kaydedilmiş metin ve özel not bu cihazdan silinecek.','Vazgeç'),
 'en':_Copy('Dietary communication card','Keep text you trust on-device and show it to restaurant staff offline.','Language / region','Text shown to staff','Enter your own text or a translation you trust.','Private note','This note stays hidden while presenting the card.','Save','Show card','Edit','Copy text','Text copied','Private note saved; it is hidden from the staff card.','Staff-facing text cannot be empty.','This card does not certify a restaurant or dish as halal; it only displays the request you entered.','Delete','Delete card?','Saved text and private note will be removed from this device.','Cancel'),
 'fr':_Copy('Carte de communication alimentaire','Conservez sur l’appareil un texte fiable à montrer au personnel, même hors ligne.','Langue / région','Texte à montrer au personnel','Saisissez votre texte ou une traduction de confiance.','Note privée','Cette note reste masquée lors de la présentation.','Enregistrer','Afficher la carte','Modifier','Copier le texte','Texte copié','Note privée enregistrée ; elle reste masquée sur la carte.','Le texte à afficher ne peut pas être vide.','Cette carte ne certifie ni un restaurant ni un plat halal ; elle affiche uniquement votre demande.','Supprimer','Supprimer la carte ?','Le texte enregistré et la note privée seront supprimés de cet appareil.','Annuler'),
 'ar':_Copy('بطاقة التواصل الغذائي','احفظ على الجهاز نصًا تثق به لعرضه على موظفي المطعم دون اتصال.','اللغة / المنطقة','النص المعروض للموظف','أدخل نصك أو ترجمة تثق بها.','ملاحظة خاصة','تبقى هذه الملاحظة مخفية عند عرض البطاقة.','حفظ','عرض البطاقة','تعديل','نسخ النص','تم نسخ النص','تم حفظ الملاحظة الخاصة ولن تظهر في بطاقة الموظف.','لا يمكن أن يكون النص فارغًا.','هذه البطاقة لا تصدّق مطعمًا أو طبقًا على أنه حلال؛ بل تعرض فقط الطلب الذي أدخلته.','حذف','حذف البطاقة؟','سيتم حذف النص المحفوظ والملاحظة الخاصة من هذا الجهاز.','إلغاء'),
 'az':_Copy('Qida ünsiyyət kartı','Etibar etdiyiniz mətni cihazda saxlayın və oflayn halda işçiyə göstərin.','Dil / bölgə','İşçiyə göstəriləcək mətn','Öz mətninizi və ya etibar etdiyiniz tərcüməni daxil edin.','Şəxsi qeyd','Kart göstərilərkən bu qeyd gizli qalır.','Yadda saxla','Kartı göstər','Düzəlt','Mətni kopyala','Mətn kopyalandı','Şəxsi qeyd saxlanıldı və işçi kartında göstərilmir.','Göstəriləcək mətn boş ola bilməz.','Bu kart restoranı və ya yeməyi halal kimi təsdiqləmir; yalnız daxil etdiyiniz tələbi göstərir.','Sil','Kart silinsin?','Saxlanmış mətn və şəxsi qeyd bu cihazdan silinəcək.','Ləğv et'),
 'ru':_Copy('Карточка питания','Храните доверенный текст на устройстве и показывайте персоналу без интернета.','Язык / регион','Текст для персонала','Введите свой текст или перевод, которому доверяете.','Личная заметка','Эта заметка скрыта при показе карточки.','Сохранить','Показать карточку','Изменить','Копировать текст','Текст скопирован','Личная заметка сохранена и скрыта от персонала.','Текст для персонала не может быть пустым.','Карточка не подтверждает халяльность ресторана или блюда; она лишь показывает введённую вами просьбу.','Удалить','Удалить карточку?','Сохранённый текст и личная заметка будут удалены с устройства.','Отмена'),
};
