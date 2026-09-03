// Notice that in this file, we import dart:ffi and not proxy_ffi.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:universal_ffi/ffi.dart';

import 'abstract_asset_saver.dart';

class SwephAssetSaver extends AbstractAssetSaver<DynamicLibrary, Allocator> {
  static SwephAssetSaver? _instance;
  bool _directoryCreated = false;

  SwephAssetSaver._(super.epheFilesPath);

  void _ensureDirectoryExists() {
    if (_directoryCreated) return;
    final epheDir = Directory(epheFilesPath);
    if (!epheDir.existsSync()) {
      epheDir.createSync(recursive: true);
    }
    _directoryCreated = true;
  }

  static Future<SwephAssetSaver> init(
    DynamicLibrary library,
    String epheFilesPath,
  ) async {
    _instance ??= SwephAssetSaver._(epheFilesPath);
    return _instance!;
  }

  @override
  Future<void> saveEpheFile(String destFile, Uint8List contents) async {
    _ensureDirectoryExists();
    final destPath = File('$epheFilesPath/$destFile');
    if (destPath.existsSync()) {
      return;
    }
    destPath.writeAsBytesSync(contents);
  }

  @override
  void copyEpheDir(String epheFilesDir, bool forceOverwrite) {
    final srcDir = Directory(epheFilesDir);
    if (!srcDir.existsSync()) {
      return;
    }

    _ensureDirectoryExists();
    for (final file in srcDir.listSync()) {
      if (file is! File) {
        continue;
      }
      copyEpheFile(file.path, forceOverwrite);
    }
  }

  @override
  void copyEpheFile(String filePath, bool forceOverwrite) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return;
    }

    _ensureDirectoryExists();
    final filename = basename(filePath);
    final destFile = File('$epheFilesPath/$filename');
    if (destFile.existsSync() && !forceOverwrite) {
      return;
    }

    destFile.writeAsBytesSync(file.readAsBytesSync());
  }
}
