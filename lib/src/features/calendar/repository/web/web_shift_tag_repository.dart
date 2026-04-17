import 'package:shift_tomo/src/features/calendar/model/shift_tag.dart';
import 'package:shift_tomo/src/features/calendar/repository/shift_tag_repository.dart';

class InMemoryShiftTagRepository implements ShiftTagRepository {
  static final List<ShiftTag> _tags = [];

  @override
  Future<List<ShiftTag>> getTags() async {
    return List.from(_tags);
  }

  @override
  Future<void> addTag(ShiftTag tag) async {
    _tags.add(tag);
  }

  @override
  Future<void> updateTag(ShiftTag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
    }
  }

  @override
  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> replaceTags(List<ShiftTag> tags) async {
    _tags.clear();
    _tags.addAll(tags);
  }
}
