// Notice that in this file, we import dart:ffi and not proxy_ffi.dart
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart';

import 'abstract_platform_provider.dart';

class SwephPlatformProvider
    extends AbstractPlatformProvider<DynamicLibrary, Allocator> {
  static SwephPlatformProvider? _instance;

  SwephPlatformProvider._(super.lib, super.allocator, super.epheFilesPath);

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

  static Future<SwephPlatformProvider> init(
      String modulePath, String epheFilesPath) async {
    if (_instance == null) {
      final library = await _initLib();

      _instance = SwephPlatformProvider._(library, Arena(), epheFilesPath);

      final epheDir = Directory(epheFilesPath);
      epheDir.createSync(recursive: true);
    }

    return _instance!;
  }

  @override
  Future<void> saveEpheFile(String destFile, Uint8List contents) async {
    final destPath = File('$epheFilesPath/$destFile');
    if (destPath.existsSync()) {
      return;
    }
    destPath.writeAsBytesSync(contents);
  }

  @override
  void copyEpheDir(String epheFilesDir, bool forceOverwrite) {
    final srcDir = Directory(epheFilesDir);
    if (!srcDir.existsSync()) {
      return;
    }

    for (final file in srcDir.listSync()) {
      if (file is! File) {
        continue;
      }
      copyEpheFile(file.path, forceOverwrite);
    }
  }

  @override
  void copyEpheFile(String filePath, bool forceOverwrite) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return;
    }

    final filename = basename(filePath);
    final destFile = File('$epheFilesPath/$filename');
    if (destFile.existsSync() && !forceOverwrite) {
      return;
    }

    destFile.writeAsBytesSync(file.readAsBytesSync());
  }
}
