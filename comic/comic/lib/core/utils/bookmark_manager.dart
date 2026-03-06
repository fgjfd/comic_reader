import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/comic_model.dart';

/// 书签数据模型
class Bookmark {
  final int chapterNumber;
  final int imagePosition;
  final String name;
  final DateTime createdAt;
  final bool isAuto;

  Bookmark({
    required this.chapterNumber,
    required this.imagePosition,
    required this.name,
    required this.createdAt,
    this.isAuto = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'chapterNumber': chapterNumber,
      'imagePosition': imagePosition,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isAuto': isAuto,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      chapterNumber: json['chapterNumber'],
      imagePosition: json['imagePosition'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      isAuto: json['isAuto'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmark &&
          runtimeType == other.runtimeType &&
          chapterNumber == other.chapterNumber &&
          imagePosition == other.imagePosition &&
          name == other.name &&
          isAuto == other.isAuto;

  @override
  int get hashCode =>
      chapterNumber.hashCode ^
      imagePosition.hashCode ^
      name.hashCode ^
      isAuto.hashCode;
}

/// 书签管理器（单例）
class BookmarkManager {
  static final BookmarkManager _instance = BookmarkManager._internal();
  factory BookmarkManager() => _instance;
  BookmarkManager._internal();

  /// 保存书签
  Future<void> saveBookmark(String comicName, Bookmark bookmark) async {
    try {
      final bookmarks = await loadBookmarks(comicName);

      if (bookmark.isAuto) {
        await _saveAutoBookmark(comicName, bookmark, bookmarks);
      } else {
        await _saveManualBookmark(comicName, bookmark, bookmarks);
      }
    } catch (e) {
      print('保存书签失败: $e');
    }
  }

  /// 保存自动书签（只保留最新的）
  Future<void> _saveAutoBookmark(
    String comicName,
    Bookmark bookmark,
    List<Bookmark> existingBookmarks,
  ) async {
    List<Bookmark> autoBookmarks = existingBookmarks
        .where((b) => b.isAuto)
        .toList();
    List<Bookmark> manualBookmarks = existingBookmarks
        .where((b) => !b.isAuto)
        .toList();

    autoBookmarks.clear();

    final latestBookmark = Bookmark(
      chapterNumber: bookmark.chapterNumber,
      imagePosition: bookmark.imagePosition,
      name:
          '最近阅读: 第 ${bookmark.chapterNumber} 章 - 图片 ${bookmark.imagePosition + 1}',
      createdAt: bookmark.createdAt,
      isAuto: true,
    );

    autoBookmarks.add(latestBookmark);

    List<Bookmark> updatedBookmarks = [...autoBookmarks, ...manualBookmarks];
    await _saveBookmarksToFile(comicName, updatedBookmarks);
  }

  /// 保存手动书签
  Future<void> _saveManualBookmark(
    String comicName,
    Bookmark bookmark,
    List<Bookmark> existingBookmarks,
  ) async {
    existingBookmarks.removeWhere(
      (b) =>
          b.chapterNumber == bookmark.chapterNumber &&
          b.imagePosition == bookmark.imagePosition &&
          !b.isAuto,
    );
    existingBookmarks.add(bookmark);
    await _saveBookmarksToFile(comicName, existingBookmarks);
  }

  /// 加载书签
  Future<List<Bookmark>> loadBookmarks(String comicName) async {
    try {
      final file = await _getBookmarksFile(comicName);
      if (!file.existsSync()) {
        return [];
      }
      final content = file.readAsStringSync();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      print('加载书签失败: $e');
      return [];
    }
  }

  /// 删除书签
  Future<void> deleteBookmark(String comicName, Bookmark bookmark) async {
    try {
      final bookmarks = await loadBookmarks(comicName);
      bookmarks.removeWhere(
        (b) =>
            b.chapterNumber == bookmark.chapterNumber &&
            b.imagePosition == bookmark.imagePosition &&
            b.name == bookmark.name &&
            b.isAuto == bookmark.isAuto,
      );
      await _saveBookmarksToFile(comicName, bookmarks);
    } catch (e) {
      print('删除书签失败: $e');
    }
  }

  /// 删除漫画的所有书签
  Future<void> deleteComicBookmarks(String comicName) async {
    try {
      final file = await _getBookmarksFile(comicName);
      if (file.existsSync()) {
        file.deleteSync();
        print('已删除漫画 $comicName 的所有书签');
      }
    } catch (e) {
      print('删除漫画书签失败: $e');
    }
  }

  /// 获取书签文件路径
  Future<File> _getBookmarksFile(String comicName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final bookmarksDir = Directory(
      '${appDir.path}${Platform.pathSeparator}bookmarks',
    );
    if (!bookmarksDir.existsSync()) {
      bookmarksDir.createSync(recursive: true);
    }
    final safeComicName = comicName.replaceAll(RegExp(r'[<>"/\\|?*]'), '_');
    return File(
      '${bookmarksDir.path}${Platform.pathSeparator}$safeComicName.json',
    );
  }

  /// 保存书签到文件
  Future<void> _saveBookmarksToFile(
    String comicName,
    List<Bookmark> bookmarks,
  ) async {
    try {
      final file = await _getBookmarksFile(comicName);
      final jsonList = bookmarks.map((b) => b.toJson()).toList();
      file.writeAsStringSync(json.encode(jsonList));
    } catch (e) {
      print('保存书签到文件失败: $e');
    }
  }

  /// 清除所有书签
  Future<void> clearAllBookmarks() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final bookmarksDir = Directory(
        '${appDir.path}${Platform.pathSeparator}bookmarks',
      );
      if (bookmarksDir.existsSync()) {
        bookmarksDir.deleteSync(recursive: true);
        bookmarksDir.createSync(recursive: true);
      }
    } catch (e) {
      print('清除所有书签失败: $e');
    }
  }
}
