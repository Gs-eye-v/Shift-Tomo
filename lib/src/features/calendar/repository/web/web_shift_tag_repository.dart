import 'dart:convert';
import 'package:shift_tomo/src/features/calendar/model/shift_tag.dart';
import 'package:shift_tomo/src/features/calendar/repository/shift_tag_repository.dart';
import 'package:shift_tomo/src/utils/device_service.dart';

class LocalStorageShiftTagRepository implements ShiftTagRepository {
  static const String _key = 'local_tags';
  final List<ShiftTag> _tags = [];
  bool _isLoaded = false;

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    final prefs = DeviceService.instance.prefs;
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      final List<dynamic> list = json.decode(jsonStr);
      _tags.clear();
      _tags.addAll(list.map((item) => ShiftTag.fromMap(item as Map<String, dynamic>)));
    }
    _isLoaded = true;
  }

  Future<void> _save() async {
    final prefs = DeviceService.instance.prefs;
    final jsonStr = json.encode(_tags.map((t) => t.toMap()).toList());
    await prefs.setString(_key, jsonStr);
  }

  @override
  Future<List<ShiftTag>> getTags() async {
    await _ensureLoaded();
    return List.from(_tags);
  }

  @override
  Future<void> addTag(ShiftTag tag) async {
    await _ensureLoaded();
    _tags.add(tag);
    await _save();
  }

  @override
  Future<void> updateTag(ShiftTag tag) async {
    await _ensureLoaded();
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
      await _save();
    }
  }

  @override
  Future<void> deleteTag(String id) async {
    await _ensureLoaded();
    _tags.removeWhere((t) => t.id == id);
    await _save();
  }

  @override
  Future<void> replaceTags(List<ShiftTag> tags) async {
    _tags.clear();
    _tags.addAll(tags);
    _isLoaded = true;
    await _save();
  }
}

// 互換性のためのエイリアス
typedef InMemoryShiftTagRepository = LocalStorageShiftTagRepository;
