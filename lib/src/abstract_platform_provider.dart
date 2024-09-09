import 'dart:typed_data';

import 'package:path/path.dart';

import '../sweph.dart' show AssetLoader;

abstract class AbstractPlatformProvider<DynamicLibrary, Allocator> {
  final DynamicLibrary _lib;
  final Allocator _allocator;
  final String _epheFilesPath;

  AbstractPlatformProvider(this._lib, this._allocator, this._epheFilesPath);

  DynamicLibrary get lib => _lib;
  Allocator get allocator => _allocator;
  String get epheFilesPath => _epheFilesPath;

  Future<void> saveEpheAssets(
      List<String> epheAssets, AssetLoader assetLoader) async {
    for (final asset in epheAssets) {
      final destFile = basename(asset);
      final contents = await assetLoader.load(asset);

      saveEpheFile(destFile, contents);
    }
  }

  Future<void> saveEpheFile(String destFile, Uint8List contents);
  void copyEpheDir(String epheFilesDir, bool forceOverwrite) {}
  void copyEpheFile(String filePath, bool forceOverwrite) {}
}
