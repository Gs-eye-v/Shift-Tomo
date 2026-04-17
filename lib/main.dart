import 'package:flutter/foundation.dart'; // kIsWeb用
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/features/calendar/ui/calendar_page.dart';
import 'src/features/sync/provider/realtime_sync_provider.dart';
import 'src/features/sync/provider/sync_provider.dart';
import 'src/features/calendar/provider/calendar_provider.dart'; // 追加
import 'src/features/calendar/provider/tag_provider.dart'; // 追加
import 'src/utils/theme_provider.dart';
import 'src/utils/app_theme.dart';
import 'src/utils/supabase_client.dart';
import 'src/utils/device_service.dart';
import 'src/utils/notification_service.dart';

// Web用ガードのための条件付きインポート
import 'dart:html' as html if (dart.library.io) 'src/utils/stubs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ja_JP');
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  // 端末ID初期化
  await DeviceService.instance.init();

  // 通知初期化 (Mobileのみ)
  if (!kIsWeb) {
    await NotificationService().init();
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全体でリアルタイム同期リスナーを有効化
    ref.watch(realtimeSyncNotifierProvider);

    // 初回データロード時のスナップショット作成
    ref.listen(isSyncRequiredProvider, (previous, next) {
      if (kIsWeb) {
        if (next) {
          html.window.onBeforeUnload.listen((event) {
            (event as html.BeforeUnloadEvent).returnValue = '未保存の変更があります。';
          });
        } else {
          // 変更がない場合はリスナー解除（実際はブラウザ側が管理するが、ロジックとして明示）
          html.window.onBeforeUnload.listen(null);
        }
      }
    });

    final themeType = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Shift-Tomo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromType(themeType),
      home: const SyncStartHandler(child: CalendarPage()),
    );
  }
}

/// 起動直後のデータロードを待機して初回スナップショットを撮影するラッパー
class SyncStartHandler extends ConsumerWidget {
  final Widget child;
  const SyncStartHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // データがロードされたら初回スナップショットを撮影
    ref.listen(calendarNotifierProvider, (prev, next) {
      if (prev?.value == null && next.value != null) {
        ref.read(syncNotifierProvider.notifier).captureSnapshot();
      }
    });

    return child;
  }
}
