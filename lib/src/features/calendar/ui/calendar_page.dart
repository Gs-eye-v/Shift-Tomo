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
import '../provider/shared_shifts_provider.dart';
import '../../sync/provider/sync_settings_provider.dart';
import '../../sync/provider/realtime_sync_provider.dart';
import '../../sync/provider/partner_provider.dart';
import '../../sync/provider/sync_provider.dart';
import '../provider/view_state_provider.dart';
import '../../sync/model/partner.dart';
import '../../../utils/encryption_service.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  bool _hasCheckedDeepLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeepLink();
    });
  }

  Future<void> _checkDeepLink() async {
    if (_hasCheckedDeepLink) return;
    _hasCheckedDeepLink = true;

    final uri = Uri.base;
    final obfuscated = uri.queryParameters['i'];
    if (obfuscated == null || obfuscated.isEmpty) return;

    try {
      final decoded = utf8.decode(base64Url.decode(obfuscated));
      final parts = decoded.split('::');
      if (parts.length < 3) return;

      final roomId = parts[0];
      final password = parts[1];
      final userName = parts[2];

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('友達の追加'),
          content: Text('$userNameさんを友達に追加しますか？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('追加')),
          ],
        ),
      );

      if (confirmed == true) {
        final repository = ref.read(syncRepositoryProvider);
        await repository.validateAndFetchProfiles(roomId, password);

        final friend = Partner(
          id: const Uuid().v4(),
          displayName: userName,
          roomId: roomId,
          password: password,
          profileName: userName,
          isReadOnly: true,
        );

        await ref.read(partnerNotifierProvider.notifier).addPartner(friend);
        ref.read(calendarViewUserNotifierProvider.notifier).selectPartner(friend);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('友達を追加しました'), backgroundColor: Color(0xFF2ECC71)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リンクの解析に失敗しました'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final shiftsMapAsync = ref.watch(calendarNotifierProvider);
    final salaryStats = ref.watch(monthlySalaryProvider);
    final viewUser = ref.watch(calendarViewUserNotifierProvider);

    ref.watch(realtimeSyncNotifierProvider);

    ref.listen(remoteUpdateEventProvider, (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('最新のデータを受信しました'),
            backgroundColor: Color(0xFF3498DB),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

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
            const _UserSwitcher(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF2ECC71)),
                    onPressed: () => ref.read(focusedMonthProvider.notifier).previousMonth(),
                  ),
                  Text(
                    '${focusedMonth.year}年${focusedMonth.month}月',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF2ECC71)),
                    onPressed: () => ref.read(focusedMonthProvider.notifier).nextMonth(),
                  ),
                ],
              ),
            ),
            const _WeekdayHeader(),
            Expanded(
              child: shiftsMapAsync.when(
                data: (shiftsMap) => GridView.builder(
                  padding: const EdgeInsets.all(4),
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
                      sharedShifts: const [],
                      isToday: dateOnly == today,
                      isCurrentMonth: date.month == focusedMonth.month,
                      onTap: () => _showDayDetailBottomSheet(context, ref, viewUser, date, shifts),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
            _SalaryDashboard(stats: salaryStats),
          ],
        ),
      ),
    );
  }

  void _showDayDetailBottomSheet(BuildContext context, WidgetRef ref, CalendarViewUser viewUser, DateTime date, List<Shift> shifts) {
    final tagsAsync = ref.read(tagNotifierProvider);
    final dateStr = DateFormat('yyyy年MM月dd日 (E)', 'ja_JP').format(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 背景を透過させて自前で角丸のContainerを作る
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              if (viewUser.isMe)
                const Text('自分の予定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2ECC71)))
              else
                Text('${viewUser.displayName} の予定', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3498DB))),
              
              const SizedBox(height: 12),
              if (shifts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('予定はありません', style: TextStyle(color: Colors.grey, fontSize: 13)),
                )
              else
                ...shifts.expand((shift) {
                  return shift.tagIds.map((tagId) {
                    final tag = tagsAsync.value?.where((t) => t.id == tagId).firstOrNull;
                    if (tag == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tag.color.withOpacity(0.2),
                          child: Text(tag.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(tag.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: tag.isDayOff ? const Text('休み') : Text('${tag.startTime} 〜 ${tag.endTime}'),
                      ),
                    );
                  });
                }).toList(),

              if (shifts.any((s) => s.memo != null && s.memo!.isNotEmpty))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('メモ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2ECC71))),
                      const SizedBox(height: 8),
                      Text(shifts.first.memo!),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              
              if (viewUser.isMe)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ShiftDialog.show(context, date: date, initialShifts: shifts);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('予定を編集'),
                  ),
                )
              else
                const Center(child: Text('閲覧専用', style: TextStyle(color: Colors.grey))),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _UserSwitcher extends ConsumerWidget {
  const _UserSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(partnerNotifierProvider);
    final currentUser = ref.watch(calendarViewUserNotifierProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: friendsAsync.when(
        data: (friends) => ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ChoiceChip(
                label: const Text('自分'),
                selected: currentUser.isMe,
                onSelected: (selected) => ref.read(calendarViewUserNotifierProvider.notifier).selectMe(),
              ),
            ),
            ...friends.map((friend) => Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8, bottom: 8),
              child: GestureDetector(
                onLongPress: () => _showFriendMenu(context, ref, friend),
                child: ChoiceChip(
                  label: Text(friend.displayName),
                  selected: !currentUser.isMe && currentUser.partner?.id == friend.id,
                  onSelected: (selected) => ref.read(calendarViewUserNotifierProvider.notifier).selectPartner(friend),
                ),
              ),
            )),
          ],
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  void _showFriendMenu(BuildContext context, WidgetRef ref, Partner friend) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('名前を変更'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('解除する', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(partnerNotifierProvider.notifier).removePartner(friend.id);
                ref.read(calendarViewUserNotifierProvider.notifier).selectMe();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('友達を解除しました')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Partner friend) {
    final controller = TextEditingController(text: friend.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前を変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '新しい名前'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(partnerNotifierProvider.notifier).renamePartner(friend.id, newName);
                final current = ref.read(calendarViewUserNotifierProvider);
                if (current.partner?.id == friend.id) {
                  ref.read(calendarViewUserNotifierProvider.notifier).selectPartner(
                    friend.copyWithDisplayName(newName)
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

extension PartnerExtension on Partner {
  Partner copyWithDisplayName(String newName) {
    return Partner(
      id: id,
      displayName: newName,
      roomId: roomId,
      password: password,
      profileName: profileName,
      isReadOnly: isReadOnly,
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: '推定月収',
            value: currencyFormat.format(stats.totalSalary),
            valueColor: const Color(0xFF3498DB),
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
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF2C3E50),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                day, 
                style: const TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}
