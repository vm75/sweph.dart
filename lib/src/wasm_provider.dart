import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:js/js_util.dart';
import 'package:wasm_interop/wasm_interop.dart' as interop;
import 'package:wasm_ffi/wasm_ffi.dart';
import 'package:wasm_ffi/wasm_ffi_modules.dart';
import 'package:wasm_ffi/wasm_ffi_meta.dart';

import 'abstract_platform_provider.dart';

typedef UnsignedLong = Uint64;
typedef Int = Int64;
typedef Size = Uint64;

/// Documentation is in `emscripten_module_stub.dart`!
@extra
class _WasmModule extends Module {
  final interop.Instance _instance;
  final List<WasmSymbol> _exports = [];

  @override
  List<WasmSymbol> get exports => _exports;

  static Future<_WasmModule> initFromAsset(String path) async {
    final bytes = await rootBundle.load(path);
    return initFromBuffer(bytes.buffer);
  }

  static Future<_WasmModule> initFromBuffer(ByteBuffer buffer) async {
    final wasmInstance =
        await interop.Instance.fromBytesAsync(buffer.asUint8List());
    return _WasmModule._(wasmInstance);
  }

  FunctionDescription _fromWasmFunction(String name, Function func, int index) {
    String? s = getProperty(func, 'name');
    if (s != null) {
      int? length = getProperty(func, 'length');
      if (length != null) {
        return FunctionDescription(
            tableIndex: index,
            name: name,
            function: func,
            argumentCount: length);
      }
    }
    throw ArgumentError('$name does not seem to be a function symbol!');
  }

  _WasmModule._(this._instance) {
    int index = 0;
    for (final e in _instance.functions.entries) {
      _exports.add(_fromWasmFunction(e.key, e.value, index++));
    }
  }

  @override
  void free(int pointer) {
    final func = _instance.functions['free'];
    func?.call(pointer);
  }

  @override
  ByteBuffer get heap => _instance.memories['memory']!.buffer;

  @override
  int malloc(int size) {
    final func = _instance.functions['malloc'];
    final resp = func?.call(size) as int;
    return resp;
  }

  Function? getMethod(String methodName) {
    return _instance.functions[methodName];
  }
}

class SwephPlatformProvider
    extends AbstractPlatformProvider<DynamicLibrary, Allocator> {
  static final Future<SwephPlatformProvider> _instance = _init();

  static Future<SwephPlatformProvider> get instance => _instance;

  final _WasmModule _module;

  SwephPlatformProvider._(
      this._module, super.lib, super.allocator, super.epheFilesPath);

  static Future<SwephPlatformProvider> _init() async {
    Memory.init();
    final module =
        await _WasmModule.initFromAsset('packages/sweph/assets/sweph.wasm');
    return SwephPlatformProvider._(module, DynamicLibrary.fromModule(module),
        Memory.global!, "ephe_files");
  }

  @override
  Future<void> saveEpheFile(String destFile, Uint8List contents) async {
    final destPath = "$epheFilesPath/$destFile";

    final destPathPtr = _copyToWasm(Uint8List.fromList(destPath.codeUnits));
    final dataPtr = _copyToWasm(contents);

    final writeFile = _module.getMethod('write_file')!;
    writeFile.call(destPathPtr, dataPtr, contents.length, 0);

    _module.free(destPathPtr);
  }

  int _copyToWasm(Uint8List data) {
    final size = data.length;
    final dataPtr = _module.malloc(size + 1);
    final memoryView = _module.heap.asUint8List();
    memoryView.setAll(dataPtr, data);
    memoryView[dataPtr + size] = 0;
    return dataPtr;
  }
}
