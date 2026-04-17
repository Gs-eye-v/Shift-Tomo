import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/profile.dart';
import 'repository_provider.dart';

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<List<Profile>> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    return repository.getProfiles();
  }
}
