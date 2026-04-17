import 'package:image_picker/image_picker.dart';
import '../model/shift_tag.dart';
import 'native_ocr_service.dart' if (dart.library.html) 'web_ocr_service.dart';

abstract class OcrService {
  /// プラットフォームに応じたサービスインスタンスを生成
  factory OcrService() => getOcrService();

  Future<List<OcrMatch>> scanImage(XFile image, List<ShiftTag> tags);
  void dispose();
}

class OcrMatch {
  final int day;
  final ShiftTag tag;
  final double confidence;

  OcrMatch({
    required this.day,
    required this.tag,
    this.confidence = 1.0,
  });
}
