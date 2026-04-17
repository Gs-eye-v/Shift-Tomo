import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../provider/sync_provider.dart';
import '../provider/partner_provider.dart';
import '../model/partner.dart';
import '../../calendar/provider/view_state_provider.dart';
import '../../../utils/encryption_service.dart';

class AddFriendDialog extends ConsumerStatefulWidget {
  const AddFriendDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddFriendDialog(),
    );
  }

  @override
  ConsumerState<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<AddFriendDialog> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  String? _decodedRoomId;
  String? _decodedPassword;
  String? _decodedOriginalName;
  
  int _currentStep = 0;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleUrlPaste() {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) return;

    try {
      final uri = Uri.parse(rawUrl);
      final token = uri.queryParameters['i'];
      if (token == null) throw Exception('URLが無効です');

      final decoded = utf8.decode(base64Url.decode(token));
      final parts = decoded.split('::');
      if (parts.length < 3) throw Exception('データが不足しています');

      setState(() {
        _decodedRoomId = parts[0];
        _decodedPassword = parts[1];
        _decodedOriginalName = parts[2];
        _nameController.text = _decodedOriginalName!;
        _currentStep = 1;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'URLの解析に失敗しました');
    }
  }

  Future<void> _handleAdd() async {
    if (_decodedRoomId == null || _decodedPassword == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(syncRepositoryProvider);
      final profilesMap = await repository.validateAndFetchProfiles(_decodedRoomId!, _decodedPassword!);
      final profiles = profilesMap['profiles'] as Map<String, dynamic>? ?? {};
      
      if (profiles.isEmpty) {
        throw Exception('データが見つかりません');
      }

      final profileName = profiles.keys.first;

      final friend = Partner(
        id: const Uuid().v4(),
        displayName: _nameController.text.trim().isEmpty ? _decodedOriginalName! : _nameController.text.trim(),
        roomId: _decodedRoomId!,
        password: _decodedPassword!,
        profileName: profileName,
        isReadOnly: true,
      );

      await ref.read(partnerNotifierProvider.notifier).addPartner(friend);
      ref.read(calendarViewUserNotifierProvider.notifier).selectPartner(friend);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('友達を追加しました'), backgroundColor: Color(0xFF2ECC71)),
        );
      }
    } on DecryptionException {
      setState(() => _errorMessage = 'パスワードが正しくない可能性があります');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _currentStep == 0 ? const Color(0xFF3498DB).withOpacity(0.1) : const Color(0xFF2ECC71).withOpacity(0.1),
                  child: Icon(
                    _currentStep == 0 ? Icons.link : Icons.person_add, 
                    color: _currentStep == 0 ? const Color(0xFF3498DB) : const Color(0xFF2ECC71),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentStep == 0 ? '友達を追加' : '友達の登録',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_currentStep == 0) ...[
              const Text(
                '共有されたURLを貼り付けてください。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.paste, size: 20),
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
            ] else ...[
              const Text('友達の表示名を確認してください。', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '表示名',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF3498DB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ID: $_decodedRoomId',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF3498DB), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                if (_currentStep == 1 && !_isLoading) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('戻る'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_currentStep == 0 ? _handleUrlPaste : _handleAdd),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 0 ? const Color(0xFF3498DB) : const Color(0xFF2ECC71),
                    ),
                    child: Text(_currentStep == 0 ? '次へ' : '追加'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
