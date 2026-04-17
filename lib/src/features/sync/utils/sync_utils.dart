import 'dart:convert';
import '../../calendar/model/shift.dart';
import '../../calendar/model/shift_tag.dart';

class SyncUtils {
  /// シフトとタグの情報をソートされた安定したJSON文字列に変換する
  static String canonicalize(Map<DateTime, List<Shift>> shiftsMap, List<ShiftTag> tags) {
    // タグをID順にソート
    final sortedTags = [...tags]..sort((a, b) => a.id.compareTo(b.id));
    
    // 全てのシフトをフラットにしてID順にソート
    final allShifts = shiftsMap.values.expand((list) => list).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final data = {
      'tags': sortedTags.map((t) => t.toMap()).toList(),
      'shifts': allShifts.map((s) => s.toMap()).toList(),
    };

    return jsonEncode(data);
  }
}
