import 'package:shift_tomo/src/features/calendar/repository/shift_tag_repository.dart';
import 'package:shift_tomo/src/features/calendar/repository/shift_repository.dart';
import 'package:shift_tomo/src/features/calendar/repository/profile_repository.dart';
import 'package:shift_tomo/src/features/calendar/model/shift_tag.dart';
import 'package:shift_tomo/src/features/calendar/model/shift.dart';
import 'package:shift_tomo/src/features/calendar/model/profile.dart';

// These classes only exist to satisfy the compiler on Web.
// They are never actually instantiated because of kIsWeb guards in providers.

class SqliteShiftTagRepository implements ShiftTagRepository {
  @override
  Future<List<ShiftTag>> getTags() => throw UnimplementedError();
  @override
  Future<void> addTag(ShiftTag tag) => throw UnimplementedError();
  @override
  Future<void> updateTag(ShiftTag tag) => throw UnimplementedError();
  @override
  Future<void> deleteTag(String id) => throw UnimplementedError();
  @override
  Future<void> replaceTags(List<ShiftTag> tags) => throw UnimplementedError();
}

class SqliteShiftRepository implements ShiftRepository {
  @override
  Future<List<Shift>> getShiftsForMonth(DateTime month) => throw UnimplementedError();
  @override
  Future<List<Shift>> getAllShifts() => throw UnimplementedError();
  @override
  Future<void> addShift(Shift shift) => throw UnimplementedError();
  @override
  Future<void> replaceShifts(List<Shift> shifts) => throw UnimplementedError();
}

class SqliteProfileRepository implements ProfileRepository {
  @override
  Future<List<Profile>> getProfiles() => throw UnimplementedError();
}
