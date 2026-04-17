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
        .select('encrypted_data')
        .eq('id', roomId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('該当するユーザーIDが見つかりません');
    }

    final encryptedPayload = response['encrypted_data'] as String;
    final encryptionService = EncryptionService(password: password);
    
    final jsonString = encryptionService.decryptData(encryptedPayload);

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// クラウドへデータをアップロード (E2EE)
  Future<void> uploadData(String roomId, String password, String userName) async {
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

    // ルームID単位でデータを管理するため、1つのIDに1つの暗号化ペイロードを保存
    final jsonString = jsonEncode({'profiles': {userName: myCurrentData}});
    final encryptedPayload = encryptionService.encryptData(jsonString);

    try {
      await _client.from('shared_shifts').upsert({
        'id': roomId,
        'encrypted_data': encryptedPayload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
    } on PostgrestException catch (e) {
      // 400 Bad Request 等の詳細なデバッグ情報を出力
      // ignore: avoid_print
      print('--- Supabase Upsert Error ---');
      // ignore: avoid_print
      print('Message: ${e.message}');
      // ignore: avoid_print
      print('Details: ${e.details}');
      // ignore: avoid_print
      print('Hint: ${e.hint}');
      // ignore: avoid_print
      print('Code: ${e.code}');
      rethrow;
    }
  }

  /// クラウドからデータをダウンロードして復元 (E2EE)
  Future<void> downloadData(String roomId, String password, String userName) async {
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
  }

  /// ルーム内のデータを取得 (Holiday Finder用)
  Future<Map<String, dynamic>?> fetchAllProfiles(String roomId, String password) async {
    final response = await _client
        .from('shared_shifts')
        .select('encrypted_data')
        .eq('id', roomId)
        .maybeSingle();

    if (response == null) return null;

    final encryptionService = EncryptionService(password: password);
    final encryptedPayload = response['encrypted_data'] as String;
      
    try {
      final jsonString = encryptionService.decryptData(encryptedPayload);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // 復号化失敗
      return null;
    }
  }
}
