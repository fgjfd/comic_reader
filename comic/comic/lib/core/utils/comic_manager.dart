import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/comic_model.dart';
import '../services/comic_service.dart';
import 'zip_importer.dart';
import 'bookmark_manager.dart';

class ComicManager {
  static final ComicManager _instance = ComicManager._internal();
  List<Comic> comics = [];
  bool isLoading = false;
  bool isImporting = false;
  final BookmarkManager bookmarkManager = BookmarkManager();

  factory ComicManager() {
    return _instance;
  }

  ComicManager._internal();

  Future<List<Comic>> loadComics() async {
    isLoading = true;
    try {
      comics = await ComicService.loadComics();
    } catch (e) {
      print('加载漫画失败: $e');
      comics = [];
    } finally {
      isLoading = false;
    }
    return comics;
  }

  Future<void> saveComics() async {
    try {
      await ComicService.saveComics(comics);
    } catch (e) {
      print('保存漫画失败: $e');
    }
  }

  Future<void> addComic(Comic comic) async {
    try {
      comics.add(comic);
      await saveComics();
    } catch (e) {
      print('添加漫画失败: $e');
    }
  }

  Future<void> saveComic(Comic comic) async {
    try {
      comics.add(comic);
      await saveComics();
    } catch (e) {
      print('保存漫画失败: $e');
    }
  }

  Future<void> removeComic(int index) async {
    if (index >= 0 && index < comics.length) {
      try {
        String comicName = comics[index].name;
        await ComicService.deleteComic(comics, index);
        await saveComics();
        await bookmarkManager.deleteComicBookmarks(comicName);
      } catch (e) {
        print('删除漫画失败: $e');
      }
    }
  }

  Future<Comic> removeChapter(int comicIndex, int chapterIndex) async {
    if (comicIndex >= 0 && comicIndex < comics.length) {
      try {
        Comic comic = comics[comicIndex];
        int deletedChapterNumber = comic.chapters[chapterIndex].number;

        Comic updatedComic = await ComicService.deleteChapter(
          comics,
          comicIndex,
          chapterIndex,
        );
        comics[comicIndex] = updatedComic;
        await saveComics();

        await _updateBookmarksAfterChapterDelete(
          comic.name,
          deletedChapterNumber,
          updatedComic,
        );

        return updatedComic;
      } catch (e) {
        print('删除章节失败: $e');
        return comics[comicIndex];
      }
    }
    return comics[comicIndex];
  }

  Future<void> _updateBookmarksAfterChapterDelete(
    String comicName,
    int deletedChapterNumber,
    Comic updatedComic,
  ) async {
    try {
      List<Bookmark> bookmarks = await bookmarkManager.loadBookmarks(comicName);
      List<Bookmark> updatedBookmarks = [];

      for (var bookmark in bookmarks) {
        if (bookmark.chapterNumber == deletedChapterNumber) {
          if (updatedComic.chapters.isNotEmpty) {
            int newChapterNumber = updatedComic.chapters.first.number;
            int newImagePosition = 0;

            updatedBookmarks.add(
              Bookmark(
                chapterNumber: newChapterNumber,
                imagePosition: newImagePosition,
                name: bookmark.isAuto
                    ? '最近阅读: 第 $newChapterNumber 章 - 图片 1'
                    : bookmark.name,
                createdAt: bookmark.createdAt,
                isAuto: bookmark.isAuto,
              ),
            );
          }
        } else {
          updatedBookmarks.add(bookmark);
        }
      }

      await bookmarkManager.deleteComicBookmarks(comicName);
      for (var bookmark in updatedBookmarks) {
        await bookmarkManager.saveBookmark(comicName, bookmark);
      }
    } catch (e) {
      print('更新书签失败: $e');
    }
  }

  Future<void> saveReadingProgress(
    String comicName,
    int chapterNumber,
    int imageIndex,
  ) async {
    try {
      await ComicService.saveReadingProgress(
        comicName,
        chapterNumber,
        imageIndex,
      );
    } catch (e) {
      print('保存阅读进度失败: $e');
    }
  }

  Future<Map<String, int>?> loadReadingProgress(String comicName) async {
    try {
      return await ComicService.loadReadingProgress(comicName);
    } catch (e) {
      print('加载阅读进度失败: $e');
      return null;
    }
  }

  Future<Comic?> importZip() async {
    if (isImporting) return null;
    isImporting = true;
    try {
      Comic? newComic = await ZipImporter.importZip(comics);
      if (newComic != null) {
        await addComic(newComic);
      }
      return newComic;
    } catch (e) {
      print('导入压缩包失败: $e');
      throw e;
    } finally {
      isImporting = false;
    }
  }

  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final comicsDir = Directory(
        '${appDir.path}${Platform.pathSeparator}comics',
      );
      if (comicsDir.existsSync()) {
        comicsDir.deleteSync(recursive: true);
        comicsDir.createSync(recursive: true);
      }
      comics = [];
      await saveComics();
    } catch (e) {
      print('清理缓存失败: $e');
      throw e;
    }
  }

  Future<void> clearAllData() async {
    try {
      await clearCache();
      await bookmarkManager.clearAllBookmarks();
    } catch (e) {
      print('清除所有数据失败: $e');
      throw e;
    }
  }
}
