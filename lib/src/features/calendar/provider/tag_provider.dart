import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import '../model/shift_tag.dart';
import 'repository_provider.dart';

part 'tag_provider.g.dart';

@Riverpod(keepAlive: true)
class TagNotifier extends _$TagNotifier {
  @override
  Future<List<ShiftTag>> build() async {
    final repository = ref.watch(shiftTagRepositoryProvider);
    final tags = await repository.getTags();
    
    if (tags.isEmpty) {
      final defaultTags = [
        const ShiftTag(
          id: 'default_hayaban',
          title: '早番',
          watermarkChar: '早',
          emoji: '☀️',
          color: Colors.orange,
          startTime: '09:00',
          endTime: '18:00',
        ),
        const ShiftTag(
          id: 'default_chuban',
          title: '昼番',
          watermarkChar: '昼',
          emoji: '🕛',
          color: Colors.blue,
          startTime: '12:00',
          endTime: '21:00',
        ),
        const ShiftTag(
          id: 'default_osoban',
          title: '遅番',
          watermarkChar: '遅',
          emoji: '🌙',
          color: Colors.indigo,
          startTime: '13:00',
          endTime: '22:00',
        ),
        const ShiftTag(
          id: 'default_yasumi',
          title: '休み',
          watermarkChar: '休',
          emoji: '💤',
          color: Colors.green,
          isDayOff: true,
        ),
        const ShiftTag(
          id: 'default_gym',
          title: 'ジム',
          watermarkChar: '力',
          emoji: '💪',
          color: Colors.teal,
        ),
      ];
      
      for (final tag in defaultTags) {
        await repository.addTag(tag);
      }
      return defaultTags;
    }
    
    return tags;
  }

  Future<void> addTag(ShiftTag tag) async {
    final repository = ref.read(shiftTagRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addTag(tag);
      return repository.getTags();
    });
  }

  Future<void> updateTag(ShiftTag tag) async {
    final repository = ref.read(shiftTagRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateTag(tag);
      return repository.getTags();
    });
  }

  Future<void> deleteTag(String id) async {
    final repository = ref.read(shiftTagRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTag(id);
      return repository.getTags();
    });
  }
}
