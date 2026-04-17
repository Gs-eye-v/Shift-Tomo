import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/sync_provider.dart';
import '../provider/sync_settings_provider.dart';

class SyncDialog extends ConsumerStatefulWidget {
  const SyncDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SyncDialog(),
    );
  }

  @override
  ConsumerState<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends ConsumerState<SyncDialog> {
  late final TextEditingController _roomIdController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(syncSettingsNotifierProvider);
    _roomIdController = TextEditingController(text: settings.roomId);
    _passwordController = TextEditingController(text: settings.password);
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_sync, color: Colors.blue),
          SizedBox(width: 8),
          Text('クラウド同期 (E2EE)'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supabaseを介してデータを共有します。\nAES-256で暗号化されるため安全です。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(
                labelText: 'ルームID',
                hintText: '例: shared-calendar-01',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room),
              ),
              onChanged: (val) => ref.read(syncSettingsNotifierProvider.notifier).updateRoomId(val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '暗号化パスワード',
                hintText: '共通鍵として使用します',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onChanged: (val) => ref.read(syncSettingsNotifierProvider.notifier).updatePassword(val),
            ),
            if (syncState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('通信中...', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: syncState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        ElevatedButton.icon(
          onPressed: syncState.isLoading ? null : () => _handleSync(isUpload: true),
          icon: const Icon(Icons.upload, size: 18),
          label: const Text('アップロード'),
        ),
        ElevatedButton.icon(
          onPressed: syncState.isLoading ? null : () => _handleSync(isUpload: false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('ダウンロード'),
        ),
      ],
    );
  }

  Future<void> _handleSync({required bool isUpload}) async {
    final roomId = _roomIdController.text.trim();
    final password = _passwordController.text.trim();

    if (roomId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルームIDとパスワードを入力してください')),
      );
      return;
    }

    try {
      if (isUpload) {
        await ref.read(syncNotifierProvider.notifier).pushAll(roomId, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('アップロードが完了しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await ref.read(syncNotifierProvider.notifier).pullAll(roomId, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ダウンロードとデータの更新が完了しました'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
