import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/ocr_service.dart';

part 'ocr_provider.g.dart';

@riverpod
OcrService ocrService(OcrServiceRef ref) {
  // サービス側のインターフェースで定義された factory constructor もしくは 
  // OcrService() を通じてプラットフォーム固有のインスタンスを取得
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
}
