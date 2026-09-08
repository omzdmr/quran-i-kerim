import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../application/prayer_online_location_service.dart';
import '../data/offline_city_repository.dart';
import '../domain/prayer_city_catalog.dart';

class PrayerCityPicker extends StatefulWidget {
  const PrayerCityPicker({
    required this.selectedCityId,
    this.onUseCurrentLocation,
    super.key,
  });

  final String? selectedCityId;
  final Future<void> Function()? onUseCurrentLocation;

  @override
  State<PrayerCityPicker> createState() => _PrayerCityPickerState();
}

class _PrayerCityPickerState extends State<PrayerCityPicker> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loadingOffline = false;
  bool _loadingOnline = false;
  bool _offlineSearched = false;
  List<PrayerCity> _offlineResults = const <PrayerCity>[];
  List<PrayerCity> _onlineResults = const <PrayerCity>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _query = value;
      _onlineResults = const <PrayerCity>[];
      _offlineSearched = false;
    });
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _offlineResults = const <PrayerCity>[]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 260), _searchOffline);
  }

  Future<void> _searchOffline() async {
    final queryAtStart = _query;
    if (queryAtStart.trim().length < 2) return;
    setState(() => _loadingOffline = true);
    try {
      final world = await OfflinePrayerCityRepository.instance.search(
        queryAtStart,
      );
      if (!mounted || _query != queryAtStart) return;
      final priority = prayerCities.where((city) {
        final text = _normalize('${city.searchText} ${city.country}');
        return text.contains(_normalize(queryAtStart));
      });
      final seen = <String>{};
      final merged = <PrayerCity>[];
      for (final city in [...priority, ...world]) {
        final key = '${city.label}|${city.country}|${city.location.latitude.toStringAsFixed(3)}|${city.location.longitude.toStringAsFixed(3)}';
        if (seen.add(key)) merged.add(city);
        if (merged.length >= 60) break;
      }
      setState(() {
        _offlineResults = merged;
        _offlineSearched = true;
      });
    } catch (_) {
      if (mounted && _query == queryAtStart) {
        setState(() {
          _offlineResults = const <PrayerCity>[];
          _offlineSearched = true;
        });
      }
    } finally {
      if (mounted && _query == queryAtStart) {
        setState(() => _loadingOffline = false);
      }
    }
  }

  Future<void> _searchOnline() async {
    if (_query.trim().length < 2 || _loadingOnline) return;
    setState(() => _loadingOnline = true);
    try {
      final results = await PrayerOnlineLocationService.search(
        query: _query,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() => _onlineResults = results);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('onlineSearchFailed'))),
      );
    } finally {
      if (mounted) setState(() => _loadingOnline = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    Navigator.pop(context);
    await widget.onUseCurrentLocation?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final queryActive = _query.trim().length >= 2;
    final visible = queryActive ? _offlineResults : prayerCities;
    final showNotFound =
        queryActive &&
        _offlineSearched &&
        !_loadingOffline &&
        visible.isEmpty &&
        _onlineResults.isEmpty;

    return FractionallySizedBox(
      heightFactor: .92,
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
                  Expanded(
                    child: Text(
                      l10n.text('chooseCity'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
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
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: l10n.text('citySearchHint'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _loadingOffline
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            _debounce?.cancel();
                            setState(() {
                              _query = '';
                              _offlineResults = const <PrayerCity>[];
                              _onlineResults = const <PrayerCity>[];
                              _offlineSearched = false;
                            });
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
            if (!queryActive && widget.onUseCurrentLocation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: Text(l10n.text('useCurrentLocation')),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.text('worldCitySearchInfo'),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: showNotFound
                  ? _NotFoundActions(
                      loadingOnline: _loadingOnline,
                      onUseLocation: widget.onUseCurrentLocation == null
                          ? null
                          : _useCurrentLocation,
                      onSearchOnline: _searchOnline,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                      children: [
                        if (_onlineResults.isNotEmpty) ...[
                          _SectionLabel(l10n.text('onlineResults')),
                          for (final city in _onlineResults)
                            _CityTile(
                              city: city,
                              selected: city.id == widget.selectedCityId,
                            ),
                          const SizedBox(height: 14),
                        ],
                        if (visible.isNotEmpty) ...[
                          _SectionLabel(
                            queryActive
                                ? l10n.text('offlineResults')
                                : l10n.text('priorityCities'),
                          ),
                          for (final city in visible)
                            _CityTile(
                              city: city,
                              selected: city.id == widget.selectedCityId,
                            ),
                        ],
                        if (queryActive &&
                            _offlineSearched &&
                            !_loadingOffline &&
                            visible.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: OutlinedButton.icon(
                              onPressed: _loadingOnline ? null : _searchOnline,
                              icon: _loadingOnline
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.public_rounded),
                              label: Text(l10n.text('searchOnline')),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Text(
                l10n.text('locationDataAttribution'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalize(String value) => value
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .toLowerCase()
      .trim();
}

class _NotFoundActions extends StatelessWidget {
  const _NotFoundActions({
    required this.loadingOnline,
    required this.onUseLocation,
    required this.onSearchOnline,
  });

  final bool loadingOnline;
  final VoidCallback? onUseLocation;
  final VoidCallback onSearchOnline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_searching_rounded, size: 48, color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              l10n.text('cityNotFound'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text('cityNotFoundBody'),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 18),
            if (onUseLocation != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onUseLocation,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(l10n.text('useLocationToFind')),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loadingOnline ? null : onSearchOnline,
                icon: loadingOnline
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.public_rounded),
                label: Text(l10n.text('searchOnline')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(5, 3, 5, 8),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.city, required this.selected});

  final PrayerCity city;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: () => Navigator.pop(context, city),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: Icon(
            selected ? Icons.location_on_rounded : Icons.location_on_outlined,
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
    );
  }
}
