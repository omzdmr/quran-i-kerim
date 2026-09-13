import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LearnArticleCardData {
  const LearnArticleCardData({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    this.cover,
    this.icon = Icons.menu_book_rounded,
  });

  final String id;
  final String title;
  final String summary;
  final String category;
  final ImageProvider? cover;
  final IconData icon;
}

/// Section wrapper matching the reference pattern of a compact article preview
/// plus an explicit “see all” action. Content and licensing stay external.
class LearnArticleSection extends StatelessWidget {
  const LearnArticleSection({
    required this.title,
    required this.items,
    required this.onOpen,
    super.key,
    this.seeAllLabel,
    this.onSeeAll,
    this.previewCount = 4,
    this.emptyState,
  });

  final String title;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final int previewCount;
  final List<LearnArticleCardData> items;
  final ValueChanged<LearnArticleCardData> onOpen;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    final safeCount = previewCount < 0 ? 0 : previewCount;
    final preview = items.take(safeCount).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (seeAllLabel != null && onSeeAll != null)
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onSeeAll!();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      seeAllLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 17),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        LearnArticleGrid(
          items: preview,
          onOpen: onOpen,
          emptyState: emptyState,
        ),
      ],
    );
  }
}

/// Two-column article surface derived from the supplied references.
///
/// Data and licensing remain outside this widget. Callers should only provide
/// editorial content that has already passed source/licence validation.
class LearnArticleGrid extends StatelessWidget {
  const LearnArticleGrid({
    required this.items,
    required this.onOpen,
    super.key,
    this.emptyState,
  });

  final List<LearnArticleCardData> items;
  final ValueChanged<LearnArticleCardData> onOpen;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return emptyState ?? const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 3 ? .86 : .74,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ArticleCard(
              item: item,
              onTap: () {
                HapticFeedback.selectionClick();
                onOpen(item);
              },
            );
          },
        );
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.item, required this.onTap});

  final LearnArticleCardData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: item.cover == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primaryContainer,
                            scheme.secondaryContainer,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          size: 42,
                          color: scheme.primary,
                        ),
                      ),
                    )
                  : Image(
                      image: item.cover!,
                      fit: BoxFit.cover,
                    ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        item.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
