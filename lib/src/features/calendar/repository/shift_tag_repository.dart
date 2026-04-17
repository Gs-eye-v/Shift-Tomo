import '../model/shift_tag.dart';

abstract class ShiftTagRepository {
  Future<List<ShiftTag>> getTags();
  Future<void> addTag(ShiftTag tag);
  Future<void> updateTag(ShiftTag tag);
  Future<void> deleteTag(String id);
  Future<void> replaceTags(List<ShiftTag> tags);
}
