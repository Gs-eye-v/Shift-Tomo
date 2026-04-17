import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/shift.dart';
import '../provider/tag_provider.dart';
import '../provider/calendar_provider.dart';

class ShiftDialog extends StatefulWidget {
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
  State<ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends State<ShiftDialog> {
  late DateTime _selectedDate;
  final Set<String> _selectedTagIds = {};
  late TextEditingController _memoController;
  String? _existingId;

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

        return AlertDialog(
          title: const Text('シフトを編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 日付選択
                ListTile(
                  title: const Text('日付'),
                  subtitle: Text('${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
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

                const SizedBox(height: 16),

                // タグ複数選択
                tagsAsync.when(
                  data: (tags) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('タグを選択（複数可）', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((tag) {
                            final isSelected = _selectedTagIds.contains(tag.id);
                            return FilterChip(
                              label: Text('${tag.emoji} ${tag.title}'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTagIds.add(tag.id);
                                  } else {
                                    _selectedTagIds.remove(tag.id);
                                  }
                                });
                              },
                              selectedColor: tag.color.withOpacity(0.5),
                              checkmarkColor: Colors.black,
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Error: $e'),
                ),

                const SizedBox(height: 16),

                // メモ入力
                TextField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    labelText: 'メモ',
                    border: OutlineInputBorder(),
                    hintText: '備考など',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            OutlinedButton(
              onPressed: () => _saveAndPrevious(ref),
              child: const Text('前へ'),
            ),
            OutlinedButton(
              onPressed: () => _saveAndNext(ref),
              child: const Text('次へ'),
            ),
            ElevatedButton(
              onPressed: () => _saveAndClose(ref),
              child: const Text('保存'),
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
    _saveShift(ref);
    _moveDay(ref, -1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました。前の日を入力してください'), duration: Duration(seconds: 1)),
    );
  }

  void _saveAndNext(WidgetRef ref) {
    _saveShift(ref);
    _moveDay(ref, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました。次の日を入力してください'), duration: Duration(seconds: 1)),
    );
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
    });
  }

  void _saveShift(WidgetRef ref) {
    final shift = Shift(
      id: _existingId ?? const Uuid().v4(),
      profileId: 'my_id',
      tagIds: _selectedTagIds.toList(),
      date: _selectedDate,
      memo: _memoController.text,
    );
    ref.read(calendarNotifierProvider.notifier).addShift(shift);
  }
}
