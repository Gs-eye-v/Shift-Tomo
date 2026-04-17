import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/shift.dart';
import '../model/shift_tag.dart';
import '../provider/tag_provider.dart';
import '../provider/app_settings_provider.dart';

class CalendarCell extends ConsumerWidget {
  final DateTime date;
  final List<Shift> shifts;
  final List<Shift> sharedShifts;
  final bool isToday;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  const CalendarCell({
    super.key,
    required this.date,
    required this.shifts,
    this.sharedShifts = const [],
    this.isToday = false,
    this.isCurrentMonth = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagNotifierProvider);
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.secondary;
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context, tagsAsync.value ?? []),
        borderRadius: BorderRadius.circular(12),
        border: isToday 
            ? Border.all(color: secondaryColor, width: 2)
            : Border.all(color: theme.dividerColor, width: 1),
        boxShadow: isToday ? [
          BoxShadow(
            color: secondaryColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const emojiStyle = TextStyle(
                color: null,
                fontFamilyFallback: [
                  'Apple Color Emoji',
                  'Segoe UI Emoji',
                  'Noto Color Emoji',
                ],
              );
    
              final dayShifts = shifts.where((s) => 
                s.date.year == date.year && 
                s.date.month == date.month && 
                s.date.day == date.day
              ).toList();
    
              final List<ShiftTag> appliedTags = [];
              String? memo;
              
              if (dayShifts.isNotEmpty) {
                memo = dayShifts.first.memo;
                final tagIds = dayShifts.first.tagIds;
                final allTags = tagsAsync.value ?? [];
                for (final id in tagIds) {
                  final tag = allTags.where((t) => t.id == id).firstOrNull;
                  if (tag != null) appliedTags.add(tag);
                }
              }
    
              return Stack(
                children: [
                  _buildContent(ref, appliedTags, emojiStyle),
    
                  if (sharedShifts.isNotEmpty)
                    Positioned(
                      bottom: 4,
                      left: 2,
                      right: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: sharedShifts.expand((s) {
                          return s.tagIds.map((id) {
                            final tag = tagsAsync.value?.where((t) => t.id == id).firstOrNull;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1.0),
                              child: Text(tag?.emoji ?? '?', style: const TextStyle(fontSize: 8)),
                            );
                          });
                        }).toList(),
                      ),
                    ),
    
                  if (memo != null && memo.isNotEmpty)
                    const Positioned(
                      bottom: 4,
                      right: 4,
                      child: Text('📝', style: TextStyle(fontSize: 10)),
                    ),
    
                  Positioned(
                    top: 4,
                    right: 6,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrentMonth 
                            ? (isToday ? secondaryColor : theme.textTheme.bodyLarge?.color) 
                            : theme.textTheme.bodyLarge?.color?.withOpacity(0.25),
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                splashColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(WidgetRef ref, List<ShiftTag> appliedTags, TextStyle style) {
    final count = appliedTags.length;
    if (count == 0) return const SizedBox.expand();

    if (count == 1) {
      return _withEmojiStyle(
        ref,
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.65,
            heightFactor: 0.65,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(appliedTags.first.emoji, style: style),
            ),
          ),
        ),
      );
    }

    if (count == 2) {
      return _withEmojiStyle(
        ref,
        Column(
          children: [
            Expanded(child: _buildEmojiSlot(appliedTags[0].emoji, style)),
            Expanded(child: _buildEmojiSlot(appliedTags[1].emoji, style)),
          ],
        ),
      );
    }

    return _withEmojiStyle(
      ref,
      Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildEmojiSlot(appliedTags[0].emoji, style)),
                Expanded(child: _buildEmojiSlot(appliedTags[1].emoji, style)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildEmojiSlot(appliedTags[2].emoji, style)),
                Expanded(
                  child: count > 3 
                    ? _buildEmojiSlot(appliedTags[3].emoji, style)
                    : const SizedBox.expand()
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _withEmojiStyle(WidgetRef ref, Widget child) {
    final useColor = ref.watch(appSettingsNotifierProvider).useColorEmoji;
    if (useColor) return child;

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Colors.grey,
        BlendMode.saturation,
      ),
      child: child,
    );
  }

  Widget _buildEmojiSlot(String emoji, TextStyle style) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.7,
        heightFactor: 0.7,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(emoji, style: style),
        ),
      ),
    );
  }

  Color? _getBackgroundColor(BuildContext context, List<ShiftTag> allTags) {
    if (shifts.isEmpty) return Theme.of(context).cardColor;
    final tagIds = shifts.first.tagIds;
    if (tagIds.isEmpty) return Theme.of(context).cardColor;
    
    final firstTag = allTags.where((t) => t.id == tagIds.first).firstOrNull;
    if (firstTag == null) return Theme.of(context).cardColor;
    
    return firstTag.color.withOpacity(0.15);
  }
}
