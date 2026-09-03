# Sweph

Cross-platform bindings of Swiss Ephemeris APIs for Dart & Flutter.
Everything you need to create Astrology and Astronomy applications with Dart and Flutter.

* 100% API coverage
* Dart friendly parameters and return values
* Supported on all platforms. Uses `dart:ffi` for non-Web platforms and [universal_ffi](https://pub.dev/packages/universal_ffi) / [wasm_ffi](https://pub.dev/packages/wasm_ffi) for Web
* Original Swiss Ephemeris version used as build number for reference

References:
- [Official programmers documentation for the Swiss Ephemeris by Astrodienst AG](https://www.astro.com/swisseph/swephprg.htm)
- [Official guide for the Swiss Ephemeris by Astrodienst AG](https://www.astro.com/ftp/swisseph/doc/swisseph.htm)
- [Official site for source and ehemeris files](https://www.astro.com/ftp/swisseph/)
- [Sweph for Flutter on Github](https://github.com/vm75/sweph.dart)
- [Sweph on pub.dev](https://pub.dev/packages/sweph)

## Usage example
```dart
import 'package:sweph/sweph.dart';

Future<void> main() async {
  // Sweph comes bundled with some ephe files. These are available for Flutter but not for vanilla Dart.
  // These or any other bundled ephe files can be initialized during Sweph.init.
  // For non-Web platforms, these are copied to the epheFilesPath (e.g. <ApplicationSupportDirectory>/ephe_files).
  // For Web, this is the only way to provide ephe files, and they are loaded into Wasm memory.
  // NOTE: For standard Flutter apps, omit `modulePath` (it defaults to null to use native plugin loading).
  await Sweph.init(
    epheAssets: [
      "packages/sweph/assets/ephe/sefstars.txt",
    ],
    assetLoader: SomeLoader(), // platform-specific asset loader (e.g. rootBundle).
    epheFilesPath: 'ephe_files', // where to store ephe files.
  );
  // refer to example. Both Flutter and vanilla Dart examples are available

  // alternately if a folder already contains ephe files, Sweph can be used in sync mode like this:
  // await Sweph.swe_set_ephe_path(<path-to-existing-folder>)
  // This is not available for Web

  print('sweph.swe_version = ${Sweph.swe_version()}');
  print('Moon longitude on 2022-06-29 02:52:00 UTC = ${Sweph.swe_calc_ut(Sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL), HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH).longitude}');

  // Most methods use positional parameters, not named. So if some positional parameters take default values, please refer to original documentation
  // If only some specific flags are allowed for a method, it is restricted via the enumerated flags
  // For example, to set the sidereal mode to Lahiri with projection onto solar system plane and custom t0 in UT
  Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI, SiderealModeFlag.SE_SIDBIT_SSY_PLANE, 123.45 /* t0 */);
  // or, to set the sidereal mode to Lahiri with no flags and custom ayan_t0 in UT
  Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI, SiderealModeFlag.SE_SIDBIT_NONE, 0.0 /* t0 */, 987.65 /* ayan_t0 */);
}
```

## Licensing

This library follows the licensing model of the Swiss Ephemeris by Astrodienst AG. Detailed information and material classification are documented in [LICENSING.md](LICENSING.md).

### AGPL-3.0-only (Open Source Path)

By default, this package and the bundled Swiss Ephemeris code are licensed under the GNU Affero General Public License Version 3 (**`AGPL-3.0-only`**).

### LGPL-3.0-only (Professional License Path)

For users who hold an applicable Swiss Ephemeris Professional License purchased directly from Astrodienst AG:
- Clearly maintainer-authored portions of `sweph.dart` may additionally be used under **`LGPL-3.0-only`**.
- This grant does **not** relicense material owned by Astrodienst AG (Swiss Ephemeris C source, ephemeris data files, and derived binaries remain governed by your Astrodienst license agreement).
- See [LICENSING.md](LICENSING.md) for exact material classifications, notice preservation rules, and version-specific declarations (such as [`doc/licensing/3.2.1+2.10.3.md`](doc/licensing/3.2.1+2.10.3.md)).

## Versioning

This package integrates the upstream Swiss Ephemeris version into its composite version string using the format:

```
<package_version>+<sweph_version>
```

For example, in `4.0.0+2.10.3`:
* **Package Version (`4.0.0`)**: Follows [Semantic Versioning (SemVer)](https://semver.org/) for Dart/Flutter wrapper APIs, platform integrations, build tooling, and package-level features or fixes:
  * **Major**: Breaking API changes, major platform requirement shifts, or major toolchain updates.
  * **Minor**: Backward-compatible new functionality or wrapper enhancements.
  * **Patch**: Backward-compatible bug fixes and minor adjustments.
* **Build Number (`+2.10.3`)**: Denotes the exact upstream Swiss Ephemeris C library version bundled in the release (extracted directly from `SE_VERSION` in `native/sweph/src/sweph.h`). Whenever the underlying Swiss Ephemeris C sources are upgraded, this build component is updated to reflect the upstream calculation engine version.

Platform build files (`pubspec.yaml`, iOS/macOS Podspecs, Android Gradle, and Linux/Windows CMake) are synchronized automatically via `tool/bump_version.dart`.

## Ephemeris files

The following ephemeris files are bundled with this plugin:
  * seas_18.se1    - main ephemeris for asteroids (1800-2400 CE)
  * semo_18.se1    - main ephemeris for moon (1800-2400 CE)
  * sepl_18.se1    - main ephemeris for planets (1800-2400 CE)
  * seasnam.txt    - list of asteroids
  * sefstars.txt   - fixed stars data file
  * seleapsec.txt  - dates of leap seconds to be taken into account
  * seorbel.txt    - orbital elements of ficticious planets :)

These could also be download from [https://www.astro.com/ftp/swisseph/ephe/](https://www.astro.com/ftp/swisseph/ephe/).
More information can be found in the [Swiss Ephemeris files documentation](https://www.astro.com/ftp/swisseph/doc/swisseph.htm#_Toc58931065).

## Platform Support and Packaging

Sweph supports all Flutter platforms:

* **macOS & iOS**: Fully supports both **Swift Package Manager** (default in Flutter 3.44+) and **CocoaPods**. `Package.swift` manifests are included for each platform, compiling the canonical C sources cleanly as dynamic frameworks.
* **Android**: Modernized Gradle build supporting 16 KB page sizes with NDK r28 and compileSdk 36.
* **Linux & Windows**: CMake-based native library compilation.
* **Web**: Compiled to WebAssembly using Emscripten and standalone Wasm, loaded via `universal_ffi` / `wasm_ffi`, and fully supported under both `dart2js` (normal Flutter Web) and `dart2wasm` (Flutter Web with `--wasm`).

### Native Library Loading

In ordinary Flutter applications, simply call `Sweph.init()` without specifying a `modulePath`:
```dart
await Sweph.init();
```
Flutter's plugin loader handles resolution of the native shared library/framework on all platforms automatically.

For custom standalone Dart CLI scripts, desktop builds without Flutter tooling, or custom library paths, you can provide an explicit path:
```dart
await Sweph.init(modulePath: '/path/to/libsweph.dylib');
```
Alternatively, set the `SWEPH_DYLIB_PATH` environment variable.

### Testing with `flutter_test`

Because `flutter test` executes in a headless host test runner (`flutter_tester`) that does not automatically build or bundle native platform frameworks into `@rpath`:

1. `Sweph.init()` includes automatic fallback resolution: if the application was previously built (via `flutter build macos`, `flutter run`, etc.), `Sweph.init()` locates the compiled framework in the project's build output (`build/macos/Build/Products/...`) and loads it seamlessly.
2. Alternatively, specify an explicit library location via `Sweph.init(modulePath: ...)` or the `SWEPH_DYLIB_PATH` environment variable.
3. For pure Dart unit tests that do not need Swiss Ephemeris calculations, you can test higher-level logic independently, or run integration tests via `flutter test integration_test` where the full native application bundle is executed.

## Using bundled Ephemeris files
`Sweph.init` accepts a list of ephemeris files as assets. These could be any of the bundled ones or other app assets. It does not accept local file path!
### non-Web
These are cached in \<ApplicationSupportDirectory\>/ephe_files folder. First load will be slow.
Async methods `swe_set_ephe_path` & `swe_set_jpl_file` could be called to set new ephe files.
If file already present, it is not overwritten, unless `forceOverwrite` is true.
### Web
`Sweph.init` is the only way to provide ephe files, and they are loaded into Wasm memory during initialization. This is a limitation of the Web plugin.
Calls to `swe_set_ephe_path` have no effect on Web. Only the loaded assets are used.
If custom JPL files are needed, they need to be loaded with the name "jpl_file.eph" during init and `swe_set_jpl_file` could be called.

## Contributing

If you find any innacuracy or bug in this library, or if you find an update that is not yet included in this library, feel free to open an issue or a pull request.

## Known Issues and Caveats

* The included ephe files are available async only
* Due to how the underlying C library operates, you may find that the `error` field returned by some functions will contain random data even if there is no actual error. This can happen when existing memory buffers are recycled therefore the user must always check the returned flag values as per the Swiss Ephemeris documentation.

## Author

Copyright © 2022, VM75
