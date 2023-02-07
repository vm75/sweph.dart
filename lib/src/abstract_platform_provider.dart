abstract class AbstractPlatformProvider<DynamicLibrary, Allocator> {
  static const epheAssetsPath = "packages/sweph/native/sweph/src/ephe_files";
  static const epheAssets = [
    "seas_18.se1",
    "seasnam.txt",
    "sefstars.txt",
    "seleapsec.txt",
    "seorbel.txt"
  ];
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

  Future<void> saveEpheAssets();
  Future<void> copyEpheFiles(String ephePath);
  Future<void> copyJplFile(String filePath);
}
