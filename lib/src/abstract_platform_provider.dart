import 'package:flutter/services.dart';

abstract class AbstractPlatformProvider<DynamicLibrary, Allocator> {
  final DynamicLibrary _lib;
  final Allocator _allocator;
  final String _epheFilesPath;
  final String _jplFilePath;

  AbstractPlatformProvider(
      this._lib, this._allocator, this._epheFilesPath, this._jplFilePath);

  DynamicLibrary get lib => _lib;
  Allocator get allocator => _allocator;
  String get epheFilesPath => _epheFilesPath;
  String get jplFilePath => _jplFilePath;

  Future<void> saveEpheAssets({List<String>? epheAssets}) async {
    for (final asset in epheAssets ?? []) {
      final destFile = asset.replaceAll(RegExp(r'.*[/\\]'), '');
      final contents = (await rootBundle.load(asset)).buffer.asUint8List();

      saveEpheFile(destFile, contents);
    }
  }

  Future<void> saveEpheFile(String destFile, Uint8List contents);
  Future<void> copyEpheFiles(String ephePath);
  Future<void> copyJplFile(String filePath);
}
