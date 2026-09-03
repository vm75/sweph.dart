import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:universal_ffi/ffi.dart';
import 'package:universal_ffi/ffi_helper.dart';

Future<FfiHelper> loadSwephLibrary(String? modulePath) async {
  if (modulePath != null) {
    return FfiHelper.load(
      modulePath,
      options: {LoadOption.isStandaloneWasm},
      overrides: {appType: modulePath},
    );
  }

  // 1. Try standard Flutter FFI plugin loading (default for production apps).
  try {
    return await FfiHelper.load(
      'sweph',
      options: {
        LoadOption.isFfiPlugin,
        LoadOption.isStandaloneWasm,
      },
    );
  } catch (error) {
    // 2. Check if symbols are available in the current process (e.g. iOS static linking or SwiftPM static library).
    try {
      final process = DynamicLibrary.process();
      process.lookup('swe_version');
      return await FfiHelper.load(
        '',
        options: {LoadOption.isStaticallyLinked},
      );
    } catch (_) {}

    // 3. Check environment variable SWEPH_DYLIB_PATH.
    final envPath = Platform.environment['SWEPH_DYLIB_PATH'];
    if (envPath != null && File(envPath).existsSync()) {
      try {
        return await FfiHelper.load(
          envPath,
          overrides: {appType: envPath},
        );
      } catch (_) {}
    }

    // 4. Check candidate library paths in build outputs (e.g. during flutter test).
    for (final candidate in _findCandidateLibraryPaths()) {
      if (File(candidate).existsSync()) {
        try {
          return await FfiHelper.load(
            candidate,
            overrides: {appType: candidate},
          );
        } catch (_) {}
      }
    }

    // If none succeeded, rethrow the original error.
    rethrow;
  }
}

List<String> _findCandidateLibraryPaths() {
  final candidates = <String>[];
  final searchDirs = <Directory>[
    Directory.current,
    Directory.current.parent,
  ];

  for (final base in searchDirs) {
    if (!base.existsSync()) continue;
    if (Platform.isMacOS) {
      final productDirs = [
        Directory(p.join(base.path, 'build', 'macos', 'Build', 'Products')),
        Directory(p.join(
            base.path, 'example', 'build', 'macos', 'Build', 'Products')),
      ];
      for (final macosBuildProducts in productDirs) {
        if (macosBuildProducts.existsSync()) {
          try {
            for (final entity in macosBuildProducts.listSync(recursive: true)) {
              if (entity is File &&
                  (entity.path.endsWith('sweph.framework/sweph') ||
                      entity.path
                          .endsWith('sweph.framework/Versions/A/sweph'))) {
                candidates.add(entity.path);
              }
            }
          } catch (_) {}
        }
      }
      candidates.add(p.join(base.path, 'libsweph.dylib'));
      candidates.add(p.join(base.path, 'native', 'libsweph.dylib'));
    } else if (Platform.isLinux) {
      candidates.add(p.join(base.path, 'build', 'linux', 'x64', 'debug',
          'bundle', 'lib', 'libsweph.so'));
      candidates.add(p.join(base.path, 'build', 'linux', 'x64', 'release',
          'bundle', 'lib', 'libsweph.so'));
      candidates.add(p.join(base.path, 'libsweph.so'));
      candidates.add(p.join(base.path, 'native', 'libsweph.so'));
    } else if (Platform.isWindows) {
      candidates.add(p.join(base.path, 'build', 'windows', 'x64', 'runner',
          'Debug', 'sweph.dll'));
      candidates.add(p.join(base.path, 'build', 'windows', 'x64', 'runner',
          'Release', 'sweph.dll'));
      candidates.add(p.join(base.path, 'sweph.dll'));
      candidates.add(p.join(base.path, 'native', 'sweph.dll'));
    }
  }
  return candidates;
}
