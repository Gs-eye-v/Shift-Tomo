import 'package:shift_tomo/src/features/calendar/model/profile.dart';
import 'package:shift_tomo/src/features/calendar/repository/profile_repository.dart';

class InMemoryProfileRepository implements ProfileRepository {
  final List<Profile> _profiles = [
    const Profile(id: 'my_id', name: '自分', isMe: true),
  ];

  @override
  Future<List<Profile>> getProfiles() async => List.unmodifiable(_profiles);
}
