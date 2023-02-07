// Notice that in this file, we import dart:ffi and not proxy_ffi.dart
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'abstract_platform_provider.dart';

class SwephPlatformProvider
    extends AbstractPlatformProvider<DynamicLibrary, Allocator> {
  static final Future<SwephPlatformProvider> _instance = _init();

  SwephPlatformProvider._(
      super.lib, super.allocator, super.epheFilesPath, super.jplFilePath);

  static Future<SwephPlatformProvider> get instance => _instance;

  @override
  Future<void> saveEpheAssets() async {
    for (final file in AbstractPlatformProvider.epheAssets) {
      final destFile = File("$epheFilesPath/$file");
      if (destFile.existsSync()) {
        continue;
      }
      final assetPath = "${AbstractPlatformProvider.epheAssetsPath}/$file";
      final data = await rootBundle.load(assetPath);
      destFile.writeAsBytesSync(data.buffer.asUint8List());
    }
  }

  @override
  Future<void> copyEpheFiles(String ephePath) async {
    final srcDir = Directory(ephePath);
    if (!srcDir.existsSync()) {
      return;
    }

    for (final file in srcDir.listSync()) {
      if (file is! File) {
        continue;
      }
      final filename = basename(file.path);
      final destFile = File("$epheFilesPath/$filename");
      if (destFile.existsSync()) {
        continue;
      }

      destFile.writeAsBytesSync(file.readAsBytesSync());
    }
  }

  @override
  Future<void> copyJplFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return;
    }

    final destFile = File(jplFilePath);
    if (destFile.existsSync()) {
      return;
    }

    destFile.writeAsBytesSync(file.readAsBytesSync());
  }

  static Future<SwephPlatformProvider> _init() async {
    final appDocDir = (await getApplicationSupportDirectory()).path;
    final epheDir = Directory("$appDocDir/ephe_files");
    epheDir.createSync(recursive: true);
    return SwephPlatformProvider._(await _initLib(), Arena(), epheDir.path,
        "${epheDir.path}/jpl_file.eph");
  }

  static Future<DynamicLibrary> _initLib() async {
    const String swephLibName = 'sweph';

    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$swephLibName.framework/$swephLibName');
    } else if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$swephLibName.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('$swephLibName.dll');
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
