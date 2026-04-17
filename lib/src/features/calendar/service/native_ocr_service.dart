import 'dart:math';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../model/shift_tag.dart';
import 'ocr_service.dart';

// ネイティブ用ファクトリ関数
OcrService getOcrService() => NativeOcrService();

class NativeOcrService implements OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  @override
  Future<List<OcrMatch>> scanImage(XFile image, List<ShiftTag> tags) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    final List<_TextElementInfo> elements = [];

    // すべてのテキスト要素（単語単位）をフラットなリストに抽出
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          elements.add(_TextElementInfo(
            text: element.text,
            rect: element.boundingBox,
            center: Offset(
              element.boundingBox.left + element.boundingBox.width / 2,
              element.boundingBox.top + element.boundingBox.height / 2,
            ),
          ));
        }
      }
    }

    final List<OcrMatch> matches = [];

    // 1. 日付と思われる数字 (1-31) を探す
    final dateElements = elements.where((e) {
      final val = int.tryParse(e.text);
      return val != null && val >= 1 && val <= 31;
    }).toList();

    // 2. 各日付に対して、最も近い位置にある「シフトタグ」を特定する
    for (final dateEl in dateElements) {
      final day = int.parse(dateEl.text);
      
      ShiftTag? bestTag;
      double minDistance = double.infinity;

      for (final tag in tags) {
        // タグのタイトルまたは透かし文字に一致する近傍テキストを探す
        final nearbyElements = elements.where((e) => 
          e.text.contains(tag.title) || 
          (tag.watermarkChar.isNotEmpty && e.text.contains(tag.watermarkChar))
        );

        for (final el in nearbyElements) {
          // 日付要素とテキスト要素の距離を計算
          final dist = _calculateDistance(dateEl.center, el.center);
          
          if (dist < minDistance && dist < 300) { // 300pixel以内などの閾値を設ける
            minDistance = dist;
            bestTag = tag;
          }
        }
      }

      if (bestTag != null) {
        matches.add(OcrMatch(day: day, tag: bestTag));
      }
    }

    return matches;
  }

  double _calculateDistance(Offset p1, Offset p2) {
    return sqrt(pow(p1.dx - p2.dx, 2) + pow(p1.dy - p2.dy, 2));
  }

  @override
  void dispose() {
    _textRecognizer.close();
  }
}

class _TextElementInfo {
  final String text;
  final Rect rect;
  final Offset center;

  _TextElementInfo({required this.text, required this.rect, required this.center});
}
