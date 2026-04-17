import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/theme_provider.dart';
import '../../../utils/app_theme.dart';
import '../../sync/provider/sync_settings_provider.dart';
import '../../sync/provider/sync_provider.dart';
import 'tag_management_page.dart';
import 'holiday_finder_page.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);
    final syncSettings = ref.watch(syncSettingsNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '設定',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              
              // --- テーマ設定 ---
              Text(
                'テーマ設定',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: AppThemeType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: currentTheme == type,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(themeNotifierProvider.notifier).setTheme(type);
                      }
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              
              // --- シフトタグ管理 ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.label_outline),
                title: const Text('シフトタグの管理'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TagManagementPage()),
                  );
                },
              ),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_outline, color: Colors.green),
                title: const Text('共通の休みを探す'),
                subtitle: const Text('ルーム内の全員のシフトを照合'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HolidayFinderPage()),
                  );
                },
              ),
              
              const Divider(),
              const SizedBox(height: 16),
              
              // --- クラウド同期 (E2EE) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'クラウド同期 (E2EE)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: syncSettings.isEnabled,
                    onChanged: (value) {
                      ref.read(syncSettingsNotifierProvider.notifier).setEnabled(value);
                    },
                  ),
                ],
              ),
              const Text(
                'ルームIDとパスワードを使用して、暗号化されたデータを同期します。サーバー側からは内容は解読できません。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              if (syncSettings.isEnabled) ...[
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'ルームID',
                    hintText: '例: family-room-123',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref.read(syncSettingsNotifierProvider.notifier).updateSettings(
                    syncSettings.copyWith(roomId: value)
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '暗号化パスワード',
                    hintText: '共有する相手と同じパスワード',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref.read(syncSettingsNotifierProvider.notifier).updateSettings(
                    syncSettings.copyWith(password: value)
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Supabase 接続情報:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Supabase URL',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref.read(syncSettingsNotifierProvider.notifier).updateSettings(
                    syncSettings.copyWith(supabaseUrl: value)
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Supabase Anon Key',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref.read(syncSettingsNotifierProvider.notifier).updateSettings(
                    syncSettings.copyWith(supabaseAnonKey: value)
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: syncState.isLoading 
                      ? null 
                      : () => ref.read(syncNotifierProvider.notifier).pushAll(syncSettings.roomId, syncSettings.password),
                    icon: syncState.isLoading 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                    label: const Text('今すぐ同期 (アップロード)'),
                  ),
                ),
                if (syncState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '同期エラー: ${syncState.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
