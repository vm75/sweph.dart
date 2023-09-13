export 'package:wasm_ffi/wasm_ffi.dart' if (dart.library.ffi) 'dart:ffi';
export 'package:wasm_ffi/wasm_ffi_utils.dart'
    if (dart.library.ffi) 'package:ffi/ffi.dart';
export 'wasm_provider.dart' if (dart.library.ffi) 'ffi_provider.dart';
export 'abstract_platform_provider.dart';
