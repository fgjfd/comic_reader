import 'package:flutter/material.dart';
import '../../core/models/comic_model.dart';

/// 简单的书架管理对话框，用于从书架删除漫画
class BookshelfManageDialog extends StatelessWidget {
  final List<Comic> comics;
  final Future<void> Function(int) onDelete;

  const BookshelfManageDialog({super.key, required this.comics, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('管理书架'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: comics.length,
          itemBuilder: (context, index) {
            final comic = comics[index];
            return ListTile(
              title: Text(comic.name),
              subtitle: Text('章节: ${comic.originalChapterCount}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onDelete(index);
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('关闭')),
      ],
    );
  }
}
