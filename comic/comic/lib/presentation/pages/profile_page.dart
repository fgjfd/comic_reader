import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/zip_importer.dart';
import '../../core/utils/comic_manager.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ComicManager comicManager = ComicManager();
  bool _isImporting = false;
  StreamController<ImportProgress>? _progressController;

  Future<void> _importZip() async {
    if (_isImporting || comicManager.isImporting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在导入中，请稍候...')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    _progressController = StreamController<ImportProgress>.broadcast();

    _showImportProgressDialog();

    try {
      final comics = await comicManager.loadComics();
      final newComic = await ZipImporter.importZip(
        comics,
        onProgress: (progress) {
          _progressController?.add(progress);
        },
      );

      await _progressController?.close();
      _progressController = null;

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (newComic != null) {
        await comicManager.saveComic(newComic);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导入成功')),
          );
        }
      }
    } catch (e) {
      await _progressController?.close();
      _progressController = null;

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  void _showImportProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('正在导入漫画'),
            content: StreamBuilder<ImportProgress>(
              stream: _progressController?.stream,
              initialData: ImportProgress(
                stage: '准备',
                current: 0,
                total: 100,
                message: '准备导入...',
              ),
              builder: (context, snapshot) {
                final progress = snapshot.data;
                final percentage = progress?.percentage ?? 0.0;
                final message = progress?.message ?? '准备导入...';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _progressController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.file_download,
                    title: '导入漫画',
                    subtitle: '从压缩包导入漫画',
                    onTap: _importZip,
                    isLoading: _isImporting,
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: '阅读历史',
                    subtitle: '查看最近阅读记录',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('功能开发中')),
                      );
                    },
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
                    icon: Icons.settings,
                    title: '设置',
                    subtitle: '应用设置',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, color: Colors.grey[600], size: 20),
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
            if (!isLoading) const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
