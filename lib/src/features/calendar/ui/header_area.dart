import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'settings_sheet.dart';
import 'shift_dialog.dart';
import '../../sync/ui/add_friend_dialog.dart';
import 'scan_page.dart';
import 'holiday_finder_page.dart';
import '../../sync/provider/sync_settings_provider.dart'; // 再追加
import '../../sync/provider/sync_provider.dart';
import 'tag_management_page.dart';

class HeaderArea extends ConsumerWidget {
  const HeaderArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDefault = theme.colorScheme.primary == const Color(0xFF2ECC71); // Mint

    // テーマに応じたグラデーション設定
    List<Color> gradientColors;
    if (isDark) {
      gradientColors = [
        const Color(0xFF1E1E1E),
        const Color(0xFF0D1B2A).withOpacity(0.9), // Deep Navy
      ];
    } else if (!isDefault) {
      // パステルの場合
      gradientColors = [
        const Color(0xFFF06292).withOpacity(0.8), // Pastel Pink
        const Color(0xFFBA68C8).withOpacity(0.8), // Pastel Purple
      ];
    } else {
      // デフォルトの場合
      gradientColors = [
        const Color(0xFF2ECC71), // Mint
        const Color(0xFF3498DB).withOpacity(0.8), // Sky Blue
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'シフトモ',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.person_add_outlined,
              tooltip: '友達を追加',
              onPressed: () => AddFriendDialog.show(context),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.share_outlined,
              tooltip: '共有リンクをコピー',
              onPressed: () => _handleShare(context, ref),
            ),
            const SizedBox(width: 8),
            
            // クラウド保存ボタン（差分がある場合のみ表示）
            if (ref.watch(isSyncRequiredProvider)) ...[
              _HeaderIcon(
                icon: Icons.cloud_upload_outlined,
                tooltip: 'クラウドに保存',
                color: const Color(0xFFFFD700),
                onPressed: () => _handleCloudPush(context, ref),
              ),
              const SizedBox(width: 8),
            ],

            _HeaderIcon(
              icon: Icons.photo_camera_outlined,
              tooltip: 'カメラで読み取り',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanPage()),
              ),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.add_circle_outline,
              tooltip: 'シフトを追加',
              onPressed: () => ShiftDialog.show(context),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.style_outlined,
              tooltip: 'タグ管理',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TagManagementPage()),
              ),
            ),
            const SizedBox(width: 8),
            _HeaderIcon(
              icon: Icons.settings_outlined,
              tooltip: '設定',
              onPressed: () => SettingsSheet.show(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCloudPush(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(syncSettingsNotifierProvider);
    if (settings.roomId.isEmpty || settings.password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定画面からユーザーIDとパスワードを設定してください'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await ref.read(syncNotifierProvider.notifier).pushAll(
        settings.roomId,
        settings.password,
        settings.userName,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クラウドに保存しました'), backgroundColor: Color(0xFF2ECC71)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleShare(BuildContext context, WidgetRef ref) {
    final settings = ref.read(syncSettingsNotifierProvider);
    
    if (settings.roomId.isEmpty || settings.password.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('設定が必要です'),
          content: const Text('先に設定画面でユーザーIDとパスワードを設定してください。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                SettingsSheet.show(context);
              },
              child: const Text('設定を開く'),
            ),
          ],
        ),
      );
      return;
    }

    final rawString = '${settings.roomId}::${settings.password}::${settings.userName}';
    final obfuscated = base64Url.encode(utf8.encode(rawString));
    
    final uri = Uri.base;
    final shareUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ":${uri.port}" : ""}${uri.path}?i=$obfuscated';

    Clipboard.setData(ClipboardData(text: shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('共有リンクをコピーしました'), backgroundColor: Color(0xFF2ECC71)),
    );
  }
}
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onPressed;

  const _HeaderIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: color ?? Colors.white, size: 22),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
