import '../models/comic_model.dart';
import '../utils/bookmark_manager.dart';

/// 书签服务类，处理书签相关的业务逻辑
class BookmarkService {
  final BookmarkManager _bookmarkManager = BookmarkManager();

  /// 加载指定漫画的所有书签
  Future<List<Bookmark>> loadBookmarks(String comicName) async {
    return await _bookmarkManager.loadBookmarks(comicName);
  }

  /// 获取最近阅读的书签（自动书签）
  Bookmark? getRecentBookmark(List<Bookmark> bookmarks) {
    for (var bookmark in bookmarks) {
      if (bookmark.isAuto) {
        return bookmark;
      }
    }
    return null;
  }

  /// 获取所有手动书签
  List<Bookmark> getManualBookmarks(List<Bookmark> bookmarks) {
    return bookmarks.where((b) => !b.isAuto).toList();
  }

  /// 计算书签在总图片中的位置
  int getBookmarkImageGlobalIndex(Bookmark bookmark, Comic comic) {
    int index = 0;
    for (int i = 0; i < comic.chapters.length; i++) {
      if (comic.chapters[i].number == bookmark.chapterNumber) {
        index += bookmark.imagePosition;
        break;
      }
      index += comic.chapters[i].images.length;
    }
    return index;
  }

  /// 删除书签
  Future<void> deleteBookmark(String comicName, Bookmark bookmark) async {
    await _bookmarkManager.deleteBookmark(comicName, bookmark);
  }

  /// 根据书签获取章节索引
  int? getChapterIndex(Bookmark bookmark, Comic comic) {
    final chapterIndex = comic.chapters.indexWhere(
      (c) => c.number == bookmark.chapterNumber,
    );
    return chapterIndex != -1 ? chapterIndex : null;
  }
}
