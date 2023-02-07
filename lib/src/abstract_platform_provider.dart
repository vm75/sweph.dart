import 'package:flutter/services.dart';
import 'package:path/path.dart';

abstract class AbstractPlatformProvider<DynamicLibrary, Allocator> {
  final DynamicLibrary _lib;
  final Allocator _allocator;
  final String _epheFilesPath;

  AbstractPlatformProvider(this._lib, this._allocator, this._epheFilesPath);

  DynamicLibrary get lib => _lib;
  Allocator get allocator => _allocator;
  String get epheFilesPath => _epheFilesPath;

  Future<void> saveEpheAssets(List<String>? epheAssets) async {
    for (final asset in epheAssets ?? []) {
      final destFile = basename(asset);
      final contents = (await rootBundle.load(asset)).buffer.asUint8List();

      saveEpheFile(destFile, contents);
    }
  }

  Future<void> saveEpheFile(String destFile, Uint8List contents);
  void copyEpheDir(String epheFilesDir, bool forceOverwrite) {}
  void copyEpheFile(String filePath, bool forceOverwrite) {}
}
