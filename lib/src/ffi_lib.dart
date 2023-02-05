// Notice that in this file, we import dart:ffi and not proxy_ffi.dart
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

const String _libName = 'sweph';

class SwephDynamicLib {
  static final Future<DynamicLibrary> _lib = _initLib();
  static final Allocator _allocator = Arena();

  static get lib => _lib;
  static get allocator => _allocator;

  static Future<DynamicLibrary> _initLib() async {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$_libName.framework/$_libName');
    } else if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$_libName.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('$_libName.dll');
    } else {
      throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
    }
  }
}

class ResourceUtils {
  static Future<void> extractAssets(String src, String dst) async {
    final dstFile = File(dst);
    dstFile.parent.createSync(recursive: true);
    try {
      final srcFile = await rootBundle.load(src);
      await dstFile.writeAsBytes(srcFile.buffer
          .asUint8List(srcFile.offsetInBytes, srcFile.lengthInBytes));
    } catch (e) {
      // ignore
    }
  }
}
