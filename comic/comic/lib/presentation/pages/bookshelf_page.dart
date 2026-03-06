import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/comic_model.dart';
import '../../core/utils/comic_manager.dart';
import 'comic_detail_page.dart';
import 'bookshelf_manage_dialog.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  final comicManager = ComicManager();

  @override
  void initState() {
    super.initState();
    _loadComics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadComics();
  }

  Future<void> _loadComics() async {
    await comicManager.loadComics();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (comicManager.comics.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('书架')),
        body: const Center(child: Text('暂无保存的漫画！')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => BookshelfManageDialog(
                  comics: comicManager.comics,
                  onDelete: (index) async {
                    await comicManager.removeComic(index);
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: comicManager.comics.length,
        itemBuilder: (context, comicIndex) {
          Comic comic = comicManager.comics[comicIndex];
          return ComicCard(comic: comic, onTap: () => _showComicActions(comic));
        },
      ),
    );
  }

  void _showComicActions(Comic comic) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComicDetailPage(comic: comic)),
    );
  }
}

class ComicCard extends StatelessWidget {
  final Comic comic;
  final VoidCallback onTap;

  const ComicCard({super.key, required this.comic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String? coverPath;
    if (comic.coverImagePath != null && comic.coverImagePath!.isNotEmpty) {
      coverPath = comic.coverImagePath;
    } else if (comic.chapters.isNotEmpty &&
        comic.chapters[0].images.isNotEmpty) {
      coverPath = comic.chapters[0].images[0].path;
    }

    Widget coverWidget;
    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);
      if (file.existsSync()) {
        coverWidget = ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: 80,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey[300],
                ),
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        );
      } else {
        coverWidget = Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: Colors.grey[300],
          ),
          child: const Icon(Icons.image, color: Colors.grey),
        );
      }
    } else {
      coverWidget = Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          color: Colors.grey[300],
        ),
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16.0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            coverWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text('共 ${comic.originalChapterCount} 章'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
