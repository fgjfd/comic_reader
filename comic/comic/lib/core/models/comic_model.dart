/// 漫画数据模型
class Comic {
  /// 漫画名
  final String name;

  /// 章节列表（当前）
  final List<Chapter> chapters;

  /// 导入时的原始章节数量（用于在书架展示时保持不变）
  final int originalChapterCount;

  /// 封面图片路径
  final String? coverImagePath;

  /// 构造函数
  Comic(
    this.name,
    this.chapters, {
    int? originalChapterCount,
    this.coverImagePath,
  }) : originalChapterCount = originalChapterCount ?? chapters.length;

  /// 从 JSON 映射创建 Comic 对象
  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      json['name'],
      (json['chapters'] as List)
          .map((chapterJson) => Chapter.fromJson(chapterJson))
          .toList(),
      originalChapterCount:
          json['originalChapterCount'] ?? (json['chapters'] as List).length,
      coverImagePath: json['coverImagePath'],
    );
  }

  /// 将 Comic 对象转换为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'originalChapterCount': originalChapterCount,
      'coverImagePath': coverImagePath,
    };
  }
}

/// 图片数据模型
class ComicImage {
  /// 图片路径
  final String path;

  /// 图片原始宽度
  final int originalWidth;

  /// 图片原始高度
  final int originalHeight;

  /// 在章节中的位置（第几张）
  final int positionInChapter;

  /// 构造函数
  ComicImage(
    this.path,
    this.originalWidth,
    this.originalHeight,
    this.positionInChapter,
  );

  /// 根据屏幕宽度计算显示高度
  double getDisplayHeight(double screenWidth) {
    if (originalWidth <= 0 || originalHeight <= 0) {
      return screenWidth * 1.5;
    }
    double aspectRatio = originalWidth / originalHeight;
    return screenWidth / aspectRatio;
  }

  /// 从 JSON 映射创建 ComicImage 对象
  factory ComicImage.fromJson(Map<String, dynamic> json) {
    return ComicImage(
      json['path'],
      json['originalWidth'] ?? json['height']?.toInt() ?? 1920,
      json['originalHeight'] ?? 1080,
      json['positionInChapter'],
    );
  }

  /// 将 ComicImage 对象转换为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'positionInChapter': positionInChapter,
    };
  }
}

/// 章节数据模型
class Chapter {
  /// 章节号
  final int number;

  /// 章节路径
  final String path;

  /// 章节中的图片列表
  final List<ComicImage> images;

  /// 构造函数
  Chapter(this.number, this.path, this.images);

  /// 从 JSON 映射创建 Chapter 对象
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      json['number'],
      json['path'],
      (json['images'] as List)
          .map((imgJson) => ComicImage.fromJson(imgJson))
          .toList(),
    );
  }

  /// 将 Chapter 对象转换为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'path': path,
      'images': images.map((img) => img.toJson()).toList(),
    };
  }
}
