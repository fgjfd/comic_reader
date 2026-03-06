import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/utils/comic_manager.dart';
import '../../core/utils/bookmark_manager.dart';
import '../../core/models/comic_model.dart';

class ComicViewPage extends StatefulWidget {
  final String? comicName;
  final int? chapterNumber;
  final int? totalChapters;
  final Comic? comic;
  final int initialChapterIndex;
  final int initialImagePosition;

  const ComicViewPage({
    super.key,
    this.comicName,
    this.chapterNumber,
    this.totalChapters,
    this.comic,
    this.initialChapterIndex = 0,
    this.initialImagePosition = 0,
  });

  @override
  State<ComicViewPage> createState() => _ComicViewPageState();
}

class _ComicViewPageState extends State<ComicViewPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ComicManager _comicManager = ComicManager();
  final BookmarkManager _bookmarkManager = BookmarkManager();

  bool _showAppBar = true;
  int _currentChapterIndex = 0;
  int _currentImagePosition = 0;
  bool _isFirstBuild = true;
  Map<String, Size> _imageSizes = {};

  List<ComicImage> _allImages = [];
  List<int> _chapterStartIndices = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _itemPositionsListener.itemPositions.addListener(_onPositionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstBuild) {
      _scrollToInitialPosition();
      _isFirstBuild = false;
    }
  }

  void _initializeData() {
    _currentChapterIndex = widget.initialChapterIndex;
    _currentImagePosition = widget.initialImagePosition;
    _initImageList();
  }

  void _initImageList() {
    if (widget.comic == null) return;

    _allImages.clear();
    _chapterStartIndices.clear();

    for (int i = 0; i < widget.comic!.chapters.length; i++) {
      _chapterStartIndices.add(_allImages.length);
      _allImages.addAll(widget.comic!.chapters[i].images);
    }
  }

  void _scrollToInitialPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int globalIndex = _getGlobalImageIndex(
        widget.initialChapterIndex,
        widget.initialImagePosition,
      );
      _scrollToIndex(globalIndex);
    });
  }

  int _getGlobalImageIndex(int chapterIndex, int imagePosition) {
    if (chapterIndex >= _chapterStartIndices.length) return 0;
    return _chapterStartIndices[chapterIndex] + imagePosition;
  }

  int _getChapterIndexFromGlobal(int globalIndex) {
    for (int i = _chapterStartIndices.length - 1; i >= 0; i--) {
      if (globalIndex >= _chapterStartIndices[i]) {
        return i;
      }
    }
    return 0;
  }

  int _getImagePositionFromGlobal(int globalIndex, int chapterIndex) {
    if (chapterIndex >= _chapterStartIndices.length) return 0;
    return globalIndex - _chapterStartIndices[chapterIndex];
  }

  void _scrollToIndex(int index) {
    if (index < 0 || index >= _allImages.length) return;
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPositionChanged() {
    if (_itemPositionsListener.itemPositions.value.isEmpty) {
      return;
    }
    var position = _itemPositionsListener.itemPositions.value.first;
    int currentIndex = position.index;

    if (currentIndex >= 0 && currentIndex < _allImages.length) {
      int newChapterIndex = _getChapterIndexFromGlobal(currentIndex);
      int newImagePosition = _getImagePositionFromGlobal(
        currentIndex,
        newChapterIndex,
      );

      if (newChapterIndex != _currentChapterIndex ||
          newImagePosition != _currentImagePosition) {
        setState(() {
          _currentChapterIndex = newChapterIndex;
          _currentImagePosition = newImagePosition;
        });
        _saveAutoBookmark();
      }
    }
  }

  int _getCurrentChapterNumber() {
    if (widget.comic != null &&
        _currentChapterIndex >= 0 &&
        _currentChapterIndex < widget.comic!.chapters.length) {
      return widget.comic!.chapters[_currentChapterIndex].number;
    }
    return widget.chapterNumber ?? 1;
  }

  int _getTotalChapters() {
    return widget.comic?.chapters.length ?? widget.totalChapters ?? 1;
  }

  int _getTotalImagesInCurrentChapter() {
    if (widget.comic != null &&
        _currentChapterIndex >= 0 &&
        _currentChapterIndex < widget.comic!.chapters.length) {
      return widget.comic!.chapters[_currentChapterIndex].images.length;
    }
    return 0;
  }

  Future<void> _addManualBookmark() async {
    if (!_canSaveBookmark()) return;

    try {
      int chapterNumber = widget.comic!.chapters[_currentChapterIndex].number;
      String defaultName =
          '第 $chapterNumber 章 - 图片 ${_currentImagePosition + 1}';

      String? bookmarkName = await _showBookmarkNameDialog(defaultName);

      if (bookmarkName != null && bookmarkName.isNotEmpty) {
        await _saveManualBookmark(bookmarkName);
        _showSuccessMessage('书签已添加');
      }
    } catch (e) {
      _showErrorMessage('添加书签失败: $e');
    }
  }

  bool _canSaveBookmark() {
    return widget.comicName != null &&
        widget.comic != null &&
        _currentChapterIndex >= 0 &&
        _currentChapterIndex < widget.comic!.chapters.length;
  }

  Future<String?> _showBookmarkNameDialog(String defaultName) {
    TextEditingController controller = TextEditingController(text: defaultName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加书签'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '书签名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveManualBookmark(String name) async {
    if (!_canSaveBookmark()) return;

    int chapterNumber = widget.comic!.chapters[_currentChapterIndex].number;
    final bookmark = Bookmark(
      chapterNumber: chapterNumber,
      imagePosition: _currentImagePosition,
      name: name,
      createdAt: DateTime.now(),
      isAuto: false,
    );
    await _bookmarkManager.saveBookmark(widget.comicName!, bookmark);
  }

  Future<void> _saveAutoBookmark() async {
    if (!_canSaveBookmark()) return;

    try {
      int chapterNumber = widget.comic!.chapters[_currentChapterIndex].number;
      await _comicManager.saveReadingProgress(
        widget.comicName!,
        chapterNumber,
        _currentImagePosition,
      );
      final autoBookmark = Bookmark(
        chapterNumber: chapterNumber,
        imagePosition: _currentImagePosition,
        name: '最近阅读: 第 $chapterNumber 章 - 图片 ${_currentImagePosition + 1}',
        createdAt: DateTime.now(),
        isAuto: true,
      );
      await _bookmarkManager.saveBookmark(widget.comicName!, autoBookmark);
    } catch (e) {
      print('保存阅读进度失败: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildTitle() {
    int currentChapterNumber = _getCurrentChapterNumber();
    int totalChapters = _getTotalChapters();
    int currentImageInChapter = _currentImagePosition + 1;
    int totalImagesInChapter = _getTotalImagesInCurrentChapter();

    return '第 $currentChapterNumber 章/$totalChapters 章 - 图片 $currentImageInChapter/$totalImagesInChapter';
  }

  PreferredSizeWidget? _buildAppBar() {
    if (!_showAppBar) return null;

    return AppBar(
      title: Text(_buildTitle()),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_add),
          onPressed: _addManualBookmark,
          tooltip: '添加书签',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comic == null || _allImages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('漫画阅读')),
        body: const Center(child: Text('没有图片')),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _saveAutoBookmark();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: GestureDetector(
          onTap: () {
            setState(() {
              _showAppBar = !_showAppBar;
            });
          },
          child: ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemCount: _allImages.length,
            addSemanticIndexes: false,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final image = _allImages[index];
              final chapterIndex = _getChapterIndexFromGlobal(index);
              final imagePosition = _getImagePositionFromGlobal(
                index,
                chapterIndex,
              );
              final isChapterStart = imagePosition == 0;

              return ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isChapterStart)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.grey[850],
                        child: Text(
                          '第 ${chapterIndex + 1} 章',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Image(
                          image: FileImage(File(image.path)),
                          width: constraints.maxWidth,
                          fit: BoxFit.fitWidth,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                if (frame != null) {
                                  return child;
                                }
                                return Container(
                                  width: constraints.maxWidth,
                                  height: 300,
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        backgroundColor: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                );
                              },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionChanged);
    super.dispose();
  }
}
