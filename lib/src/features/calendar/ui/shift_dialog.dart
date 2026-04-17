import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/shift.dart';
import '../provider/tag_provider.dart';
import '../provider/calendar_provider.dart';
import '../provider/view_state_provider.dart'; // 追加

class ShiftDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final List<Shift>? initialShifts;

  const ShiftDialog({super.key, this.initialDate, this.initialShifts});

  static Future<void> show(BuildContext context, {DateTime? date, List<Shift>? initialShifts}) {
    return showDialog(
      context: context,
      builder: (context) => ShiftDialog(initialDate: date, initialShifts: initialShifts),
    );
  }

  @override
  ConsumerState<ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends ConsumerState<ShiftDialog> {
  late DateTime _selectedDate;
  final Set<String> _selectedTagIds = {};
  late TextEditingController _memoController;
  String? _existingId;

  // 差分チェック用の初期状態
  Set<String> _initialTagIds = {};
  String _initialMemo = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _memoController = TextEditingController();

    // 既存データがあれば復元
    if (widget.initialShifts != null && widget.initialShifts!.isNotEmpty) {
      final first = widget.initialShifts!.first;
      _existingId = first.id;
      _selectedTagIds.addAll(first.tagIds);
      _memoController.text = first.memo ?? '';
    }
    
    _recordInitialState();
  }

  void _recordInitialState() {
    _initialTagIds = Set.from(_selectedTagIds);
    _initialMemo = _memoController.text;
  }

  bool _hasChanges() {
    // タグの不一致チェック
    if (_initialTagIds.length != _selectedTagIds.length) return true;
    if (!_initialTagIds.containsAll(_selectedTagIds)) return true;
    
    // メモの不一致チェック
    if (_initialMemo != _memoController.text) return true;
    
    return false;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final tagsAsync = ref.watch(tagNotifierProvider);
        final viewUser = ref.watch(calendarViewUserNotifierProvider);
        final isReadOnly = !viewUser.isMe;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 8),
          title: Text(isReadOnly ? 'シフト詳細' : 'シフトを編集'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isReadOnly) ...[
                    // 上部ナビゲーション（日めくり用）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _saveAndPrevious(ref),
                          icon: const Icon(Icons.chevron_left, size: 18),
                          label: const Text('前へ', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        Text(
                          '${_selectedDate.month}/${_selectedDate.day}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _saveAndNext(ref),
                          icon: const Icon(Icons.chevron_right, size: 18),
                          label: const Text('次へ', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 日付選択（読み取り専用または通常表示）
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('対象日', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    subtitle: Text(
                      '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    trailing: isReadOnly ? null : const Icon(Icons.edit_calendar, size: 20),
                    onTap: isReadOnly ? null : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),

                  const Divider(),
                  const SizedBox(height: 8),

                  // タグ複数選択
                  tagsAsync.when(
                    data: (tags) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('タグを選択', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: tags.map((tag) {
                              final isSelected = _selectedTagIds.contains(tag.id);
                              return FilterChip(
                                label: Text('${tag.emoji} ${tag.title}'),
                                selected: isSelected,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                showCheckmark: false,
                                onSelected: isReadOnly ? null : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTagIds.add(tag.id);
                                    } else {
                                      _selectedTagIds.remove(tag.id);
                                    }
                                  });
                                },
                                selectedColor: tag.color.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? tag.color : Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  ),

                  const SizedBox(height: 24),

                  // メモ入力
                  TextField(
                    controller: _memoController,
                    readOnly: isReadOnly,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'メモ',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      hintText: isReadOnly ? '' : '備考など',
                    ),
                  ),
                  if (isReadOnly)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text('閲覧専用（編集できません）', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(isReadOnly ? '閉じる' : 'キャンセル', style: const TextStyle(color: Colors.grey)),
                  ),
                  if (!isReadOnly) ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _saveAndClose(ref),
                      child: const Text('保存'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveAndClose(WidgetRef ref) {
    _saveShift(ref);
    Navigator.pop(context);
  }

  void _saveAndPrevious(WidgetRef ref) {
    final didSave = _saveShift(ref);
    if (didSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存しました'), duration: Duration(milliseconds: 500)),
      );
    }
    _moveDay(ref, -1);
  }

  void _saveAndNext(WidgetRef ref) {
    final didSave = _saveShift(ref);
    if (didSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存しました'), duration: Duration(milliseconds: 500)),
      );
    }
    _moveDay(ref, 1);
  }

  void _moveDay(WidgetRef ref, int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      
      final shiftsMap = ref.read(calendarNotifierProvider).value ?? {};
      final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final targetDayShifts = shiftsMap[dateOnly] ?? [];

      _selectedTagIds.clear();
      _memoController.clear();
      _existingId = null;

      if (targetDayShifts.isNotEmpty) {
        final first = targetDayShifts.first;
        _existingId = first.id;
        _selectedTagIds.addAll(first.tagIds);
        _memoController.text = first.memo ?? '';
      }
      
      _recordInitialState();
    });
  }

  bool _saveShift(WidgetRef ref) {
    if (!_hasChanges()) return false;

    final shift = Shift(
      id: _existingId ?? const Uuid().v4(),
      profileId: 'my_id',
      tagIds: _selectedTagIds.toList(),
      date: _selectedDate,
      memo: _memoController.text,
    );
    ref.read(calendarNotifierProvider.notifier).addShift(shift);
    return true;
  }
}
