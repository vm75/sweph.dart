import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class ResourceUtils {
  static Future<void> extractAssets(String src, String dst) async {
    final dstFile = File(dst);
    dstFile.parent.createSync(recursive: true);
    try {
      final srcFile = await rootBundle.load(src);
      await dstFile.writeAsBytes(srcFile.buffer
          .asUint8List(srcFile.offsetInBytes, srcFile.lengthInBytes));
    } catch (e) {
      // ignore
    }
  }
}
