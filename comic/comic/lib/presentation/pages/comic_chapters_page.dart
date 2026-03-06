import 'package:flutter/material.dart';
import '../../core/models/comic_model.dart';
import '../../core/services/comic_service.dart';
import 'comic_view_page.dart';

class ComicChaptersPage extends StatefulWidget {
  final Comic comic;
  final Future<Comic> Function(int) onDeleteChapter;
  final Function() onRefresh;

  const ComicChaptersPage({
    super.key,
    required this.comic,
    required this.onDeleteChapter,
    required this.onRefresh,
  });

  @override
  State<ComicChaptersPage> createState() => _ComicChaptersPageState();
}

class _ComicChaptersPageState extends State<ComicChaptersPage> {
  late Comic _comic;

  @override
  void initState() {
    super.initState();
    _comic = widget.comic;
  }

  @override
  Widget build(BuildContext context) {
    Comic comic = _comic;
    return Scaffold(
      appBar: AppBar(
        title: Text(comic.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('删除章节'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _comic.chapters.length,
                        itemBuilder: (context, idx) {
                          return ListTile(
                            title: Text(
                              '第 ${_comic.chapters[idx].number} 章 (${_comic.chapters[idx].images.length} 张)',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                Navigator.pop(context);
                                Comic newComic = await widget.onDeleteChapter(
                                  idx,
                                );
                                setState(() {
                                  _comic = newComic;
                                });
                                await widget.onRefresh();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('关闭'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: comic.chapters.length,
        itemBuilder: (context, index) {
          Chapter chapter = comic.chapters[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComicViewPage(
                          comicName: widget.comic.name,
                          chapterNumber: chapter.number,
                          totalChapters: widget.comic.chapters.length,
                          comic: widget.comic,
                          initialChapterIndex: index,
                          initialImagePosition: 0,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第 ${chapter.number} 章',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${chapter.images.length} 张图片',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认删除'),
                        content: const Text('确定要删除这个章节吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              Comic newComic = await widget.onDeleteChapter(
                                index,
                              );
                              setState(() {
                                _comic = newComic;
                              });
                              await widget.onRefresh();
                            },
                            child: const Text(
                              '删除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
