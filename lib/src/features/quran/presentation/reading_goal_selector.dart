import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReadingGoalChoice {
  const ReadingGoalChoice({
    required this.minutes,
    required this.title,
    required this.subtitle,
  });

  final int minutes;
  final String title;
  final String subtitle;
}

class ReadingGoalSelector extends StatelessWidget {
  const ReadingGoalSelector({
    required this.choices,
    required this.selectedMinutes,
    required this.onSelected,
    super.key,
  });

  final List<ReadingGoalChoice> choices;
  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final choice in choices) ...[
          Material(
            color: choice.minutes == selectedMinutes
                ? scheme.primaryContainer
                : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(choice.minutes);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: .58),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choice.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            choice.subtitle,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      choice.minutes == selectedMinutes
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: choice.minutes == selectedMinutes
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

Future<int?> showReadingGoalSelector({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required List<ReadingGoalChoice> choices,
  required int initialMinutes,
}) async {
  var selected = initialMinutes;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 18),
                  ReadingGoalSelector(
                    choices: choices,
                    selectedMinutes: selected,
                    onSelected: (value) =>
                        setModalState(() => selected = value),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
