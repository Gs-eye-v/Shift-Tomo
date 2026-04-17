import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter/services.dart'; 
import '../../../utils/theme_provider.dart';
import '../../../utils/app_theme.dart';
import '../../sync/provider/sync_settings_provider.dart';
import '../../sync/provider/sync_provider.dart';
import '../../calendar/provider/shared_shifts_provider.dart';
import 'tag_management_page.dart';
import 'holiday_finder_page.dart';
import '../provider/app_settings_provider.dart';
import '../provider/calendar_provider.dart'; // 追加
import '../model/shift_tag.dart'; // 追加
import 'manual_page.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late TextEditingController _baseIdController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isEditingPassword = false;
  String _generationError = '';

  @override
  void initState() {
    super.initState();
    _baseIdController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _baseIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeNotifierProvider);
    final syncSettings = ref.watch(syncSettingsNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final appSettings = ref.watch(appSettingsNotifierProvider);
    final syncNotifier = ref.read(syncSettingsNotifierProvider.notifier);

    final isPassMatch = _passwordController.text == _confirmPasswordController.text;
    final isPassValid = syncNotifier.isPasswordValid(_passwordController.text);
    
    // パスワードがすでにある場合の状態判定
    final hasExistingPassword = syncSettings.password.isNotEmpty;
    final shouldShowInputs = !hasExistingPassword || _isEditingPassword;

    final canApplyPassword = _isEditingPassword 
        ? (isPassMatch && isPassValid && _confirmPasswordController.text.isNotEmpty) 
        : true;
    
    final maskedPassword = '●' * 8;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  '設定', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  )
                ),
                const SizedBox(height: 24),
                
                _buildCardSection(
                  context,
                  title: 'デザイン',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('カラー絵文字を使用'),
                      subtitle: const Text('OFFでモノクロ表示になります', style: TextStyle(fontSize: 11)),
                      value: appSettings.useColorEmoji,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) => ref.read(appSettingsNotifierProvider.notifier).setUseColorEmoji(value),
                    ),
                    const SizedBox(height: 16),
                    const Text('テーマカラー', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: AppThemeType.values.map((type) {
                        return ChoiceChip(
                          label: Text(type.label),
                          selected: currentTheme == type,
                          onSelected: (selected) {
                            if (selected) ref.read(themeNotifierProvider.notifier).setTheme(type);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildCardSection(
                  context,
                  title: '機能',
                  children: [
                    _buildListTile(
                      context,
                      icon: Icons.label_outline,
                      title: 'シフトタグの管理',
                      onTap: () => _navigateTo(context, const TagManagementPage()),
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      context,
                      icon: Icons.star_outline,
                      title: 'みんなの休みを探す',
                      onTap: () => _navigateTo(context, const HolidayFinderPage()),
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      context,
                      icon: Icons.help_outline,
                      title: '使い方・マニュアル',
                      onTap: () => _navigateTo(context, const ManualPage()),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildCardSection(
                  context,
                  title: '通知設定',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('自分のシフトを通知する'),
                      value: appSettings.notifyMyShifts,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) async {
                        await ref.read(appSettingsNotifierProvider.notifier).setNotifyMyShifts(value);
                        ref.read(calendarNotifierProvider.notifier).syncNotifications();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('共有相手のシフトを通知する'),
                      subtitle: const Text('相手の通知設定に基づいて通知します', style: TextStyle(fontSize: 11)),
                      value: appSettings.notifyPartnerShifts,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) async {
                        await ref.read(appSettingsNotifierProvider.notifier).setNotifyPartnerShifts(value);
                        ref.read(calendarNotifierProvider.notifier).syncNotifications();
                      },
                    ),
                    const Divider(),
                    const Text('デフォルトの通知タイミング', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...appSettings.defaultReminders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final reminder = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            DropdownButton<int>(
                              value: reminder.daysBefore,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('当日')),
                                DropdownMenuItem(value: 1, child: Text('1日前')),
                                DropdownMenuItem(value: 2, child: Text('2日前')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  final newReminders = List<ShiftTagReminder>.from(appSettings.defaultReminders);
                                  newReminders[index] = ShiftTagReminder(daysBefore: val, time: reminder.time);
                                  ref.read(appSettingsNotifierProvider.notifier).setDefaultReminders(newReminders);
                                  ref.read(calendarNotifierProvider.notifier).syncNotifications();
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectDefaultReminderTime(context, ref, appSettings.defaultReminders, index),
                                child: Text(reminder.time),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () {
                                final newReminders = List<ShiftTagReminder>.from(appSettings.defaultReminders);
                                newReminders.removeAt(index);
                                ref.read(appSettingsNotifierProvider.notifier).setDefaultReminders(newReminders);
                                ref.read(calendarNotifierProvider.notifier).syncNotifications();
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        final newReminders = List<ShiftTagReminder>.from(appSettings.defaultReminders);
                        newReminders.add(const ShiftTagReminder(daysBefore: 1, time: '21:00'));
                        ref.read(appSettingsNotifierProvider.notifier).setDefaultReminders(newReminders);
                        ref.read(calendarNotifierProvider.notifier).syncNotifications();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('通知を追加', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildCardSection(
                  context,
                  title: 'クラウドに保存',
                  action: Switch(
                    value: syncSettings.isEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => ref.read(syncSettingsNotifierProvider.notifier).setEnabled(value),
                  ),
                  children: [
                    const Text(
                      'ユーザーIDとパスワードで、データを安全にバックアップします。他者に見られることはありません。',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (syncSettings.isEnabled) ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                        context,
                        label: 'あなたの表示名',
                        hint: '例: 自分、佐藤',
                        initialValue: syncSettings.userName,
                        onChanged: (val) => ref.read(syncSettingsNotifierProvider.notifier).updateUserName(val),
                      ),
                      const SizedBox(height: 20),
                      const Text('ユーザーID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (syncSettings.roomId.isEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _baseIdController,
                                decoration: const InputDecoration(labelText: 'ベースID (8文字以上)'),
                                onChanged: (_) => setState(() => _generationError = ''),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _baseIdController.text.length < 8 ? null : _handleGenerateId,
                              child: const Text('生成'),
                            ),
                          ],
                        ),
                      ] else ...[
                        _buildBubbleInfo(
                          context,
                          icon: Icons.person,
                          content: syncSettings.roomId,
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: syncSettings.roomId));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IDをコピーしました')));
                          },
                          onReset: () => _handleConfirmResetId(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('パスワード', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (!shouldShowInputs) ...[
                        _buildMaskedField(context, maskedPassword),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _isEditingPassword = true),
                            icon: const Icon(Icons.lock_reset, size: 18),
                            label: const Text('パスワードを変更する'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                            ),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: '新しいパスワード'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: '（確認用入力）',
                            errorText: (_confirmPasswordController.text.isNotEmpty && !isPassMatch) ? '一致しません' : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _buildRequirement('8文字以上、大文字・小文字・数字を含む', isPassValid),
                        if (hasExistingPassword)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () => setState(() {
                                  _isEditingPassword = false;
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                }),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('変更をキャンセル'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (syncState.isLoading || !canApplyPassword || syncSettings.roomId.isEmpty) 
                              ? null 
                              : () => _handleApply(context, ref, syncSettings),
                            icon: syncState.isLoading 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check),
                            label: const Text('設定を適用する'),
                          ),
                        ),
                      ],
                      if (syncSettings.roomId.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: syncState.isLoading ? null : () => _handleDeleteCloudData(context, ref),
                            icon: const Icon(Icons.delete_forever, size: 18),
                            label: const Text('クラウド上のデータを削除'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'バージョン 1.2.0',
                    style: TextStyle(fontSize: 11, color: Colors.grey.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(BuildContext context, {required String title, Widget? action, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBubbleInfo(BuildContext context, {required IconData icon, required String content, required VoidCallback onCopy, required VoidCallback onReset}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3498DB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )
            )
          ),
          IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: onCopy),
          TextButton(onPressed: onReset, child: const Text('リセット', style: TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildMaskedField(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text(
        text, 
        style: TextStyle(
          letterSpacing: 4, 
          color: Theme.of(context).textTheme.bodyLarge?.color,
        )
      ),
    );
  }

  Widget _buildRequirement(String label, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.circle_outlined, size: 14, color: isValid ? const Color(0xFF2ECC71) : Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, color: isValid ? const Color(0xFF2ECC71) : Colors.grey)),
      ],
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildTextField(BuildContext context, {required String label, required String hint, required String initialValue, required Function(String) onChanged}) {
    return TextField(
      decoration: InputDecoration(labelText: label, hintText: hint),
      controller: TextEditingController(text: initialValue)..selection = TextSelection.collapsed(offset: initialValue.length),
      onChanged: onChanged,
    );
  }

  Future<void> _handleGenerateId() async {
    final base = _baseIdController.text.trim();
    final notifier = ref.read(syncSettingsNotifierProvider.notifier);
    final repo = ref.read(syncRepositoryProvider);
    try {
      final generatedId = notifier.generateRoomId(base);
      final isAvailable = await repo.isRoomIdAvailable(generatedId);
      if (isAvailable) {
        notifier.updateRoomId(generatedId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IDを生成しました')));
      } else {
        setState(() => _generationError = '既に使用されています');
      }
    } catch (e) {
      setState(() => _generationError = e.toString());
    }
  }

  Future<void> _handleConfirmResetId() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザーIDのリセット'),
        content: const Text('ユーザーIDを消去します。新しいIDを設定しない限り、この端末からの同期は行われません。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('リセット', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirmed == true) {
      ref.read(syncSettingsNotifierProvider.notifier).updateRoomId('');
    }
  }

  Future<void> _handleDeleteCloudData(BuildContext context, WidgetRef ref) async {
    final syncSettings = ref.read(syncSettingsNotifierProvider);
    if (syncSettings.roomId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クラウドデータの削除'),
        content: const Text('クラウド上のデータが削除され、同期などの機能が使えなくなります。本当に削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('削除する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(syncRepositoryProvider);
      await repo.deleteRoom(syncSettings.roomId);
      
      // ローカルのIDとパスワードをクリア
      final notifier = ref.read(syncSettingsNotifierProvider.notifier);
      notifier.updateRoomId('');
      notifier.updatePassword('');
      setState(() => _isEditingPassword = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クラウド上のデータを削除しました'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除エラー: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _handleApply(BuildContext context, WidgetRef ref, dynamic settings) async {
    final notifier = ref.read(syncSettingsNotifierProvider.notifier);
    
    if (_isEditingPassword) {
      final password = _passwordController.text;
      final confirm = _confirmPasswordController.text;

      if (password.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('パスワードを入力してください'), backgroundColor: Colors.orange));
        return;
      }

      if (password != confirm) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('パスワードが一致しません'), backgroundColor: Colors.orange));
        return;
      }

      if (!notifier.isPasswordValid(password)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('パスワードは8文字以上、大文字・小文字・数字を含める必要があります'), backgroundColor: Colors.orange));
        return;
      }

      notifier.updatePassword(password);
    }

    try {
      final updatedSettings = ref.read(syncSettingsNotifierProvider);
      await ref.read(syncNotifierProvider.notifier).pushAll(
        updatedSettings.roomId, 
        updatedSettings.password, 
        updatedSettings.userName,
      );
      
      if (mounted) {
        setState(() {
          _isEditingPassword = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定を保存しました'), backgroundColor: Color(0xFF2ECC71))
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectDefaultReminderTime(BuildContext context, WidgetRef ref, List<ShiftTagReminder> currentReminders, int index) async {
    final reminder = currentReminders[index];
    final currentParts = reminder.time.split(':');
    final initialTime = currentParts.length == 2
        ? TimeOfDay(hour: int.parse(currentParts[0]), minute: int.parse(currentParts[1]))
        : const TimeOfDay(hour: 21, minute: 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final newReminders = List<ShiftTagReminder>.from(currentReminders);
      newReminders[index] = ShiftTagReminder(
        daysBefore: reminder.daysBefore,
        time: timeStr,
      );
      await ref.read(appSettingsNotifierProvider.notifier).setDefaultReminders(newReminders);
      ref.read(calendarNotifierProvider.notifier).syncNotifications();
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
