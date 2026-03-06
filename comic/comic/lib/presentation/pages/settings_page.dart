import 'package:flutter/material.dart';
import '../../core/models/comic_model.dart';
import '../../core/utils/comic_manager.dart';
import '../../core/utils/app_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ComicManager comicManager = ComicManager();
  final AppConfig appConfig = AppConfig();
  int _comicCount = 0;
  int _chapterCount = 0;
  int _imageCount = 0;
  List<Comic> _comics = [];
  List<bool> _selectedComics = [];
  bool _isSelectMode = false;
  ImportMode _importMode = ImportMode.progressive;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await appConfig.load();
    setState(() {
      _importMode = appConfig.importMode;
    });
  }

  Future<void> _loadData() async {
    await _loadStatistics();
    await _loadComics();
  }

  Future<void> _loadStatistics() async {
    try {
      final comics = await comicManager.loadComics();
      setState(() {
        _comicCount = comics.length;
        _chapterCount = comics.fold(
          0,
          (sum, comic) => sum + comic.chapters.length,
        );
        _imageCount = comics.fold(
          0,
          (sum, comic) =>
              sum +
              comic.chapters.fold(
                0,
                (sum, chapter) => sum + chapter.images.length,
              ),
        );
      });
    } catch (e) {
      print('加载统计数据失败: $e');
    }
  }

  Future<void> _loadComics() async {
    try {
      _comics = await comicManager.loadComics();
      _selectedComics = List<bool>.filled(_comics.length, false);
      setState(() {});
    } catch (e) {
      print('加载漫画失败: $e');
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedComics = List<bool>.filled(_comics.length, false);
    });
  }

  void _toggleComicSelection(int index) {
    setState(() {
      _selectedComics[index] = !_selectedComics[index];
    });
  }

  void _showDeleteComicsConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除选中的漫画吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSelectedComics();
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedComics() async {
    try {
      List<int> selectedIndices = [];
      for (int i = 0; i < _selectedComics.length; i++) {
        if (_selectedComics[i]) {
          selectedIndices.add(i);
        }
      }

      if (selectedIndices.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请选择要删除的漫画')));
        return;
      }

      selectedIndices.sort((a, b) => b.compareTo(a));
      for (int index in selectedIndices) {
        await comicManager.removeComic(index);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除成功')));
      _loadData();
      _toggleSelectMode();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  void _showImportModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('导入配置'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ImportMode>(
                    title: const Text('渐进式加载'),
                    subtitle: const Text('先加载前10章图片尺寸，其余后台加载'),
                    value: ImportMode.progressive,
                    groupValue: _importMode,
                    onChanged: (value) {
                      setState(() {
                        _importMode = value!;
                      });
                    },
                  ),
                  RadioListTile<ImportMode>(
                    title: const Text('一次性加载'),
                    subtitle: const Text('导入时加载所有图片尺寸'),
                    value: ImportMode.allAtOnce,
                    groupValue: _importMode,
                    onChanged: (value) {
                      setState(() {
                        _importMode = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    await appConfig.setImportMode(_importMode);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('配置已保存')));
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showClearAllDataConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认清除所有数据'),
          content: const Text('确定要清除所有漫画和书签吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearAllData();
              },
              child: const Text('清除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllData() async {
    try {
      await comicManager.clearAllData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('所有数据已清除')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清除失败: $e')));
    }
  }

  void _showChapterDeleteDialog(Comic comic, int comicIndex) {
    showDialog(
      context: context,
      builder: (context) {
        List<bool> selectedChapters = List<bool>.filled(
          comic.chapters.length,
          false,
        );
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('删除章节 - ${comic.name}'),
              content: SingleChildScrollView(
                child: Column(
                  children: comic.chapters.asMap().entries.map((entry) {
                    int index = entry.key;
                    Chapter chapter = entry.value;
                    return CheckboxListTile(
                      title: Text(
                        '第 ${chapter.number} 章 (${chapter.images.length} 页)',
                      ),
                      value: selectedChapters[index],
                      onChanged: (value) {
                        setState(() {
                          selectedChapters[index] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    List<int> selectedIndices = [];
                    for (int i = 0; i < selectedChapters.length; i++) {
                      if (selectedChapters[i]) {
                        selectedIndices.add(i);
                      }
                    }

                    if (selectedIndices.isEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请选择要删除的章节')),
                      );
                      return;
                    }

                    selectedIndices.sort((a, b) => b.compareTo(a));
                    for (int index in selectedIndices) {
                      await comicManager.removeChapter(comicIndex, index);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('章节删除成功')));
                    _loadData();
                  },
                  child: const Text('删除'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: _isSelectMode
            ? [
                TextButton(
                  onPressed: _showDeleteComicsConfirmDialog,
                  child: const Text('删除'),
                ),
              ]
            : [],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  const Text(
                    '漫画库统计',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('漫画', _comicCount.toString()),
                      _buildStatItem('章节', _chapterCount.toString()),
                      _buildStatItem('图片', _imageCount.toString()),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.select_all,
                    title: _isSelectMode ? '取消选择' : '管理漫画',
                    subtitle: _isSelectMode ? '取消多选模式' : '多选删除漫画',
                    onTap: _toggleSelectMode,
                  ),
                  if (_isSelectMode)
                    ..._comics.asMap().entries.map((entry) {
                      int index = entry.key;
                      Comic comic = entry.value;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFF0F0F0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedComics[index],
                              onChanged: (value) =>
                                  _toggleComicSelection(index),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comic.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '${comic.chapters.length} 章',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  if (!_isSelectMode && _comics.isNotEmpty)
                    ..._comics.asMap().entries.map((entry) {
                      int index = entry.key;
                      Comic comic = entry.value;
                      return _buildMenuItem(
                        icon: Icons.book,
                        title: comic.name,
                        subtitle: '${comic.chapters.length} 章',
                        onTap: () => _showChapterDeleteDialog(comic, index),
                      );
                    }).toList(),
                  if (!_isSelectMode && _comics.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Text(
                          '暂无漫画',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.settings_applications,
                    title: '导入配置',
                    subtitle: _importMode == ImportMode.progressive
                        ? '渐进式加载（推荐）'
                        : '一次性加载',
                    onTap: _showImportModeDialog,
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_forever,
                    title: '清除所有数据',
                    subtitle: '清除所有漫画和书签',
                    onTap: _showClearAllDataConfirmDialog,
                  ),
                  _buildMenuItem(
                    icon: Icons.info,
                    title: '关于',
                    subtitle: '版本信息',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: '漫画阅读器',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.book, size: 48),
                        applicationLegalese: '© 2026 漫画阅读器',
                        children: const [Text('一个简单的本地漫画阅读应用')],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          ),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
