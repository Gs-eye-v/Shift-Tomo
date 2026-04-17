import 'package:flutter/material.dart';

class ManualPage extends StatelessWidget {
  const ManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マニュアル'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildManualSection(
            context,
            title: '自分のシフトをクラウドに保存する方法',
            content: '設定画面で「ユーザーID」と「パスワード」を設定し、有効化した状態で「適用」ボタンを押してください。データは安全にバックアップされ、別の端末から同じID/パスワードで復元（プル）することも可能です。',
          ),
          const Divider(height: 48),
          _buildManualSection(
            context,
            title: '友達のシフトを追加する方法',
            content: 'ヘッダーの共有アイコンから「共有リンク」をコピーして、友達に送ります。受け取った友達がそのURLを開くか、「友達を追加」画面でURLを貼り付けることで、カレンダーに表示されるようになります。',
          ),
          const Divider(height: 48),
          _buildManualSection(
            context,
            title: 'E2EE（エンドツーエンド暗号化）について',
            content: 'Shift-Tomoはプライバシーを最優先に設計されています。全てのデータは送信前にあなたの端末内でパスワードを使用して強力に暗号化されます。サーバー運営者であっても、あなたのパスワードなしにシフトの内容を見ることは不可能です。',
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Shift-Tomo - Your privacy-first shift manager.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSection(BuildContext context, {required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ],
    );
  }
}
