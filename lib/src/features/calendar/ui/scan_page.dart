import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../model/shift.dart';
import '../provider/calendar_provider.dart';
import '../provider/ocr_provider.dart';
import '../provider/tag_provider.dart';
import '../service/ocr_service.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  XFile? _image;
  List<OcrMatch> _results = [];
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // 実際の実装ではユーザーがカメラかギャラリーか選べるのが望ましいが、要件に従いカメラを優先。
    // Webやデスクトップを考慮し gallery も選択肢として表示
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像を選択'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text('ギャラリー')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text('カメラ')),
        ],
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _isProcessing = true;
      });
      await _processImage(pickedFile);
    }
  }

  Future<void> _processImage(XFile image) async {
    final tagsAsync = ref.read(tagNotifierProvider);
    final tags = tagsAsync.value ?? [];
    
    try {
      final results = await ref.read(ocrServiceProvider).scanImage(image, tags);
      if (mounted) {
        setState(() {
          _results = results;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR読み取りエラー: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveResults() async {
    final focusedMonth = ref.read(focusedMonthProvider);
    final List<Shift> shiftsToAdd = [];

    for (final match in _results) {
      shiftsToAdd.add(Shift(
        id: const Uuid().v4(),
        profileId: 'my_id',
        tagIds: [match.tag.id],
        date: DateTime(focusedMonth.year, focusedMonth.month, match.day),
      ));
    }

    if (shiftsToAdd.isEmpty) return;

    await ref.read(calendarNotifierProvider.notifier).addMultipleShifts(shiftsToAdd);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${shiftsToAdd.length}件のシフトを登録しました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト表スキャン'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? _buildLoadingView()
          : _image == null
              ? _buildImagePickerView()
              : _buildResultsView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('シフトを読み取り中...'),
        ],
      ),
    );
  }

  Widget _buildImagePickerView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.document_scanner_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              '紙のシフト表やPC画面の写真を撮って\nカレンダーに一気に流し込みます。',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('写真を選択・撮影する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Text(
            '${_results.length}個のシフトを検出しました。内容を確認して保存してください。',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _results.isEmpty 
            ? const Center(child: Text('シフトを検出できませんでした。\n明るい場所で文字がはっきり写るように撮影してください。', textAlign: TextAlign.center))
            : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final match = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text('${match.day}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(match.tag.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(match.tag.emoji, style: const TextStyle(fontSize: 24)),
                  );
                },
              ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _image = null;
                      _results = [];
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.orange),
                      foregroundColor: Colors.orange,
                    ),
                    child: const Text('撮り直す'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _results.isEmpty ? null : _saveResults,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('登録を確定する'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
