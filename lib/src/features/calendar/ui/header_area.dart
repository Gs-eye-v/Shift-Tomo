import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_sheet.dart';
import 'shift_dialog.dart';
import '../../sync/ui/sync_dialog.dart';
import 'scan_page.dart';
import 'holiday_finder_page.dart';

class HeaderArea extends ConsumerWidget {
  const HeaderArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          const Text(
            'シフトモ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ShiftDialog.show(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanPage()),
            ),
            icon: const Icon(Icons.photo_camera, color: Colors.orange),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HolidayFinderPage()),
            ),
            icon: const Icon(Icons.event_available, color: Colors.green),
          ),
          IconButton(
            onPressed: () => SyncDialog.show(context),
            icon: const Icon(Icons.cloud_sync, color: Colors.blue),
          ),
          IconButton(
            onPressed: () => SettingsSheet.show(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
