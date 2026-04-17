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

  /// 指定したユーザーIDが使用可能（存在しない）かチェック
  Future<bool> isRoomIdAvailable(String id) async {
    final response = await _client
        .from('shared_shifts')
        .select('id')
        .eq('id', id)
        .maybeSingle();
    return response == null;
  }

  /// 指定したユーザーIDを削除
  Future<void> deleteRoom(String id) async {
    await _client
        .from('shared_shifts')
        .delete()
        .eq('id', id);
  }

  /// 友達追加時の検証: ユーザーID存在確認と復号化チェックを行い、失敗時は例外を投げる
  Future<Map<String, dynamic>> validateAndFetchProfiles(String roomId, String password) async {
    final response = await _client
        .from('shared_shifts')
        .select('encrypted_data, device_id')
        .eq('room_id', roomId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('該当するユーザーIDが見つかりません');
    }

    final encryptedPayload = response['encrypted_data'] as String;
    final encryptionService = EncryptionService(password: password);
    
    final jsonString = encryptionService.decryptData(encryptedPayload);

    // アクセス日時を更新 (最初に見つかったデバイスのみ)
    final deviceId = response['device_id'] as String;
    await _updateAccessTimestamp(deviceId);

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// クラウドへデータをアップロード (E2EE)
  /// 端末IDベースの上書き保存対応
  Future<void> uploadData(String roomId, String password, String userName, String deviceId) async {
    final encryptionService = EncryptionService(password: password);
    
    // 自分のローカルデータを取得
    final tags = await _tagRepository.getTags();
    final shifts = await _shiftRepository.getAllShifts();
    
    final myCurrentData = {
      'name': userName,
      'tags': tags.map((t) => t.toMap()).toList(),
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // 自分のデバイス専用のデータを暗号化 (以前の他者マージは不要)
    final jsonString = jsonEncode({'profiles': {userName: myCurrentData}});
    final encryptedPayload = encryptionService.encryptData(jsonString);

    await _client.from('shared_shifts').upsert({
      'device_id': deviceId,
      'room_id': roomId,
      'encrypted_data': encryptedPayload,
      'last_accessed_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'device_id');
  }

  /// クラウドから自分のデータのみをダウンロードして復元 (E2EE)
  Future<void> downloadData(String roomId, String password, String userName, String deviceId) async {
    final fullData = await fetchAllProfiles(roomId, password);
    if (fullData == null) return;

    final profiles = fullData['profiles'] as Map<String, dynamic>?;
    if (profiles == null || !profiles.containsKey(userName)) return;

    final myData = profiles[userName] as Map<String, dynamic>;
    
    final tags = (myData['tags'] as List)
        .map((m) => ShiftTag.fromMap(m as Map<String, dynamic>))
        .toList();
    
    final shifts = (myData['shifts'] as List)
        .map((m) => Shift.fromMap(m as Map<String, dynamic>))
        .toList();

    // ローカル更新
    await _tagRepository.replaceTags(tags);
    await _shiftRepository.replaceShifts(shifts);

    // 自分のアクセス日時を更新
    await _updateAccessTimestamp(deviceId);
  }

  /// ルーム内の全ユーザーのデータを取得 (Holiday Finder用)
  /// 複数デバイスのデータをマージして返す
  Future<Map<String, dynamic>?> fetchAllProfiles(String roomId, String password) async {
    final response = await _client
        .from('shared_shifts')
        .select('encrypted_data, device_id')
        .eq('room_id', roomId);

    if (response == null || (response as List).isEmpty) return null;

    final List<dynamic> rows = response as List<dynamic>;
    Map<String, dynamic> mergedProfiles = {};
    final encryptionService = EncryptionService(password: password);

    for (final row in rows) {
      final encryptedPayload = row['encrypted_data'] as String;
      final deviceId = row['device_id'] as String;
      
      try {
        final jsonString = encryptionService.decryptData(encryptedPayload);
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final profiles = data['profiles'] as Map<String, dynamic>?;
        if (profiles != null) {
          mergedProfiles.addAll(profiles);
        }
        
        // アクセス日時を更新 (一括ダウンロード時も各デバイスの生存時間を延ばす)
        await _updateAccessTimestamp(deviceId);
      } catch (e) {
        // 復号化失敗はスキップ
      }
    }

    if (mergedProfiles.isEmpty) return null;
    return {'profiles': mergedProfiles};
  }

  Future<void> _updateAccessTimestamp(String deviceId) async {
    try {
      await _client
          .from('shared_shifts')
          .update({'last_accessed_at': DateTime.now().toUtc().toIso8601String()})
          .eq('device_id', deviceId);
    } catch (e) {
      // 日時更新の失敗は致命的ではないため無視
    }
  }
}
