import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/comic_model.dart';
import '../../core/utils/comic_manager.dart';
import '../../core/utils/bookmark_manager.dart';
import '../../core/services/bookmark_service.dart';
import 'comic_view_page.dart';

/// 漫画详情页
class ComicDetailPage extends StatefulWidget {
  final Comic comic;

  const ComicDetailPage({super.key, required this.comic});

  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  late Comic _comic;
  final ComicManager comicManager = ComicManager();
  final BookmarkService bookmarkService = BookmarkService();
  List<Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _comic = widget.comic;
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await bookmarkService.loadBookmarks(_comic.name);
      _bookmarks = bookmarks;
      setState(() {});
    } catch (e) {
      print('加载书签失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_comic.name),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteChapterDialog,
            tooltip: '删除章节',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _buildCoverSection(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 180,
                        child: _buildActionsSection(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoSection(),
              _buildBookmarksSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverSection() {
    String? coverPath;
    if (_comic.coverImagePath != null && _comic.coverImagePath!.isNotEmpty) {
      coverPath = _comic.coverImagePath;
    } else if (_comic.chapters.isNotEmpty &&
        _comic.chapters[0].images.isNotEmpty) {
      coverPath = _comic.chapters[0].images[0].path;
    }

    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildCoverPlaceholder();
            },
          ),
        );
      }
    }
    return _buildCoverPlaceholder();
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('无封面', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _comic.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.book, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '共 ${_comic.originalChapterCount} 章',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.file_copy, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${_comic.chapters.length} 章可用',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksSection() {
    if (_bookmarks.isEmpty) return const SizedBox();

    final recentBookmark = bookmarkService.getRecentBookmark(_bookmarks);
    final manualBookmarks = bookmarkService.getManualBookmarks(_bookmarks);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '书签',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (recentBookmark != null) ...[
            Text(
              '自动书签',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            _buildBookmarkItem(recentBookmark),
            const SizedBox(height: 16),
          ],
          if (manualBookmarks.isNotEmpty) ...[
            Text(
              '手动书签',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ...manualBookmarks
                .map((bookmark) => _buildBookmarkItem(bookmark))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildBookmarkItem(Bookmark bookmark) {
    return GestureDetector(
      onTap: () => _gotoBookmark(bookmark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bookmark.isAuto ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: bookmark.isAuto ? Colors.blue[100]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bookmark.isAuto ? Colors.blue[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  bookmark.isAuto ? Icons.history : Icons.bookmark,
                  size: 16,
                  color: bookmark.isAuto ? Colors.blue : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookmark.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '第 ${bookmark.chapterNumber} 章 - 图片 ${bookmark.imagePosition + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!bookmark.isAuto)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                onPressed: () => _deleteBookmark(bookmark),
                tooltip: '删除书签',
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionCard(
          icon: Icons.history,
          title: '继续阅读',
          onTap: _continueReading,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.play_arrow,
          title: '选择章节',
          onTap: _showChapterSelector,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(icon, color: Colors.grey[600], size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showChapterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return _ChapterGroupSelector(
              comic: _comic,
              onChapterSelected: (idx) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComicViewPage(
                      comicName: _comic.name,
                      chapterNumber: _comic.chapters[idx].number,
                      totalChapters: _comic.chapters.length,
                      comic: _comic,
                      initialChapterIndex: idx,
                      initialImagePosition: 0,
                    ),
                  ),
                ).then((_) => _loadBookmarks());
              },
            );
          },
        );
      },
    );
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
      ),
      builder: (context) {
        final recentBookmark = bookmarkService.getRecentBookmark(_bookmarks);
        final manualBookmarks = bookmarkService.getManualBookmarks(_bookmarks);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '书签',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (recentBookmark != null)
                        _buildBookmarkItem(recentBookmark),
                      ...manualBookmarks
                          .map((bookmark) => _buildBookmarkItem(bookmark))
                          .toList(),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _continueReading() async {
    int chapterNumber = 1;
    int imagePosition = 0;

    final recentBookmark = bookmarkService.getRecentBookmark(_bookmarks);
    if (recentBookmark != null) {
      chapterNumber = recentBookmark.chapterNumber;
      imagePosition = recentBookmark.imagePosition;
    }

    int chapterIndex = 0;
    for (int i = 0; i < _comic.chapters.length; i++) {
      if (_comic.chapters[i].number == chapterNumber) {
        chapterIndex = i;
        break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicViewPage(
          comicName: _comic.name,
          chapterNumber: chapterNumber,
          totalChapters: _comic.chapters.length,
          comic: _comic,
          initialChapterIndex: chapterIndex,
          initialImagePosition: imagePosition,
        ),
      ),
    ).then((_) => _loadBookmarks());
  }

  void _gotoBookmark(Bookmark bookmark) {
    int chapterIndex = 0;
    for (int i = 0; i < _comic.chapters.length; i++) {
      if (_comic.chapters[i].number == bookmark.chapterNumber) {
        chapterIndex = i;
        break;
      }
    }

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicViewPage(
          comicName: _comic.name,
          chapterNumber: bookmark.chapterNumber,
          totalChapters: _comic.chapters.length,
          comic: _comic,
          initialChapterIndex: chapterIndex,
          initialImagePosition: bookmark.imagePosition,
        ),
      ),
    ).then((_) => _loadBookmarks());
  }

  void _deleteBookmark(Bookmark bookmark) async {
    try {
      await bookmarkService.deleteBookmark(_comic.name, bookmark);
      _loadBookmarks();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('书签已删除')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  void _showDeleteChapterDialog() {
    if (_comic.chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可删除的章节')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除章节'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择要删除的章节范围：'),
              const SizedBox(height: 16),
              _buildDeleteRangeOption('删除前 10 章', () => _deleteChapters(0, 10)),
              _buildDeleteRangeOption('删除前 50 章', () => _deleteChapters(0, 50)),
              _buildDeleteRangeOption(
                '删除前 100 章',
                () => _deleteChapters(0, 100),
              ),
              _buildDeleteRangeOption(
                '删除后 10 章',
                () => _deleteChapters(
                  _comic.chapters.length - 10,
                  _comic.chapters.length,
                ),
              ),
              _buildDeleteRangeOption(
                '删除后 50 章',
                () => _deleteChapters(
                  _comic.chapters.length - 50,
                  _comic.chapters.length,
                ),
              ),
              _buildDeleteRangeOption(
                '删除全部章节',
                () => _deleteChapters(0, _comic.chapters.length),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteRangeOption(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.red[100]!, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _deleteChapters(int start, int end) async {
    try {
      start = start.clamp(0, _comic.chapters.length);
      end = end.clamp(0, _comic.chapters.length);

      if (start >= end) return;

      for (int i = end - 1; i >= start; i--) {
        Chapter chapter = _comic.chapters[i];
        try {
          Directory chapterDir = Directory(chapter.path);
          if (chapterDir.existsSync()) {
            chapterDir.deleteSync(recursive: true);
          }
        } catch (e) {}
      }

      setState(() {
        _comic = Comic(
          _comic.name,
          _comic.chapters.sublist(0, start) + _comic.chapters.sublist(end),
          originalChapterCount: _comic.originalChapterCount,
          coverImagePath: _comic.coverImagePath,
        );
      });

      await comicManager.saveComic(_comic);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除 ${end - start} 个章节')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }
}

/// 章节分组选择器
class _ChapterGroupSelector extends StatefulWidget {
  final Comic comic;
  final Function(int) onChapterSelected;

  const _ChapterGroupSelector({
    required this.comic,
    required this.onChapterSelected,
  });

  @override
  State<_ChapterGroupSelector> createState() => _ChapterGroupSelectorState();
}

class _ChapterGroupSelectorState extends State<_ChapterGroupSelector> {
  int? _selectedGroupIndex;
  final int _groupSize = 50;

  List<Map<String, int>> _getGroups() {
    int totalChapters = widget.comic.chapters.length;
    List<Map<String, int>> groups = [];

    for (int i = 0; i < totalChapters; i += _groupSize) {
      int start = i + 1;
      int end = (i + _groupSize).clamp(0, totalChapters);
      groups.add({'start': start, 'end': end, 'index': i});
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _getGroups();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择章节 (${widget.comic.chapters.length} 章)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_selectedGroupIndex != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedGroupIndex = null;
                    });
                  },
                  child: const Text('返回分组'),
                ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedGroupIndex == null
              ? _buildGroupList(groups)
              : _buildChapterList(_selectedGroupIndex!),
        ),
      ],
    );
  }

  Widget _buildGroupList(List<Map<String, int>> groups) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.0,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGroupIndex = group['index']!;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue[100]!, width: 1),
            ),
            child: Center(
              child: Text(
                '${group['start']}-${group['end']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterList(int startIndex) {
    int endIndex = (startIndex + _groupSize).clamp(
      0,
      widget.comic.chapters.length,
    );
    int itemCount = endIndex - startIndex;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        int actualIndex = startIndex + index;
        final chapter = widget.comic.chapters[actualIndex];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              widget.onChapterSelected(actualIndex);
            },
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '第 ${chapter.number} 章',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${chapter.images.length} 页',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
