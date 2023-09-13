import 'package:flutter/services.dart';
import 'package:wasm_ffi/wasm_ffi.dart';

import 'abstract_platform_provider.dart';

typedef UnsignedLong = Uint64;
typedef Size = Uint64;

class SwephPlatformProvider
    extends AbstractPlatformProvider<DynamicLibrary, Allocator> {
  static final Future<SwephPlatformProvider> _instance = _init();

  static Future<SwephPlatformProvider> get instance => _instance;

  SwephPlatformProvider._(super.lib, super.allocator, super.epheFilesPath);

  static Future<SwephPlatformProvider> _init() async {
    final bytes = await rootBundle.load('packages/sweph/assets/sweph.wasm');

    DynamicLibrary lib = await DynamicLibrary.open(WasmType.standalone,
        wasmBinary: bytes.buffer.asUint8List());

    return SwephPlatformProvider._(lib, lib.boundMemory, "ephe_files");
  }

  @override
  Future<void> saveEpheFile(String destFile, Uint8List contents) async {
    final destPath = "$epheFilesPath/$destFile";

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
