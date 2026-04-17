import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/sync_repository.dart';
import '../../calendar/provider/repository_provider.dart';
import '../../calendar/provider/calendar_provider.dart';
import '../../calendar/provider/tag_provider.dart';

part 'sync_provider.g.dart';

@riverpod
SyncRepository syncRepository(SyncRepositoryRef ref) {
  return SyncRepository(
    shiftRepository: ref.watch(shiftRepositoryProvider),
    tagRepository: ref.watch(shiftTagRepositoryProvider),
  );
}

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  FutureOr<void> build() async {
    // 初期化時は何もしない
  }

  Future<void> pushAll(String roomId, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(syncRepositoryProvider).uploadData(roomId, password);
    });
  }

  Future<void> pullAll(String roomId, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(syncRepositoryProvider).downloadData(roomId, password);
      // ローカルの状態を更新するためにリフレッシュをトリガー
      ref.invalidate(calendarNotifierProvider);
      ref.invalidate(tagNotifierProvider);
    });
  }
}
