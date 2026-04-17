import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/supabase_client.dart';
import '../../../utils/encryption_service.dart';
import '../../calendar/repository/shift_repository.dart';
import '../../calendar/repository/shift_tag_repository.dart';
import '../../calendar/model/shift.dart';
import '../../calendar/model/shift_tag.dart';

class SyncRepository {
  final SupabaseClient _client = supabase;
  final ShiftRepository _shiftRepository;
  final ShiftTagRepository _tagRepository;

  SyncRepository({
    required ShiftRepository shiftRepository,
    required ShiftTagRepository tagRepository,
  }) : _shiftRepository = shiftRepository,
       _tagRepository = tagRepository;

  /// クラウドへデータをアップロード (E2EE)
  /// マルチユーザー対応版: 他人のデータを消さずに自分のデータを上書き/追加
  Future<void> uploadData(String roomId, String password) async {
    final encryptionService = EncryptionService(password: password);
    
    // 1. 既存のクラウドデータを取得してデコード
    Map<String, dynamic> profilesMap = {};
    final response = await _client
        .from('shared_calendars')
        .select('encrypted_payload')
        .eq('room_id', roomId)
        .maybeSingle();

    if (response != null) {
      final oldPayload = response['encrypted_payload'] as String;
      try {
        final decoded = encryptionService.decryptData(oldPayload);
        final fullData = jsonDecode(decoded) as Map<String, dynamic>;
        profilesMap = Map<String, dynamic>.from(fullData['profiles'] ?? {});
      } catch (e) {
        // 復号化失敗＝パスワード変更か初回。空から開始
      }
    }

    // 2. 自分のローカルデータを取得
    final tags = await _tagRepository.getTags();
    final shifts = await _shiftRepository.getAllShifts();
    
    final myCurrentData = {
      'name': '自分', // TODO: 将来的にユーザー設定から取得可能にする
      'tags': tags.map((t) => t.toMap()).toList(),
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // 3. マップに自分のデータを結合 (固定ID 'my_id' を使用)
    profilesMap['my_id'] = myCurrentData;

    // 4. 暗号化してアップロード
    final jsonString = jsonEncode({'profiles': profilesMap});
    final encryptedPayload = encryptionService.encryptData(jsonString);

    await _client.from('shared_calendars').upsert({
      'room_id': roomId,
      'encrypted_payload': encryptedPayload,
    });
  }

  /// クラウドから自分のデータのみをダウンロードして復元 (E2EE)
  Future<void> downloadData(String roomId, String password) async {
    final fullData = await fetchAllProfiles(roomId, password);
    if (fullData == null) return;

    final profiles = fullData['profiles'] as Map<String, dynamic>?;
    if (profiles == null || !profiles.containsKey('my_id')) return;

    final myData = profiles['my_id'] as Map<String, dynamic>;
    
    final tags = (myData['tags'] as List)
        .map((m) => ShiftTag.fromMap(m as Map<String, dynamic>))
        .toList();
    
    final shifts = (myData['shifts'] as List)
        .map((m) => Shift.fromMap(m as Map<String, dynamic>))
        .toList();

    // ローカル更新
    await _tagRepository.replaceTags(tags);
    await _shiftRepository.replaceShifts(shifts);
  }

  /// ルーム内の全ユーザーのデータを取得 (Holiday Finder用)
  Future<Map<String, dynamic>?> fetchAllProfiles(String roomId, String password) async {
    final response = await _client
        .from('shared_calendars')
        .select('encrypted_payload')
        .eq('room_id', roomId)
        .maybeSingle();

    if (response == null) return null;

    final encryptedPayload = response['encrypted_payload'] as String;
    final encryptionService = EncryptionService(password: password);
    final jsonString = encryptionService.decryptData(encryptedPayload);

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
