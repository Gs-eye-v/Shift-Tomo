import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/shift.dart';
import '../model/shift_tag.dart';
import '../provider/tag_provider.dart';

class CalendarCell extends ConsumerWidget {
  final DateTime date;
  final List<Shift> shifts;
  final bool isToday;
  final bool isCurrentMonth;
  final VoidCallback? onTap;

  const CalendarCell({
    super.key,
    required this.date,
    required this.shifts,
    this.isToday = false,
    this.isCurrentMonth = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // タグ情報を取得
    final tagsAsync = ref.watch(tagNotifierProvider);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
        color: _getBackgroundColor(tagsAsync.value ?? []),
      ),
      child: Stack(
        children: [
          // 1. コンテンツレイヤー (LayoutBuilder)
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
                  // 1. Emojis/Grid (メインコンテンツ)
                  _buildContent(appliedTags, emojiStyle),
    
                  // 2. メモアイコン (右下隅に絶対配置)
                  if (memo != null && memo.isNotEmpty)
                    const Positioned(
                      bottom: 2,
                      right: 2,
                      child: Text(
                        '📝',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
    
                  // 3. 日付 (右上隅)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrentMonth ? null : Colors.grey.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Theme.of(context).scaffoldBackgroundColor, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // 2. ヒットレイヤー (最前面でタップを確実に捕捉)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<ShiftTag> appliedTags, TextStyle style) {
    final count = appliedTags.length;

    if (count == 0) return const SizedBox.expand();

    // 1つだけの場合は特大表示 (フルセル)
    if (count == 1) {
      return Center(
        child: FractionallySizedBox(
          widthFactor: 0.75,
          heightFactor: 0.75,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(appliedTags.first.emoji, style: style),
          ),
        ),
      );
    }

    // 2つの場合は上下二分割
    if (count == 2) {
      return Column(
        children: [
          Expanded(child: _buildEmojiSlot(appliedTags[0].emoji, style)),
          Expanded(child: _buildEmojiSlot(appliedTags[1].emoji, style)),
        ],
      );
    }

    // 3〜4つの場合は2x2グリッド
    return Column(
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
    );
  }

  Widget _buildEmojiSlot(String emoji, TextStyle style) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 0.8,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(emoji, style: style),
        ),
      ),
    );
  }

  Color? _getBackgroundColor(List<ShiftTag> allTags) {
    if (shifts.isEmpty) return null;
    final tagIds = shifts.first.tagIds;
    if (tagIds.isEmpty) return null;
    
    final firstTag = allTags.where((t) => t.id == tagIds.first).firstOrNull;
    if (firstTag == null) return null;
    
    return firstTag.color.withOpacity(0.3);
  }
}
