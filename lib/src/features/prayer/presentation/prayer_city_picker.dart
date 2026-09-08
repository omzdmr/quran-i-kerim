import 'package:flutter/material.dart';

import '../domain/prayer_city_catalog.dart';

class PrayerCityPicker extends StatefulWidget {
  const PrayerCityPicker({required this.selectedCityId, super.key});

  final String selectedCityId;

  @override
  State<PrayerCityPicker> createState() => _PrayerCityPickerState();
}

class _PrayerCityPickerState extends State<PrayerCityPicker> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = _normalize(_query);
    final filtered = normalized.isEmpty
        ? prayerCities
        : prayerCities
            .where((city) => _normalize(city.searchText).contains(normalized))
            .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: .9,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Şehir seç',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: TextField(
                controller: _controller,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Şehir veya ülke ara',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: scheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Türkiye, Hicaz/Körfez, Orta Doğu, Güney ve Güneydoğu Asya önceliklidir. Liste çevrimdışı çalışır.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Şehir bulunamadı.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final city = filtered[index];
                        final showGroup = index == 0 ||
                            filtered[index - 1].group != city.group;
                        final selected = city.id == widget.selectedCityId;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showGroup) ...[
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  5,
                                  index == 0 ? 3 : 18,
                                  5,
                                  8,
                                ),
                                child: Text(
                                  city.group,
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                            Material(
                              color: selected
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(18),
                              child: ListTile(
                                onTap: () => Navigator.pop(context, city),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                leading: Icon(
                                  selected
                                      ? Icons.location_on_rounded
                                      : Icons.location_on_outlined,
                                ),
                                title: Text(
                                  city.label,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(city.country),
                                trailing: selected
                                    ? const Icon(Icons.check_circle_rounded)
                                    : const Icon(Icons.chevron_right_rounded),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalize(String value) => value
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .trim();
}
