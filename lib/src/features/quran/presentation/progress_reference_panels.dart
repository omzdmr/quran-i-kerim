import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact reference-inspired strip explaining where saved reading artifacts
/// live. Labels and values are supplied by the caller so localization and
/// persistence remain outside presentation code.
class QuranProgressArchiveBanner extends StatelessWidget {
  const QuranProgressArchiveBanner({
    required this.title,
    required this.savedLabel,
    required this.notesLabel,
    required this.highlightsLabel,
    super.key,
    this.savedCount,
    this.notesCount,
    this.highlightsCount,
  });

  final String title;
  final String savedLabel;
  final String notesLabel;
  final String highlightsLabel;
  final int? savedCount;
  final int? notesCount;
  final int? highlightsCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.bookmarks_outlined,
                  size: 19,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ArchivePill(
                icon: Icons.bookmark_outline_rounded,
                label: savedLabel,
                count: savedCount,
              ),
              _ArchivePill(
                icon: Icons.note_alt_outlined,
                label: notesLabel,
                count: notesCount,
              ),
              _ArchivePill(
                icon: Icons.border_color_outlined,
                label: highlightsLabel,
                count: highlightsCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Entry card for the reading-goal selector used from Progress/Plans.
class QuranReadingGoalCard extends StatelessWidget {
  const QuranReadingGoalCard({
    required this.title,
    required this.value,
    required this.editLabel,
    required this.onEdit,
    super.key,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onEdit();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.track_changes_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                editLabel,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivePill extends StatelessWidget {
  const _ArchivePill({required this.icon, required this.label, this.count});

  final IconData icon;
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          if (count != null) ...[
            Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
