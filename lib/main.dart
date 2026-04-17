import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/features/calendar/ui/calendar_page.dart';
import 'src/utils/theme_provider.dart';
import 'src/utils/app_theme.dart';
import 'src/utils/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ja_JP');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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
    final themeType = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'ShiftChecker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromType(themeType),
      home: const CalendarPage(),
    );
  }
}
