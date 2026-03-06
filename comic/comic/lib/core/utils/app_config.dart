import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum ImportMode {
  progressive,
  allAtOnce,
}

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  ImportMode _importMode = ImportMode.progressive;
  ImportMode get importMode => _importMode;

  Future<void> load() async {
    try {
      final file = await _getConfigFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final json = jsonDecode(content);
        _importMode = ImportMode.values[json['importMode'] ?? 0];
      }
    } catch (e) {
      print('加载配置失败: $e');
    }
  }

  Future<void> setImportMode(ImportMode mode) async {
    _importMode = mode;
    await _save();
  }

  Future<void> _save() async {
    try {
      final file = await _getConfigFile();
      final json = {'importMode': _importMode.index};
      file.writeAsStringSync(jsonEncode(json));
    } catch (e) {
      print('保存配置失败: $e');
    }
  }

  Future<File> _getConfigFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}${Platform.pathSeparator}app_config.json');
  }
}
