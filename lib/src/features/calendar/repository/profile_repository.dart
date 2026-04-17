import '../model/profile.dart';

abstract class ProfileRepository {
  Future<List<Profile>> getProfiles();
}
