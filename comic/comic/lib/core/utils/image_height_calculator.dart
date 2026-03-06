import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// 图片高度计算工具类
class ImageHeightCalculator {
  /// 计算图片的实际高度（基于屏幕宽度）
  static Future<double> calculateImageHeight(String imagePath) async {
    try {
      final screenWidth = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first,
      ).size.width;

      File imageFile = File(imagePath);
      Uint8List imageBytes = await imageFile.readAsBytes();

      ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      int width = frameInfo.image.width;
      int height = frameInfo.image.height;

      double aspectRatio = width / height;
      double displayHeight = screenWidth / aspectRatio;

      codec.dispose();
      frameInfo.image.dispose();

      return displayHeight;
    } catch (e) {
      return 1920.0;
    }
  }

  /// 批量计算图片高度
  static Future<List<double>> calculateImageHeights(List<String> imagePaths) async {
    List<double> heights = [];
    for (String path in imagePaths) {
      heights.add(await calculateImageHeight(path));
    }
    return heights;
  }
}
