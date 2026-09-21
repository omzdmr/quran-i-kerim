import 'package:flutter/material.dart';

import 'qada_fasting_archive_screen.dart';
import 'qada_fasting_ledger.dart';
import 'qada_fasting_screen.dart';

class QadaFastingHubScreen extends StatefulWidget {
  const QadaFastingHubScreen({super.key});

  @override
  State<QadaFastingHubScreen> createState() => _QadaFastingHubScreenState();
}

class _QadaFastingHubScreenState extends State<QadaFastingHubScreen> {
  static const _store = QadaFastingStore();
  QadaFastingLedger _ledger = QadaFastingLedger();
  bool _loading = true;

  String get _language => Localizations.localeOf(context).languageCode;
  String _t(String key) => (_labels[_language] ?? _labels['en']!)[key] ?? key;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final ledger = await _store.load();
    if (!mounted) return;
    setState(() {
      _ledger = ledger;
      _loading = false;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_t('title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Semantics(
                  container: true,
                  excludeSemantics: true,
                  label:
                      '${_t('remaining')}: ${_ledger.remainingDays}. ${_t('records')}: ${_ledger.entries.length}.',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('remaining'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_ledger.remainingDays}',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_t('records')),
                            Text(
                              '${_ledger.entries.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _HubCard(
                  icon: Icons.event_repeat_rounded,
                  title: _t('ledger'),
                  subtitle: _t('ledgerBody'),
                  onTap: () => _open(const QadaFastingScreen()),
                ),
                const SizedBox(height: 12),
                _HubCard(
                  icon: Icons.backup_outlined,
                  title: _t('backup'),
                  subtitle: _t('backupBody'),
                  onTap: () => _open(const QadaFastingArchiveScreen()),
                ),
                const SizedBox(height: 18),
                Semantics(
                  container: true,
                  child: Text(
                    _t('privacy'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

const Map<String, Map<String, String>> _labels = {
  'tr': {
    'title': 'Kaza orucu', 'remaining': 'Kalan gün', 'records': 'Kayıt', 'ledger': 'Kaza defteri', 'ledgerBody': 'Borç, tamamlanan oruç, düzeltme ve Ramazan geçmişini yönet.', 'backup': 'Yedekle ve geri yükle', 'backupBody': 'Hesap gerektirmeyen taşınabilir yedek oluştur; içe aktarmadan önce önizle.', 'privacy': 'Kayıtlar cihazda tutulur. Uygulama dini hüküm çıkarmaz; yalnızca senin girdiğin bilgileri saklar.'
  },
  'en': {
    'title': 'Qada fasting', 'remaining': 'Remaining days', 'records': 'Records', 'ledger': 'Qada ledger', 'ledgerBody': 'Manage debt, completed fasts, corrections and Ramadan history.', 'backup': 'Backup and restore', 'backupBody': 'Create an account-free portable backup and preview it before import.', 'privacy': 'Records stay on the device. The app does not infer religious rulings; it only stores what you enter.'
  },
  'fr': {
    'title': 'Jeûnes à rattraper', 'remaining': 'Jours restants', 'records': 'Entrées', 'ledger': 'Registre', 'ledgerBody': 'Gérez les jours dus, rattrapés, les corrections et l’historique du Ramadan.', 'backup': 'Sauvegarde et restauration', 'backupBody': 'Créez une sauvegarde portable sans compte et vérifiez-la avant l’import.', 'privacy': 'Les données restent sur l’appareil. L’application conserve uniquement les informations que vous saisissez.'
  },
  'ar': {
    'title': 'صيام القضاء', 'remaining': 'الأيام المتبقية', 'records': 'السجلات', 'ledger': 'سجل القضاء', 'ledgerBody': 'إدارة الدين والصيام المقضي والتصحيحات وسجل رمضان.', 'backup': 'النسخ الاحتياطي والاستعادة', 'backupBody': 'أنشئ نسخة محمولة دون حساب وراجعها قبل الاستيراد.', 'privacy': 'تبقى السجلات على الجهاز. لا يستنبط التطبيق أحكامًا شرعية؛ بل يحفظ ما تدخله فقط.'
  },
  'az': {
    'title': 'Qəza orucu', 'remaining': 'Qalan günlər', 'records': 'Qeydlər', 'ledger': 'Qəza dəftəri', 'ledgerBody': 'Borc, tutulan oruclar, düzəlişlər və Ramazan tarixçəsini idarə et.', 'backup': 'Yedəklə və bərpa et', 'backupBody': 'Hesabsız daşına bilən yedək yarat və idxaldan əvvəl yoxla.', 'privacy': 'Qeydlər cihazda qalır. Tətbiq dini hökm çıxarmır; yalnız daxil etdiyin məlumatı saxlayır.'
  },
  'ru': {
    'title': 'Посты када', 'remaining': 'Осталось дней', 'records': 'Записи', 'ledger': 'Учёт када', 'ledgerBody': 'Управляйте долгом, выполненными постами, исправлениями и историей Рамадана.', 'backup': 'Резервная копия и восстановление', 'backupBody': 'Создайте переносимую копию без аккаунта и проверьте её перед импортом.', 'privacy': 'Записи остаются на устройстве. Приложение не выносит религиозных решений и хранит только введённые вами данные.'
  },
};
