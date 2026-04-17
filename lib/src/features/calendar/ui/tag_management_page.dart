import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/tag_provider.dart';
import 'tag_dialog.dart';

class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シフトタグ設定'),
      ),
      body: tagsAsync.when(
        data: (tags) => ListView.builder(
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: tag.color.withOpacity(0.3),
                child: Text(tag.emoji),
              ),
              title: Text(tag.title),
              subtitle: Text('透かし: ${tag.watermarkChar}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final updatedTag = await TagDialog.show(context, tag: tag);
                      if (updatedTag != null) {
                        ref.read(tagNotifierProvider.notifier).updateTag(updatedTag);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      ref.read(tagNotifierProvider.notifier).deleteTag(tag.id);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTag = await TagDialog.show(context);
          if (newTag != null) {
            ref.read(tagNotifierProvider.notifier).addTag(newTag);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
