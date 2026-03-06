import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/comic_model.dart';

class ComicService {
  static Future<List<Comic>> loadComics() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String comicsPath = '${appDocDir.path}/comics.json';
      File comicsFile = File(comicsPath);

      if (await comicsFile.exists()) {
        String comicsJson = await comicsFile.readAsString();
        List<dynamic> comicsData = json.decode(comicsJson);
        List<Comic> comics = comicsData
            .map((comicJson) => Comic.fromJson(comicJson))
            .toList();

        List<Comic> validComics = [];
        for (Comic comic in comics) {
          bool hasValidFiles = false;

          if (comic.coverImagePath != null &&
              comic.coverImagePath!.isNotEmpty) {
            File coverFile = File(comic.coverImagePath!);
            if (coverFile.existsSync()) {
              hasValidFiles = true;
            }
          }

          if (!hasValidFiles &&
              comic.chapters.isNotEmpty &&
              comic.chapters[0].images.isNotEmpty) {
            File firstImageFile = File(comic.chapters[0].images[0].path);
            if (firstImageFile.existsSync()) {
              hasValidFiles = true;
            }
          }

          if (hasValidFiles) {
            validComics.add(comic);
          } else {
            print('漫画文件不存在，删除: ${comic.name}');
          }
        }

        if (validComics.length != comics.length) {
          await saveComics(validComics);
        }

        return validComics;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveComics(List<Comic> comics) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String comicsPath = '${appDocDir.path}/comics.json';
      File comicsFile = File(comicsPath);

      String comicsJson = json.encode(
        comics.map((comic) => comic.toJson()).toList(),
      );
      await comicsFile.writeAsString(comicsJson);
    } catch (e) {
    }
  }

  static Future<void> deleteComic(List<Comic> comics, int index) async {
    Comic removed = comics.removeAt(index);

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String progressPath = '${appDocDir.path}/reading_progress.json';
      File progressFile = File(progressPath);

      if (await progressFile.exists()) {
        String progressJson = await progressFile.readAsString();
        Map<String, dynamic> progress = json.decode(progressJson);
        if (progress.containsKey(removed.name)) {
          progress.remove(removed.name);
          String newProgressJson = json.encode(progress);
          await progressFile.writeAsString(newProgressJson);
        }
      }
    } catch (e) {
    }
  }

  static Future<Comic> deleteChapter(
    List<Comic> comics,
    int comicIndex,
    int chapterIndex,
  ) async {
    Comic comic = comics[comicIndex];
    List<Chapter> newChapters = List.from(comic.chapters);
    newChapters.removeAt(chapterIndex);
    Comic newComic = Comic(
      comic.name,
      newChapters,
      originalChapterCount: comic.originalChapterCount,
    );
    comics[comicIndex] = newComic;

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String progressPath = '${appDocDir.path}/reading_progress.json';
      File progressFile = File(progressPath);

      if (await progressFile.exists()) {
        String progressJson = await progressFile.readAsString();
        Map<String, dynamic> progress = json.decode(progressJson);

        if (progress.containsKey(comic.name)) {
          Map<String, dynamic> comicProgress = Map<String, dynamic>.from(
            progress[comic.name],
          );
          int savedChapterNumber = comicProgress['chapter'];
          int savedImage = comicProgress['image'];

          if (newChapters.isEmpty) {
            progress.remove(comic.name);
          } else {
            int removedChapterNumber = comic.chapters[chapterIndex].number;
            if (savedChapterNumber == removedChapterNumber) {
              if (chapterIndex < newChapters.length) {
                int newChapIdx = chapterIndex;
                int newImg = savedImage;
                if (newImg >= newChapters[newChapIdx].images.length) {
                  newImg = newChapters[newChapIdx].images.length - 1;
                }
                progress[comic.name] = {
                  'chapter': newChapters[newChapIdx].number,
                  'image': newImg,
                };
              } else if (chapterIndex - 1 >= 0) {
                int newChapIdx = chapterIndex - 1;
                int newImg = savedImage;
                if (newImg >= newChapters[newChapIdx].images.length) {
                  newImg = newChapters[newChapIdx].images.length - 1;
                }
                progress[comic.name] = {
                  'chapter': newChapters[newChapIdx].number,
                  'image': newImg,
                };
              } else {
                progress.remove(comic.name);
              }
            } else {
            }
          }
        }

        String newProgressJson = json.encode(progress);
        await progressFile.writeAsString(newProgressJson);
      }
    } catch (e) {
    }

    return newComic;
  }

  static Future<void> saveReadingProgress(
    String comicName,
    int chapterNumber,
    int imageIndex,
  ) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String progressPath = '${appDocDir.path}/reading_progress.json';
      File progressFile = File(progressPath);

      Map<String, dynamic> progress = {};
      if (await progressFile.exists()) {
        String progressJson = await progressFile.readAsString();
        progress = json.decode(progressJson);
      }

      progress[comicName] = {'chapter': chapterNumber, 'image': imageIndex};

      String progressJson = json.encode(progress);
      await progressFile.writeAsString(progressJson);
    } catch (e) {
    }
  }

  static Future<Map<String, int>?> loadReadingProgress(String comicName) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String progressPath = '${appDocDir.path}/reading_progress.json';
      File progressFile = File(progressPath);

      if (await progressFile.exists()) {
        String progressJson = await progressFile.readAsString();
        Map<String, dynamic> progress = json.decode(progressJson);
        if (progress.containsKey(comicName)) {
          Map<String, dynamic> comicProgress = progress[comicName];
          return {
            'chapter': comicProgress['chapter'],
            'image': comicProgress['image'],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
