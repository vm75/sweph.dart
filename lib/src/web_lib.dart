import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:js/js_util.dart';
import 'package:wasm_interop/wasm_interop.dart' as interop;
import 'package:web_ffi/web_ffi.dart';
import 'package:web_ffi/web_ffi_modules.dart';
import 'package:web_ffi/web_ffi_meta.dart';

typedef Char = Uint8;
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
    final wasmInstance = await interop.Instance.fromBufferAsync(buffer);
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
}

class SwephDynamicLib {
  static final Future<DynamicLibrary> _lib = _initLib();
  static final Allocator _allocator = _memory();

  static get lib => _lib;
  static get allocator => _allocator;

  static _memory() {
    Memory.init();
    return Memory.global!;
  }

  static Future<DynamicLibrary> _initLib() async {
    final module =
        await _WasmModule.initFromAsset('packages/sweph/assets/sweph.wasm');
    return DynamicLibrary.fromModule(module);
  }
}
