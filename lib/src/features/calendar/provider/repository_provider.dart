import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:shift_tomo/src/features/calendar/repository/shift_tag_repository.dart';
import 'package:shift_tomo/src/features/calendar/repository/web/web_shift_tag_repository.dart';

import 'package:shift_tomo/src/features/calendar/repository/shift_repository.dart';
import 'package:shift_tomo/src/features/calendar/repository/web/web_shift_repository.dart';

import 'package:shift_tomo/src/features/calendar/repository/profile_repository.dart';
import 'package:shift_tomo/src/features/calendar/repository/web/web_profile_repository.dart';

// ネイティブ実装を条件付きインポート
import 'package:shift_tomo/src/features/calendar/provider/native_repos_stub.dart'
    if (dart.library.io) 'package:shift_tomo/src/features/calendar/repository/native/native_repositories.dart';

part 'repository_provider.g.dart';

@Riverpod(keepAlive: true)
ShiftTagRepository shiftTagRepository(Ref ref) {
  if (kIsWeb) {
    return InMemoryShiftTagRepository();
  }
  // Native環境（io）でのみ実体化
  return SqliteShiftTagRepository();
}

@riverpod
ShiftRepository shiftRepository(Ref ref) {
  if (kIsWeb) {
    return InMemoryShiftRepository();
  }
  return SqliteShiftRepository();
}

@riverpod
ProfileRepository profileRepository(Ref ref) {
  if (kIsWeb) {
    return InMemoryProfileRepository();
  }
  return SqliteProfileRepository();
}
