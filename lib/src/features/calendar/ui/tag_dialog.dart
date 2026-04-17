import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../model/shift_tag.dart';

class TagDialog extends StatefulWidget {
  final ShiftTag? tag;

  const TagDialog({super.key, this.tag});

  static Future<ShiftTag?> show(BuildContext context, {ShiftTag? tag}) {
    return showDialog<ShiftTag>(
      context: context,
      builder: (context) => TagDialog(tag: tag),
    );
  }

  @override
  State<TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<TagDialog> {
  late TextEditingController _titleController;
  late TextEditingController _watermarkController;
  late TextEditingController _emojiController;
  late TextEditingController _hourlyWageController;
  late TextEditingController _breakMinutesController;
  
  String? _startTime;
  String? _endTime;
  late bool _isDayOff;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tag?.title);
    _watermarkController = TextEditingController(text: widget.tag?.watermarkChar);
    _emojiController = TextEditingController(text: widget.tag?.emoji);
    _hourlyWageController = TextEditingController(
      text: widget.tag?.hourlyWage?.toString() ?? '',
    );
    _breakMinutesController = TextEditingController(
      text: widget.tag?.breakMinutes.toString() ?? '60',
    );
    _startTime = widget.tag?.startTime;
    _endTime = widget.tag?.endTime;
    _isDayOff = widget.tag?.isDayOff ?? false;
    _selectedColor = widget.tag?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _watermarkController.dispose();
    _emojiController.dispose();
    _hourlyWageController.dispose();
    _breakMinutesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _startTime = timeStr;
        } else {
          _endTime = timeStr;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? 'タグを作成' : 'タグを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'タイトル', hintText: '例: 早番'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _watermarkController,
                    decoration: const InputDecoration(labelText: '透かし', hintText: '早'),
                    maxLength: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _emojiController,
                    decoration: const InputDecoration(labelText: '絵文字', hintText: '☀️'),
                  ),
                ),
              ],
            ),
            
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('これは休日ですか？', style: TextStyle(fontSize: 14)),
              subtitle: const Text('オンにすると共通の休み判定に使用されます', style: TextStyle(fontSize: 11)),
              value: _isDayOff,
              onChanged: (val) => setState(() => _isDayOff = val),
            ),
            
            if (!_isDayOff) ...[
              const Divider(),
              const Text('勤務時間・給与', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(true),
                      child: Text(_startTime ?? '開始時間'),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('~')),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(false),
                      child: Text(_endTime ?? '終了時間'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hourlyWageController,
                      decoration: const InputDecoration(labelText: '時給 (円)', hintText: '1200'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _breakMinutesController,
                      decoration: const InputDecoration(labelText: '休憩 (分)', hintText: '60'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            const Text('ラベルカラー', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink].map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
                    ),
                    child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: () {
            final tag = ShiftTag(
              id: widget.tag?.id ?? const Uuid().v4(),
              title: _titleController.text,
              watermarkChar: _watermarkController.text,
              emoji: _emojiController.text,
              color: _selectedColor,
              startTime: _startTime,
              endTime: _endTime,
              breakMinutes: int.tryParse(_breakMinutesController.text) ?? 60,
              hourlyWage: int.tryParse(_hourlyWageController.text),
              isDayOff: _isDayOff,
            );
            Navigator.pop(context, tag);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
