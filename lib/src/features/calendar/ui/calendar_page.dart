import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'header_area.dart';
import 'calendar_cell.dart';
import 'shift_dialog.dart';
import '../provider/calendar_provider.dart';
import '../provider/salary_provider.dart';
import '../provider/tag_provider.dart';
import '../model/shift.dart';
import '../model/shift_tag.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final shiftsMapAsync = ref.watch(calendarNotifierProvider);
    final salaryStats = ref.watch(monthlySalaryProvider);
    
    // 6x7 グリッド作成のための日付計算
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final calendarStartDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    const totalCells = 42;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HeaderArea(),
            // 月移動ナビゲーション
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => ref.read(focusedMonthProvider.notifier).previousMonth(),
                  ),
                  Text(
                    '${focusedMonth.year}年${focusedMonth.month}月',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => ref.read(focusedMonthProvider.notifier).nextMonth(),
                  ),
                ],
              ),
            ),
            const _WeekdayHeader(),
            Expanded(
              child: shiftsMapAsync.when(
                data: (shiftsMap) => GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    final date = calendarStartDate.add(Duration(days: index));
                    final dateOnly = DateTime(date.year, date.month, date.day);
                    final shifts = shiftsMap[dateOnly] ?? [];
                    
                    return CalendarCell(
                      key: ValueKey(dateOnly),
                      date: date,
                      shifts: shifts,
                      isToday: dateOnly == today,
                      isCurrentMonth: date.month == focusedMonth.month,
                      onTap: () => _showDayDetailBottomSheet(context, ref, date, shifts),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
            // 給与ダッシュボード（月間統計）
            _SalaryDashboard(stats: salaryStats),
          ],
        ),
      ),
    );
  }

  void _showDayDetailBottomSheet(BuildContext context, WidgetRef ref, DateTime date, List<Shift> shifts) {
    final tagsAsync = ref.read(tagNotifierProvider);
    final dateStr = DateFormat('yyyy年MM月dd日 (E)', 'ja_JP').format(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (shifts.isEmpty)
                const Center(child: Text('予定はありません', style: TextStyle(color: Colors.grey)))
              else
                ...shifts.expand((shift) {
                  return shift.tagIds.map((tagId) {
                    final tag = tagsAsync.value?.where((t) => t.id == tagId).firstOrNull;
                    if (tag == null) return const SizedBox.shrink();
                    return ListTile(
                      leading: Text(tag.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(tag.title),
                      subtitle: tag.isDayOff ? const Text('休み') : Text('${tag.startTime} 〜 ${tag.endTime}'),
                    );
                  });
                }).toList(),
              if (shifts.any((s) => s.memo != null && s.memo!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('メモ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(shifts.first.memo!),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ShiftDialog.show(context, date: date, initialShifts: shifts);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('編集'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SalaryDashboard extends StatelessWidget {
  final SalaryStats stats;

  const _SalaryDashboard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: '推定月収',
            value: currencyFormat.format(stats.totalSalary),
            valueColor: Colors.blue,
          ),
          _StatItem(
            label: '勤務時間',
            value: '${stats.totalHours}h',
          ),
          _StatItem(
            label: '出勤日数',
            value: '${stats.totalShifts}日',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return Container(
      color: Theme.of(context).cardColor,
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        )).toList(),
      ),
    );
  }
}
