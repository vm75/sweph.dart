# Sweph

Cross-platform bindings of Swiss Ephemeris APIs for Flutter/Dart.
Everything you need to create Astrology and Astronomy applications with Dart and Flutter.

* 100% API coverage
* Dart friendly parameters and return values
* Intended to be supported on Android, iOS, Linux, MacOS, Windows (not tested on iOS/MacOS)
* Version matched with source

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
  try {
    final sweph = Sweph();

    await sweph.useDefaultEpheFiles(); // Extracts included ephe files
    // alternately if a folder already contains ephe files, Sweph can be used in sync mode like this:
    // sweph.swe_set_ephe_path(<path-to-existing-folder>)
    // please check example

    print('sweph.swe_version = ${sweph.swe_version()}');
    print('Moon longitude on 2022-06-29 02:52:00 UTC = ${sweph.swe_calc_ut(sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL), HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH).longitude}');

    // Most methods use positional parameters, not named. So if some positional parameters take default values, please refer to original documentation
    // If only some specific flags are allowed for a method, it is restricted via the enumerated flags
    // For example, to set the sidereal mode to Lahiri with projection onto solar system plane and custom t0 in UT
    sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI, SiderealModeFlag.SE_SIDBIT_SSY_PLANE, 123.45 /* t0 */);
    // or, to set the sidereal mode to Lahiri with no flags and custom ayan_t0 in UT
    sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI, SiderealModeFlag.SE_SIDBIT_NONE, 0.0 /* t0 */, 987.65 /* ayan_t0 */);
  }
}
```

## Licensing

This library follows the licensing requirements for the Swiss Ephemeris by Astrodienst AG.

### - AGPL

Starting from version `2.10.02` and later, this library is licensed under `AGPL-3.0`.
To install and use the latest version of this library under AGPL, use `flutter pub add sweph`.

### - LGPL

If you own a professional license for the Swiss Ephemeris, you may use any version of this library under `LGPL-3.0`.

## Versioning

This library is version locked to the Swiss Ephemeris in addition to its own revisions. For example, version `2.10.02+1` corresponds to the Swiss Ephemeris version `2.10.02` and this library's revision `1`.

Updates to this library will be released under new revisions, while updates to Swiss Ephemeris will be released under matching semver versions.

## Ephemeris files

This library does not include any ephemeris files. The following text files are included:
* sefstars.txt - Swiss Ephemeris fixed stars data file
* seasnam.txt - actually ast_list.txt, a small list of asteroids

To use the Swiss Ephemeris files, download them from [https://www.astro.com/ftp/swisseph/ephe/](https://www.astro.com/ftp/swisseph/ephe/) and call `set_ephe_path()` to point the library to the folder containing the ephemeris files.
Each main ephemeris file covers a range of 600 years starting from the century indicated in its name, for example the file `sepl_18.se1` is valid from year 1800 until year 2400. The following files are available:

* sepl files - planets (AD)
* seplm files - planets (BC)
* semo files - moon (AD)
* semom files - moon (BC)
* seas files - main asteroids (AD)
* seasm files - main asteroids (BC)

For advanced usage, the following files can also be found:

* astxxx folders - files for individual asteroids (600 years)
* longfiles folder - files for individual asteroids (6000 years)
* jplfiles folder - files for nasa's jpl ephemerides
* sat folder - files for planetary moons

More information can be found in the [Swiss Ephemeris files documentation](https://www.astro.com/ftp/swisseph/doc/swisseph.htm#_Toc58931065).

## Contributing

If you find any innacuracy or bug in this library, or if you find an update that is not yet included in this library, feel free to open an issue or a pull request.

## Known Issues and Caveats

* The included ephe files are available async only
* Due to how the underlying C library operates, you may find that the `error` field returned by some functions will contain random data even if there is no actual error. This can happen when existing memory buffers are recycled therefore the user must always check the returned flag values as per the Swiss Ephemeris documentation.

## Author

Copyright © 2022, VM75
