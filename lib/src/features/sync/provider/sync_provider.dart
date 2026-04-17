import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/sync_repository.dart';
import '../../calendar/provider/repository_provider.dart';
import '../../calendar/provider/calendar_provider.dart';
import '../../calendar/provider/tag_provider.dart';
import '../../../utils/encryption_service.dart';
import '../../calendar/provider/view_state_provider.dart';
import '../utils/sync_utils.dart';
import '../../../utils/notification_service.dart';
import '../../calendar/model/shift.dart'; // 追加
import '../../calendar/provider/app_settings_provider.dart'; // 追加
import '../../sync/provider/partner_provider.dart';

part 'sync_provider.g.dart';

@riverpod
SyncRepository syncRepository(SyncRepositoryRef ref) {
  return SyncRepository(
    shiftRepository: ref.watch(shiftRepositoryProvider),
    tagRepository: ref.watch(shiftTagRepositoryProvider),
  );
}

/// 最後に同期（または起動時に読み込み）に成功したデータのスナップショットを保持
@Riverpod(keepAlive: true)
class SyncSnapshot extends _$SyncSnapshot {
  @override
  String? build() => null;

  void update(String data) {
    state = data;
  }
}

/// 同期が必要かどうかをデータ差分で自動判定するプロバイダー
@Riverpod(keepAlive: true)
bool isSyncRequired(IsSyncRequiredRef ref) {
  final lastSynced = ref.watch(syncSnapshotProvider);
  if (lastSynced == null) return false;

  final shiftsMap = ref.watch(calendarNotifierProvider).value;
  final tags = ref.watch(tagNotifierProvider).value;

  if (shiftsMap == null || tags == null) return false;

  // 閲覧専用モードなら同期の必要なし
  final viewUser = ref.watch(calendarViewUserNotifierProvider);
  if (!viewUser.isMe) return false;

  final currentJson = SyncUtils.canonicalize(shiftsMap, tags);
  return currentJson != lastSynced;
}

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  FutureOr<void> build() async {
    // 初期化時は何もしない
  }

  /// 現在の状態をスナップショットとして記録する（初期化時や保存成功時）
  void captureSnapshot() {
    final shiftsMap = ref.read(calendarNotifierProvider).value;
    final tags = ref.read(tagNotifierProvider).value;
    if (shiftsMap != null && tags != null) {
      final json = SyncUtils.canonicalize(shiftsMap, tags);
      ref.read(syncSnapshotProvider.notifier).update(json);
    }
  }

  Future<void> pushAll(String roomId, String password, String userName) async {
    // 安全装置: 閲覧専用モード（パートナー表示中）ならアップロードを拒否
    final viewUser = ref.read(calendarViewUserNotifierProvider);
    if (!viewUser.isMe) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(syncRepositoryProvider).uploadData(roomId, password, userName);
      // 保存成功時にスナップショットを更新
      captureSnapshot();
    });
  }

  Future<void> pullAll(String roomId, String password, String userName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(syncRepositoryProvider).downloadData(roomId, password, userName);
        
        // ローカルの状態を更新
        ref.invalidate(calendarNotifierProvider);
        ref.invalidate(tagNotifierProvider);
        
        // データが確定してから同期処理を実行（少し遅延させて待機）
        Future.delayed(const Duration(milliseconds: 500), () async {
          captureSnapshot();
          
          // 通知予約の更新（自分 + パートナー）
          final myShiftsRaw = await ref.read(shiftRepositoryProvider).getAllShifts();
          final tags = ref.read(tagNotifierProvider).value ?? [];
          final partners = ref.read(partnerNotifierProvider).value ?? [];
          
          final Map<DateTime, List<Shift>> myShiftsMap = {};
          for (final s in myShiftsRaw) {
            final d = DateTime(s.date.year, s.date.month, s.date.day);
            myShiftsMap[d] = (myShiftsMap[d] ?? [])..add(s);
          }
          
          final Map<String, Map<DateTime, List<Shift>>> partnerShiftsMap = {};
          final syncRepo = ref.read(syncRepositoryProvider);
          
          for (final partner in partners) {
            try {
              final profiles = await syncRepo.validateAndFetchProfiles(partner.roomId, partner.password);
              final profileData = (profiles['profiles'] as Map? ?? {})[partner.profileName];
              
              if (profileData != null) {
                final shiftsJson = profileData['shifts'] as List? ?? [];
                final shifts = shiftsJson.map((m) => Shift.fromMap(m as Map<String, dynamic>)).toList();
                
                final Map<DateTime, List<Shift>> pMap = {};
                for (final s in shifts) {
                  final d = DateTime(s.date.year, s.date.month, s.date.day);
                  pMap[d] = (pMap[d] ?? [])..add(s);
                }
                partnerShiftsMap[partner.displayName] = pMap;
              }
            } catch (_) {}
          }
          
          NotificationService().syncAllNotifications(
            myShifts: myShiftsMap,
            tags: tags,
            appSettings: ref.read(appSettingsNotifierProvider),
            partnerShifts: partnerShiftsMap,
          );
        });
      } on DecryptionException catch (e) {
        throw Exception('パスワードが正しくないか、データが壊れています。(${e.message})');
      } catch (e) {
        rethrow;
      }
    });
  }
}
