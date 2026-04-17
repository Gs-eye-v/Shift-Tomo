import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sync/model/partner.dart';

part 'view_state_provider.g.dart';

/// カレンダーに表示する対象のタイプ
enum CalendarViewUserType {
  me,
  partner,
}

class CalendarViewUser {
  final CalendarViewUserType type;
  final Partner? partner;

  const CalendarViewUser({required this.type, this.partner});

  bool get isMe => type == CalendarViewUserType.me;
  String get displayName => isMe ? '自分' : (partner?.displayName ?? '不明');

  static const me = CalendarViewUser(type: CalendarViewUserType.me);
}

@riverpod
class CalendarViewUserNotifier extends _$CalendarViewUserNotifier {
  @override
  CalendarViewUser build() {
    return CalendarViewUser.me;
  }

  void selectMe() {
    state = CalendarViewUser.me;
  }

  void selectPartner(Partner partner) {
    state = CalendarViewUser(type: CalendarViewUserType.partner, partner: partner);
  }
}
