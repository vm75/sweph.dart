import 'dart:typed_data';

import 'package:wasm_ffi/ffi_bridge.dart';
import 'abstract_platform_provider.dart';

class SwephPlatformProvider
    extends AbstractPlatformProvider<DynamicLibrary, Allocator> {
  static SwephPlatformProvider? _instance;

  SwephPlatformProvider._(super.lib, super.allocator, super.epheFilesPath);

  static Future<SwephPlatformProvider> init(
      String modulePath, String epheFilesPath) async {
    if (_instance == null) {
      final library = await DynamicLibrary.open(modulePath);

      _instance =
          SwephPlatformProvider._(library, library.memory, epheFilesPath);
    }

    return _instance!;
  }

  @override
  Future<void> saveEpheFile(String destFile, Uint8List contents) async {
    final destPath = '$epheFilesPath/$destFile';

    final destPathPtr = _copyToWasm(Uint8List.fromList(destPath.codeUnits));
    final dataPtr = _copyToWasm(contents);

    final writeFile = lib.lookupFunction('write_file');
    writeFile.call(destPathPtr, dataPtr, contents.length, 0);

    lib.module.free(destPathPtr);
  }

  int _copyToWasm(Uint8List data) {
    final size = data.length;
    final dataPtr = lib.module.malloc(size + 1);
    final memoryView = lib.module.heap.asUint8List();
    memoryView.setAll(dataPtr, data);
    memoryView[dataPtr + size] = 0;
    return dataPtr;
  }
}
