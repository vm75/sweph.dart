import 'package:universal_ffi/ffi_helper.dart';

Future<FfiHelper> loadSwephLibrary(String? modulePath) async {
  return FfiHelper.load(
    modulePath ?? 'sweph',
    options: {
      if (modulePath == null) LoadOption.isFfiPlugin,
      LoadOption.isStandaloneWasm,
    },
    overrides: {
      if (modulePath != null) appType: modulePath,
    },
  );
}
