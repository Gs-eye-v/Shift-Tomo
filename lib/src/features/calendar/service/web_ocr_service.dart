import 'package:image_picker/image_picker.dart';
import '../model/shift_tag.dart';
import 'ocr_service.dart';

// Web用ファクトリ関数
OcrService getOcrService() => WebOcrService();

class WebOcrService implements OcrService {
  @override
  Future<List<OcrMatch>> scanImage(XFile image, List<ShiftTag> tags) async {
    // Web環境では現在は未対応
    return [];
  }

  @override
  void dispose() {
    // な心
  }
}
