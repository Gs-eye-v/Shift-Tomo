import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/calendar_provider.dart';
import '../provider/holiday_provider.dart';

class HolidayFinderPage extends ConsumerWidget {
  const HolidayFinderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final holidaysAsync = ref.watch(commonHolidaysProvider(focusedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('共通の休みを探す'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 月移動ナビゲーション
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(focusedMonthProvider.notifier).previousMonth(),
                ),
                Text(
                  '${focusedMonth.year}年${focusedMonth.month}月',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref.read(focusedMonthProvider.notifier).nextMonth(),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '友達全員のシフトを照合し、全員が勤務なし（休み）の日をハイライトします。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: holidaysAsync.when(
              data: (holidays) {
                if (holidays.isEmpty) {
                  return const Center(child: Text('共通の休みが見つかりませんでした。\n同期設定を確認してください。', textAlign: TextAlign.center));
                }
                return _HolidayCalendar(month: focusedMonth, holidays: holidays);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('エラーが発生しました: $err')),
            ),
          ),
          
          _LegendArea(),
        ],
      ),
    );
  }
}

class _HolidayCalendar extends StatelessWidget {
  final DateTime month;
  final List<DateTime> holidays;

  const _HolidayCalendar({required this.month, required this.holidays});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final date = DateTime(month.year, month.month, index + 1);
        final isHoliday = holidays.any((h) => h.day == date.day);

        return Container(
          decoration: BoxDecoration(
            color: isHoliday ? Colors.green.shade100 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHoliday ? Colors.green.shade400 : Colors.grey.shade200,
              width: isHoliday ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: isHoliday ? FontWeight.bold : FontWeight.normal,
                  color: isHoliday ? Colors.green.shade900 : Colors.black54,
                ),
              ),
              if (isHoliday)
                const Icon(Icons.star, size: 16, color: Colors.orange),
            ],
          ),
        );
      },
    );
  }
}

class _LegendArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              border: Border.all(color: Colors.green.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          const Text('＝ 全員休み', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
