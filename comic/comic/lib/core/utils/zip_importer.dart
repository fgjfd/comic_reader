import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/comic_model.dart';
import 'app_config.dart';

typedef ImportProgressCallback = void Function(ImportProgress progress);

class ImportProgress {
  final String stage;
  final int current;
  final int total;
  final String message;

  ImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    required this.message,
  });

  double get percentage => total > 0 ? current / total : 0.0;
}

class ZipImporter {
  static Future<Comic?> importZip(
    List<Comic> existingComics, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      _reportProgress(onProgress, '选择文件', 0, 100, '等待选择文件...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      _reportProgress(onProgress, '读取文件', 5, 100, '正在读取压缩文件...');

      String zipPath = result.files.single.path!;
      String comicName = path.basenameWithoutExtension(zipPath);

      for (var comic in existingComics) {
        if (comic.name == comicName) {
          throw Exception('漫画 "$comicName" 已存在于书架中');
        }
      }

      Directory tempDir = Directory.systemTemp.createTempSync('comic_');

      _reportProgress(onProgress, '解压文件', 10, 100, '正在解压文件（大文件可能需要几分钟）...');

      await _extractZipWithSystemCommand(zipPath, tempDir.path, onProgress);

      _reportProgress(onProgress, '准备目录', 30, 100, '正在准备存储目录...');

      Directory appDocDir = await getApplicationDocumentsDirectory();
      Directory comicsDir = Directory(
        '${appDocDir.path}${Platform.pathSeparator}comics',
      );
      if (!comicsDir.existsSync()) {
        comicsDir.createSync(recursive: true);
      }

      Directory comicDir = Directory(
        '${comicsDir.path}${Platform.pathSeparator}$comicName',
      );
      if (comicDir.existsSync()) {
        comicDir.deleteSync(recursive: true);
      }
      comicDir.createSync(recursive: true);

      _copyDirectories(tempDir, comicDir);

      _reportProgress(onProgress, '扫描章节', 40, 100, '正在扫描章节...');

      List<Chapter> chapters = [];
      String? coverImagePath;

      List<FileSystemEntity> comicEntities = comicDir.listSync();

      List<Directory> allChapterDirs = [];
      Directory? coverDir;

      for (FileSystemEntity entity in comicEntities) {
        if (entity is Directory) {
          List<Directory> foundDirs = _findAllChapterDirs(entity);
          for (Directory dir in foundDirs) {
            String folderName = path.basename(dir.path).toLowerCase();
            if (folderName == '0' ||
                folderName == 'cover' ||
                folderName == '封面') {
              coverDir = dir;
            } else {
              allChapterDirs.add(dir);
            }
          }
        }
      }

      if (coverDir != null) {
        coverImagePath = _getFirstImagePath(coverDir);
      }

      allChapterDirs.sort((a, b) {
        String nameA = path.basename(a.path).toLowerCase();
        String nameB = path.basename(b.path).toLowerCase();

        int numA = int.tryParse(nameA) ?? 9999;
        int numB = int.tryParse(nameB) ?? 9999;

        if (numA != 9999 && numB != 9999) {
          return numA.compareTo(numB);
        }
        return nameA.compareTo(nameB);
      });

      int totalChapters = allChapterDirs.length;
      int processedChapters = 0;

      for (int idx = 0; idx < allChapterDirs.length; idx++) {
        Directory chapterDir = allChapterDirs[idx];
        int chapterNumber = idx + 1;

        Chapter? chapter = await _processChapter(
          chapterDir,
          chapterNumber,
          idx,
          processedChapters,
          totalChapters,
          onProgress,
        );

        if (chapter != null && chapter.images.isNotEmpty) {
          chapters.add(chapter);

          if (coverImagePath == null && chapter.images.isNotEmpty) {
            coverImagePath = chapter.images[0].path;
          }
        }
        processedChapters++;
      }

      _reportProgress(onProgress, '清理临时文件', 95, 100, '正在清理临时文件...');

      tempDir.deleteSync(recursive: true);

      _reportProgress(onProgress, '完成', 100, 100, '导入完成！');

      Comic comic = Comic(
        comicName,
        chapters,
        originalChapterCount: chapters.length,
        coverImagePath: coverImagePath,
      );
      return comic;
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  static String? _getFirstImagePath(Directory dir) {
    try {
      List<FileSystemEntity> entities = dir.listSync();
      List<String> imagePaths = entities
          .where((entity) => entity is File && _isImageFile(entity.path))
          .map((entity) => entity.path)
          .toList();

      if (imagePaths.isNotEmpty) {
        imagePaths.sort((a, b) {
          int numA = int.tryParse(path.basenameWithoutExtension(a)) ?? 9999;
          int numB = int.tryParse(path.basenameWithoutExtension(b)) ?? 9999;
          return numA.compareTo(numB);
        });
        return imagePaths[0];
      }
    } catch (e) {}
    return null;
  }

  static List<Directory> _findAllChapterDirs(Directory dir) {
    List<Directory> result = [];

    List<FileSystemEntity> entities = dir.listSync();
    List<Directory> subDirs = entities
        .where((entity) => entity is Directory)
        .map((entity) => entity as Directory)
        .toList();

    bool hasImages = entities.any(
      (entity) => entity is File && _isImageFile(entity.path),
    );

    if (hasImages && subDirs.isEmpty) {
      result.add(dir);
    } else if (subDirs.isNotEmpty) {
      for (Directory subDir in subDirs) {
        result.addAll(_findAllChapterDirs(subDir));
      }
    }

    return result;
  }

  static Future<Chapter?> _processChapter(
    Directory sourceChapterDir,
    int chapterNumber,
    int chapterIndex,
    int processedChapters,
    int totalChapters,
    ImportProgressCallback? onProgress,
  ) async {
    List<ComicImage> images = [];

    try {
      List<FileSystemEntity> imageEntities = sourceChapterDir.listSync();

      List<String> imagePaths = imageEntities
          .where((entity) => entity is File && _isImageFile(entity.path))
          .map((entity) => entity.path)
          .toList();

      imagePaths.sort((a, b) {
        int numA = int.tryParse(path.basenameWithoutExtension(a)) ?? 9999;
        int numB = int.tryParse(path.basenameWithoutExtension(b)) ?? 9999;
        return numA.compareTo(numB);
      });

      int totalImages = imagePaths.length;
      final config = AppConfig();
      final importMode = config.importMode;

      for (int i = 0; i < imagePaths.length; i++) {
        String sourceImagePath = imagePaths[i];

        int progress = 40 + (processedChapters * 50 ~/ totalChapters);
        _reportProgress(
          onProgress,
          '处理图片',
          progress.clamp(40, 90),
          100,
          '正在处理第 $chapterNumber 章图片... ($i/$totalImages)',
        );

        if (importMode == ImportMode.progressive && chapterIndex >= 10) {
          images.add(ComicImage(sourceImagePath, 1920, 1080, i));
        } else {
          var (width, height) = await _getImageDimensions(sourceImagePath);
          images.add(ComicImage(sourceImagePath, width, height, i));
        }
      }
    } catch (e) {
      print('处理章节失败: $e');
    }

    if (images.isEmpty) {
      return null;
    }

    return Chapter(chapterNumber, sourceChapterDir.path, images);
  }

  static Future<(int, int)> _getImageDimensions(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      int width = image.width;
      int height = image.height;

      image.dispose();
      codec.dispose();

      return (width, height);
    } catch (e) {
      print('获取图片尺寸失败: $e');
      return (1920, 1080);
    }
  }

  static Future<void> _extractZipWithSystemCommand(
    String zipPath,
    String targetPath,
    ImportProgressCallback? onProgress,
  ) async {
    ProcessResult result;

    if (Platform.isAndroid) {
      result = await Process.run('unzip', [
        '-o',
        zipPath,
        '-d',
        targetPath,
      ], runInShell: true);
    } else if (Platform.isWindows) {
      result = await Process.run('powershell', [
        '-Command',
        'Expand-Archive -Path "$zipPath" -DestinationPath "$targetPath" -Force',
      ], runInShell: true);
    } else {
      result = await Process.run('unzip', [
        '-o',
        zipPath,
        '-d',
        targetPath,
      ], runInShell: true);
    }

    if (result.exitCode != 0) {
      throw Exception('解压失败: ${result.stderr}');
    }

    _reportProgress(onProgress, '解压文件', 30, 100, '解压完成');
  }

  static void _reportProgress(
    ImportProgressCallback? callback,
    String stage,
    int current,
    int total,
    String message,
  ) {
    callback?.call(
      ImportProgress(
        stage: stage,
        current: current,
        total: total,
        message: message,
      ),
    );
  }

  static bool _isImageFile(String filePath) {
    String ext = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext);
  }

  static void _copyDirectories(Directory source, Directory target) {
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }

    for (var entity in source.listSync()) {
      String name = path.basename(entity.path);
      String newPath = '${target.path}${Platform.pathSeparator}$name';

      if (entity is Directory) {
        _copyDirectories(entity, Directory(newPath));
      } else if (entity is File) {
        entity.copySync(newPath);
      }
    }
  }
}
