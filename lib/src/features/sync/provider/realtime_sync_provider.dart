import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 追加
import '../../../utils/supabase_client.dart';
import 'sync_settings_provider.dart';
import 'sync_provider.dart';

part 'realtime_sync_provider.g.dart';

@riverpod
class RealtimeSyncNotifier extends _$RealtimeSyncNotifier {
  RealtimeChannel? _channel;

  @override
  void build() {
    final settings = ref.watch(syncSettingsNotifierProvider);
    
    if (settings.isEnabled && settings.roomId.isNotEmpty && settings.password.isNotEmpty) {
      // 1. 初回のデータ同期を実行 (非同期)
      _initialSync(settings.roomId, settings.password, settings.userName, settings.deviceId);
      
      // 2. リアルタイムリスナーを開始
      _subscribe(settings.roomId, settings.password, settings.userName, settings.deviceId);
    } else {
      _unsubscribe();
    }

    ref.onDispose(() => _unsubscribe());
  }

  /// 起動時または設定変更時の初回同期
  Future<void> _initialSync(String roomId, String password, String userName, String deviceId) async {
    // buildの直後に実行されるように microtask を使用
    Future.microtask(() async {
      try {
        await ref.read(syncNotifierProvider.notifier).pullAll(roomId, password, userName);
      } catch (e) {
        // 初回同期のエラーはNotifier側で処理される想定
      }
    });
  }

  void _subscribe(String roomId, String password, String userName, String deviceId) {
    _unsubscribe();

    _channel = supabase
        .channel('public:shared_shifts:id=eq.$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'shared_shifts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            // リモート更新を検知
            _handleRemoteUpdate(roomId, password, userName, deviceId);
          },
        )
        .subscribe();
  }

  void _unsubscribe() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  Future<void> _handleRemoteUpdate(String roomId, String password, String userName, String deviceId) async {
    // データをプルしてローカルを更新
    await ref.read(syncNotifierProvider.notifier).pullAll(roomId, password, userName);
    
    // 通知用の状態を更新
    ref.read(remoteUpdateEventProvider.notifier).trigger();
  }
}

@riverpod
class RemoteUpdateEvent extends _$RemoteUpdateEvent {
  @override
  DateTime? build() => null;

  void trigger() {
    state = DateTime.now();
  }
}
