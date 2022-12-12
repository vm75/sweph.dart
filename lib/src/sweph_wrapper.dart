// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

import 'sweph_bindings_generated.dart' as sweph;
import 'constants.dart';
import 'native_utils.dart';
import 'utils.dart';

// ----------------------
// Various return objects
// ----------------------

/// Ecliptic or Equatorial coordinates
class Coordinates {
  final double longitude;
  final double latitude;
  final double distance;
  Coordinates(this.longitude, this.latitude, this.distance);
  Pointer<Double> toNativeArray(Arena arena) {
    final array = arena<Double>(3);
    array[0] = longitude;
    array[1] = latitude;
    array[2] = distance;
    return array;
  }
}

/// Ecliptic or Equatorial coordinates with speed
class CoordinatesWithSpeed {
  final double longitude;
  final double latitude;
  final double distance;
  final double speedInLongitude;
  final double speedInLatitude;
  final double speedInDistance;
  CoordinatesWithSpeed(this.longitude, this.latitude, this.distance,
      this.speedInLongitude, this.speedInLatitude, this.speedInDistance);
  Pointer<Double> toNativeArray(Arena arena) {
    final array = arena<Double>(6);
    array[0] = longitude;
    array[1] = latitude;
    array[2] = distance;
    array[3] = speedInLongitude;
    array[4] = speedInLatitude;
    array[5] = speedInDistance;
    return array;
  }
}

/// Geographic coordinates
class GeoPosition {
  final double longitude;
  final double latitude;
  final double altitude;
  GeoPosition(this.longitude, this.latitude, [this.altitude = 0]);

  Pointer<Double> toNativeArray(Arena arena) {
    final array = arena<Double>(3);
    array[0] = longitude;
    array[1] = latitude;
    array[2] = altitude;
    return array;
  }
}

/// Orbital distance of the body
class OrbitalDistance {
  final double maxDistance;
  final double minDistance;
  final double trueDistance;
  OrbitalDistance(this.maxDistance, this.minDistance, this.trueDistance);
}

/// Components when degrees in centiseconds are split into sign/nakshatra, degrees, minutes, seconds of arc
class DegreeSplitData {
  final int degrees;
  final int minutes;
  final int seconds;
  final double secondsOfArc;
  final int sign;
  DegreeSplitData(
      this.degrees, this.minutes, this.seconds, this.secondsOfArc, this.sign);
}

/// House cusp abs asmc data with optional speed components
class HouseCuspData {
  final List<double> cusps;
  final List<double> ascmc;
  final List<double>? cuspsSpeed;
  final List<double>? ascmcSpeed;
  HouseCuspData(this.cusps, this.ascmc, [this.cuspsSpeed, this.ascmcSpeed]);
}

/// House coordinates
class HousePosition {
  final double longitude;
  final double latitude;
  final double position;
  HousePosition(this.longitude, this.latitude, this.position);
}

/// Information about crossing of heavenly body
class CrossingInfo {
  final double longitude;
  final double latitude;
  final double timeOfCrossing;
  CrossingInfo(this.longitude, this.latitude, this.timeOfCrossing);
}

/// Atmospheric conditions data
///  data[0]: atmospheric pressure in mbar (hPa) ;
///  data[1]: atmospheric temperature in degrees Celsius;
///  data[2]: relative humidity in %;
///  data[3]: if data[3]>=1, then it is Meteorological Range [km] ;
///   if 1>data[3]>0, then it is the total atmospheric coefficient (ktot) ;
///  data[3]=0, then the other atmospheric parameters determine the total atmospheric coefficient (ktot)
class AtmosphericConditions {
  final List<double> data;
  AtmosphericConditions(this.data) {
    assert(data.length >= 4);
  }
  Pointer<Double> toNativeArray(Arena arena) {
    return data.toNativeArray(arena);
  }
}

/// Observer data
/// Details for data[] (array of six doubles):
///  data[0]: age of observer in years (default = 36)
///  data[1]: Snellen ratio of observers eyes (default = 1 = normal)
/// The following parameters are only relevant if the flag SE_HELFLAG_OPTICAL_PARAMS is set:
///  data[2]: 0 = monocular, 1 = binocular (actually a boolean)
///  data[3]: telescope magnification: 0 = default to naked eye (binocular), 1 = naked eye
///  data[4]: optical aperture (telescope diameter) in mm
///  data[5]: optical transmission
class ObserverConditions {
  final List<double> data;
  ObserverConditions(this.data) {
    assert(data.length >= 6);
  }
  Pointer<Double> toNativeArray(Arena arena) {
    return data.toNativeArray(arena);
  }
}

/// Nodes and apsides data with the following:
///  List of 6 double for ascending node
///  List of 6 double for descending node
///  List of 6 double for perihelion
///  List of 6 double for aphelion
class NodesAndAspides {
  final List<double> nodesAscending;
  final List<double> nodesDescending;
  final List<double> perihelion;
  final List<double> aphelion;
  NodesAndAspides(this.nodesAscending, this.nodesDescending, this.perihelion,
      this.aphelion);
}

/// Eclipse information with the following:
///  List if eclipse times (refer to docs for details)
///  List of attributes (refer to docs for details)
///  Geographic position of eclipse
class EclipseInfo {
  final List<double>? times;
  final List<double>? attributes;
  final GeoPosition? geoPosition;
  EclipseInfo({this.times, this.attributes, this.geoPosition});
}

/// Details of loaded Ephemeris file
class FileData {
  final String path;
  final double startTime;
  final double endTime;
  final int jplEphemerisNumber;
  FileData(this.path, this.startTime, this.endTime, this.jplEphemerisNumber);
}

/// Star name and coordinates
class StarInfo {
  String name;
  CoordinatesWithSpeed coordinates;
  StarInfo(this.name, this.coordinates);
}

/// Azimuth and altitude info
class AzimuthAltitudeInfo {
  final double azimuth;
  final double trueAltitude;
  final double apparentAltitude;
  AzimuthAltitudeInfo(this.azimuth, this.trueAltitude, this.apparentAltitude);
}

typedef Centisec = int;

/// Wrapper class for Sweph native binding, providing easy input/output
class Sweph {
  static const String _libName = 'sweph';
  static final Sweph _instance = Sweph._();
  static final folderSeparator = Platform.isWindows ? ";" : ":";

  /// The dynamic library in which the symbols for [SwephBindings] can be found.
  late final DynamicLibrary _dylib = () {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$_libName.framework/$_libName');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$_libName.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('$_libName.dll');
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }();

  /// The bindings to the native functions in [_dylib].
  late final sweph.SwephBindings _bindings = sweph.SwephBindings(_dylib);
  late final Future<String> defaultEpheFilesPath = _initDefaultEpheFiles();

  /// Private constructor
  Sweph._();

  // Returns the static instance
  factory Sweph() {
    return _instance;
  }

  /// Extracts packaged default ephe files and sets them for use
  /// returns the default folder
  Future<String> useDefaultEpheFiles() async {
    final libEphePath = await defaultEpheFilesPath;
    swe_set_ephe_path(libEphePath);
    return libEphePath;
  }

  Future<String> _initDefaultEpheFiles() async {
    const srcPath = 'packages/$_libName/native/sweph/src'; // asset path

    final filesToExtract = {
      'ast_list.txt': 'seasnam.txt',
      'sefstars.txt': 'sefstars.txt',
      'seleapsec.txt': 'seleapsec.txt',
    };

    final appDataDir = await getApplicationSupportDirectory();
    final libEphePath = '${appDataDir.path}/$_libName/${swe_version()}';

    for (final entry in filesToExtract.entries) {
      final dst = '$libEphePath/${entry.value}';
      if (!File(dst).existsSync()) {
        await ResourceUtils.extractAssets('$srcPath/${entry.key}', dst);
      }
    }

    return libEphePath;
  }

  static DateTime _toDateTime(
      int year, int month, int day, int hour, int minute, double seconds) {
    int second = seconds.floor();
    seconds = (seconds - second) * 1000;
    int milliSecond = seconds.floor();
    seconds = (seconds - milliSecond) * 1000;
    int microSecond = seconds.floor();

    return DateTime.utc(
        year, month, day, hour, minute, second, milliSecond, microSecond);
  }

  static DateTime _toDateTime2(int year, int month, int day, double hours) {
    int hour = hours.floor();
    hours = (hours - hour) * 60;
    int minute = hours.floor();
    hours = (hours - minute) * 60;
    int second = hours.floor();
    hours = (hours - second) * 1000;
    int milliSecond = hours.floor();
    hours = (hours - milliSecond) * 1000;
    int microSecond = hours.floor();

    return DateTime.utc(
        year, month, day, hour, minute, second, milliSecond, microSecond);
  }

  // -----------------------------------------------------------------------------------------
  // Summary of SWISSEPH functions (https://www.astro.com/swisseph/swephprg.htm#_Toc78973625)
  // -----------------------------------------------------------------------------------------

  // -----------------------------------------------------------------
  // Calculation of planets and stars
  // Planets, moon, asteroids, lunar nodes, apogees, fictitious bodies
  // -----------------------------------------------------------------

  /// planetary positions from UT
  CoordinatesWithSpeed swe_calc_ut(
      double julianDay, HeavenlyBody planet, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_calc_ut(
          julianDay, planet.value, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
          coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
    });
  }

  /// planetary positions from TT
  CoordinatesWithSpeed swe_calc(
      double julianDay, HeavenlyBody planet, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_calc(
          julianDay, planet.value, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
          coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
    });
  }

  /// planetary positions, planetocentric, from TT
  CoordinatesWithSpeed swe_calc_pctr(double julianDay, HeavenlyBody target,
      HeavenlyBody center, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_calc_pctr(
          julianDay, target.value, center.value, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
          coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
    });
  }

  /// positions of planetary nodes and aspides from UT
  NodesAndAspides swe_nod_aps_ut(
      double tjd_ut, HeavenlyBody target, SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> nodesAsc = arena<Double>(6);
      Pointer<Double> nodesDesc = arena<Double>(6);
      Pointer<Double> perihelion = arena<Double>(6);
      Pointer<Double> aphelion = arena<Double>(6);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_nod_aps_ut(tjd_ut, target.value, flags.value,
          method.value, nodesAsc, nodesDesc, perihelion, aphelion, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return NodesAndAspides(nodesAsc.toList(6), nodesDesc.toList(6),
          perihelion.toList(6), aphelion.toList(6));
    });
  }

  /// positions of planetary nodes and aspides from TT
  NodesAndAspides swe_nod_aps(
      double tjd_et, HeavenlyBody target, SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> nodesAsc = arena<Double>(6);
      Pointer<Double> nodesDesc = arena<Double>(6);
      Pointer<Double> perihelion = arena<Double>(6);
      Pointer<Double> aphelion = arena<Double>(6);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_nod_aps(tjd_et, target.value, flags.value,
          method.value, nodesAsc, nodesDesc, perihelion, aphelion, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return NodesAndAspides(nodesAsc.toList(6), nodesDesc.toList(6),
          perihelion.toList(6), aphelion.toList(6));
    });
  }

  // -----------
  // Fixed stars
  // -----------

  /// positions of fixed stars from UT, faster function if many stars are calculated
  StarInfo swe_fixstar2_ut(String star, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> cstar = star.toNativeArray(arena, 50);
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result =
          _bindings.swe_fixstar2_ut(cstar, tjd_ut, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
          cstar.toDartString(),
          CoordinatesWithSpeed(coords[0], coords[1], coords[2], coords[3],
              coords[4], coords[5]));
    });
  }

  /// positions of fixed stars from TT, faster function if many stars are calculated
  StarInfo swe_fixstar2(String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> cstar = star.toNativeArray(arena, 50);
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result =
          _bindings.swe_fixstar2(cstar, julianDay, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
          cstar.toDartString(),
          CoordinatesWithSpeed(coords[0], coords[1], coords[2], coords[3],
              coords[4], coords[5]));
    });
  }

  /// positions of fixed stars from UT, faster function if single stars are calculated
  StarInfo swe_fixstar_ut(String star, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> cstar = star.toNativeArray(arena, 50);
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result =
          _bindings.swe_fixstar_ut(cstar, tjd_ut, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
          cstar.toDartString(),
          CoordinatesWithSpeed(coords[0], coords[1], coords[2], coords[3],
              coords[4], coords[5]));
    });
  }

  /// positions of fixed stars from TT, faster function if single stars are calculated
  StarInfo swe_fixstar(String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> cstar = star.toNativeArray(arena, 50);
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> coords = arena<Double>(6);
      final result =
          _bindings.swe_fixstar(cstar, julianDay, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return StarInfo(
          cstar.toDartString(),
          CoordinatesWithSpeed(coords[0], coords[1], coords[2], coords[3],
              coords[4], coords[5]));
    });
  }

  /// get the magnitude of a fixed star
  double swe_fixstar2_mag(String star) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> mag = arena<Double>(6);
      final result =
          _bindings.swe_fixstar2_mag(star.toNativeArray(arena), mag, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return mag.value;
    });
  }

  /// get the magnitude of a fixed star (older method)
  double swe_fixstar_mag(String star) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> mag = arena<Double>(6);
      final result =
          _bindings.swe_fixstar_mag(star.toNativeArray(arena), mag, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return mag.value;
    });
  }

  /// Set the geographic location of observer for topocentric planet computation
  void swe_set_topo(double geolon, double geolat, [double geoalt = 0]) {
    _bindings.swe_set_topo(geolon, geolat, geoalt);
  }

  // ----------------------------------------------
  // Set the sidereal mode and get ayanamsha values
  // ----------------------------------------------

  /// set sidereal mode
  void swe_set_sid_mode(SiderealMode mode,
      [SiderealModeFlag flags = SiderealModeFlag.SE_SIDBIT_NONE,
      t0 = 0,
      ayan_t0 = 0]) {
    _bindings.swe_set_sid_mode((mode.value | flags.value), t0, ayan_t0);
  }

  /// get ayanamsha for a given date in UT.
  double swe_get_ayanamsa_ex_ut(double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> ayanamsa = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_get_ayanamsa_ex_ut(
          tjd_ut, flags.value, ayanamsa, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return ayanamsa.value;
    });
  }

  /// get ayanamsha for a given date in ET/TT
  double swe_get_ayanamsa_ex(double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> ayanamsa = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result =
          _bindings.swe_get_ayanamsa_ex(tjd_et, flags.value, ayanamsa, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return ayanamsa.value;
    });
  }

  /// get ayanamsha for a date in UT, old function, better use swe_get_ayanamsa_ex_ut
  double swe_get_ayanamsa_ut(double tjd_ut) {
    return _bindings.swe_get_ayanamsa_ut(tjd_ut);
  }

  /// get ayanamsha for a date in ET/TT, old function, better use swe_get_ayanamsa_ex
  double swe_get_ayanamsa(double tjd_et) {
    return _bindings.swe_get_ayanamsa(tjd_et);
  }

  /// get the name of an ayanamsha
  String swe_get_ayanamsa_name(SiderealMode mode,
      [SiderealModeFlag flags = SiderealModeFlag.SE_SIDBIT_NONE]) {
    return _bindings
        .swe_get_ayanamsa_name(mode.value | flags.value)
        .toDartString();
  }

  // --------------------------------
  // Eclipses and planetary phenomena
  // --------------------------------

  /// Find the next solar eclipse for a given geographic position
  EclipseInfo swe_sol_eclipse_when_loc(
      double tjd_start, SwephFlag flags, GeoPosition geopos, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attr = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_sol_eclipse_when_loc(tjd_start, flags.value,
          geopos.toNativeArray(arena), times, attr, backward.value, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        times: times.toList(10),
        attributes: attr.toList(20),
      );
    });
  }

  /// Find the next solar eclipse globally
  EclipseInfo swe_sol_eclipse_when_glob(
      double tjd_start, SwephFlag flags, EclipseFlag eclType, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_sol_eclipse_when_glob(
          tjd_start, flags.value, eclType.value, times, backward.value, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        times: times.toList(10),
      );
    });
  }

  /// Compute the attributes of a solar eclipse for a given julianDay, geographic long., latit. and height
  EclipseInfo swe_sol_eclipse_how(
      double julianDay, SwephFlag flags, GeoPosition geopos) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_sol_eclipse_how(julianDay, flags.value,
          geopos.toNativeArray(arena), attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
      );
    });
  }

  /// computes geographic location and attributes of solar eclipse at a given julianDay
  EclipseInfo swe_sol_eclipse_where(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> geopos = arena<Double>(2);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_sol_eclipse_where(
          julianDay, flags.value, geopos, attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        attributes: attributes.toList(20),
        geoPosition: GeoPosition(geopos[0], geopos[1]),
      );
    });
  }

  /// computes geographic location and attributes of lunar eclipse at a given julianDay
  EclipseInfo swe_lun_occult_where(
      double julianDay, HeavenlyBody target, String starname, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> geopos = arena<Double>(2);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_lun_occult_where(
          julianDay,
          target.value,
          starname.toNativeArray(arena),
          flags.value,
          geopos,
          attributes,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
        geoPosition: GeoPosition(geopos[0], geopos[1]),
      );
    });
  }

  /// Find the next occultation of a body by the moon for a given geographic position
  /// (can also be used for solar eclipses)
  EclipseInfo swe_lun_occult_when_loc(double tjd_start, HeavenlyBody target,
      String starname, SwephFlag flags, GeoPosition geopos, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_lun_occult_when_loc(
          tjd_start,
          target.value,
          starname.toNativeArray(arena),
          flags.value,
          geopos.toNativeArray(arena),
          times,
          attributes,
          backward.value,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
        attributes: attributes.toList(20),
      );
    });
  }

  /// Find the next occultation globally
  EclipseInfo swe_lun_occult_when_glob(double tjd_start, HeavenlyBody target,
      String starname, SwephFlag flags, EclipseFlag eclType, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_lun_occult_when_glob(
          tjd_start,
          target.value,
          starname.toNativeArray(arena),
          flags.value,
          eclType.value,
          times,
          backward.value,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
      );
    });
  }

  /// Find the next lunar eclipse observable from a geographic location
  EclipseInfo swe_lun_eclipse_when_loc(
      double tjd_start, SwephFlag flags, GeoPosition geopos, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_lun_eclipse_when_loc(
          tjd_start,
          flags.value,
          geopos.toNativeArray(arena),
          times,
          attributes,
          backward.value,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
        attributes: attributes.toList(20),
      );
    });
  }

  /// Find the next lunar eclipse, global function
  EclipseInfo swe_lun_eclipse_when(
      double tjd_start, SwephFlag flags, EclipseFlag eclType, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_lun_eclipse_when(
          tjd_start, flags.value, eclType.value, times, backward.value, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
      );
    });
  }

  /// Compute the attributes of a lunar eclipse at a given time
  EclipseInfo swe_lun_eclipse_how(
      double tjd_ut, SwephFlag flags, GeoPosition geopos) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_lun_eclipse_how(
          tjd_ut, flags.value, geopos.toNativeArray(arena), attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
      );
    });
  }

  /// Compute risings, settings and meridian transits of a body
  double swe_rise_trans(
      double tjd_ut,
      HeavenlyBody target,
      String starname,
      SwephFlag epheflag,
      RiseSetTransitFlag rsmi,
      GeoPosition geopos,
      double atpress,
      double attemp) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_rise_trans(
          tjd_ut,
          target.value,
          starname.toNativeArray(arena),
          epheflag.value,
          rsmi.value,
          geopos.toNativeArray(arena),
          atpress,
          attemp,
          times,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return times.value;
    });
  }

  double swe_rise_trans_true_hor(
      double tjd_ut,
      HeavenlyBody target,
      String starname,
      SwephFlag epheflag,
      RiseSetTransitFlag rsmi,
      GeoPosition geopos,
      double atpress,
      double attemp,
      double horhgt) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_rise_trans_true_hor(
          tjd_ut,
          target.value,
          starname.toNativeArray(arena),
          epheflag.value,
          rsmi.value,
          geopos.toNativeArray(arena),
          atpress,
          attemp,
          horhgt,
          times,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return times.value;
    });
  }

  /// Compute heliacal risings and settings and related phenomena
  List<double> swe_heliacal_ut(
      double tjdstart_ut,
      GeoPosition geopos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalEventType TypeEvent,
      HeliacalFlags helflag) {
    return using((Arena arena) {
      Arena arena = Arena();
      Pointer<Double> values = arena<Double>(50);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_heliacal_ut(
          tjdstart_ut,
          geopos.toNativeArray(arena),
          atm.toNativeArray(arena),
          obs.toNativeArray(arena),
          name.toNativeArray(arena),
          TypeEvent.value,
          helflag.value,
          values,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(50);
    });
  }

  List<double> swe_heliacal_pheno_ut(
      double tjdstart_ut,
      GeoPosition geopos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalEventType TypeEvent,
      HeliacalFlags helflag) {
    return using((Arena arena) {
      Arena arena = Arena();
      Pointer<Double> values = arena<Double>(50);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_heliacal_pheno_ut(
          tjdstart_ut,
          geopos.toNativeArray(arena),
          atm.toNativeArray(arena),
          obs.toNativeArray(arena),
          name.toNativeArray(arena),
          TypeEvent.value,
          helflag.value,
          values,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(50);
    });
  }

  List<double> swe_vis_limit_mag(
      double tjdstart_ut,
      GeoPosition geopos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalFlags helflag) {
    return using((Arena arena) {
      Arena arena = Arena();
      Pointer<Double> values = arena<Double>(8);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_vis_limit_mag(
          tjdstart_ut,
          geopos.toNativeArray(arena),
          atm.toNativeArray(arena),
          obs.toNativeArray(arena),
          name.toNativeArray(arena),
          helflag.value,
          values,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(8);
    });
  }

  /// Compute planetary phenomena
  List<double> swe_pheno_ut(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_pheno_ut(
          julianDay, target.value, flags.value, attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return attributes.toList(20);
    });
  }

  List<double> swe_pheno(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_pheno(
          julianDay, target.value, flags.value, attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return attributes.toList(20);
    });
  }

  /// Compute azimuth/altitude from ecliptic or equator
  AzimuthAltitudeInfo swe_azalt(double tjd_ut, AzAltMode calc_flag,
      GeoPosition geopos, double atpress, double attemp, Coordinates coord) {
    return using((Arena arena) {
      Pointer<Double> azAlt = arena<Double>(3);
      _bindings.swe_azalt(tjd_ut, calc_flag.value, geopos.toNativeArray(arena),
          atpress, attemp, coord.toNativeArray(arena), azAlt);
      return AzimuthAltitudeInfo(azAlt[0], azAlt[1], azAlt[2]);
    });
  }

  /// Compute ecliptic or equatorial positions from azimuth/altitude
  Coordinates swe_azalt_rev(double tjd_ut, AzAltMode calc_flag,
      GeoPosition geopos, double azimuth, double trueAltitude) {
    return using((Arena arena) {
      Pointer<Double> azAlt = arena<Double>(2);
      Pointer<Double> coord = arena<Double>(2);
      azAlt[0] = azimuth;
      azAlt[1] = trueAltitude;
      _bindings.swe_azalt_rev(
          tjd_ut, calc_flag.value, geopos.toNativeArray(arena), azAlt, coord);
      return Coordinates(coord[0], coord[1], 0);
    });
  }

  /// Compute refracted altitude from true altitude or reverse
  double swe_refrac(double altOfObject, double atmPressure, double atmTemp,
      RefractionMode refracMode) {
    return _bindings.swe_refrac(
        altOfObject, atmPressure, atmTemp, refracMode.value);
  }

  List<double> swe_refrac_extended(
      double altOfObject,
      double AltOfObserver,
      double atmPressure,
      double atmTemp,
      double lapseRate,
      RefractionMode refracMode) {
    return using((Arena arena) {
      Pointer<Double> values = arena<Double>(4);
      _bindings.swe_refrac_extended(altOfObject, AltOfObserver, atmPressure,
          atmTemp, lapseRate, refracMode.value, values);
      return values.toList(20);
    });
  }

  void swe_set_lapse_rate(double lapseRate) {
    _bindings.swe_set_lapse_rate(lapseRate);
  }

  /// Compute Kepler orbital elements of a planet or asteroid
  List<double> swe_get_orbital_elements(
      double tjd_et, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> dret = arena<Double>(50);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_get_orbital_elements(
          tjd_et, target.value, flags.value, dret, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return dret.toList(50);
    });
  }

  /// Compute maximum/minimum/current distance of a planet or asteroid
  OrbitalDistance swe_orbit_max_min_true_distance(
      double tjd_et, HeavenlyBody target, SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> dmax = arena<Double>();
      Pointer<Double> dmin = arena<Double>();
      Pointer<Double> dtrue = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_orbit_max_min_true_distance(
          tjd_et, target.value, flags.value, dmax, dmin, dtrue, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return OrbitalDistance(dmax.value, dmin.value, dtrue.value);
    });
  }

  /// Date and time conversion
  /// Delta T from Julian day number
  double swe_deltat_ex(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      double delta = _bindings.swe_deltat_ex(julianDay, flags.value, error);
      return delta;
    });
  }

  double swe_deltat(double julianDay) {
    return _bindings.swe_deltat(julianDay);
  }

  /// set a user defined delta t to be returned by functions swe_deltat() and swe_deltat_ex()
  void swe_set_delta_t_userdef(double dt) {
    _bindings.swe_set_delta_t_userdef(dt);
  }

  /// Julian day number from year, month, day, hour, with check whether date is legal
  double swe_date_conversion(
      int year, int month, int day, double hours, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Double> julianDay = arena<Double>();
      final result = _bindings.swe_date_conversion(
          year,
          month,
          day,
          hours,
          (calType == CalendarType.SE_GREG_CAL ? 'g' : 'j').firstChar(),
          julianDay);
      if (result < 0) {
        throw Exception("swe_date_conversion failed");
      }
      return julianDay.value;
    });
  }

  /// Julian day number from year, month, day, hour
  double swe_julday(
      int year, int month, int day, double hours, CalendarType calType) {
    return _bindings.swe_julday(year, month, day, hours, calType.value);
  }

  /// Year, month, day, hour from Julian day number
  DateTime swe_revjul(double julianDay, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Int> year = arena<Int>();
      Pointer<Int> month = arena<Int>();
      Pointer<Int> day = arena<Int>();
      Pointer<Double> hours = arena<Double>();
      _bindings.swe_revjul(julianDay, calType.value, year, month, day, hours);
      return _toDateTime2(year.value, month.value, day.value, hours.value);
    });
  }

  /// Local time to UTC and UTC to local time
  DateTime swe_utc_time_zone(int year, int month, int day, int hour, int minute,
      double seconds, double timezone) {
    return using((Arena arena) {
      Pointer<Int> yearOut = arena<Int>();
      Pointer<Int> monthOut = arena<Int>();
      Pointer<Int> dayOut = arena<Int>();
      Pointer<Int> hourOut = arena<Int>();
      Pointer<Int> minuteOut = arena<Int>();
      Pointer<Double> secondsOut = arena<Double>();
      _bindings.swe_utc_time_zone(year, month, day, hour, minute, seconds,
          timezone, yearOut, monthOut, dayOut, hourOut, minuteOut, secondsOut);
      return _toDateTime(yearOut.value, monthOut.value, dayOut.value,
          hourOut.value, minuteOut.value, secondsOut.value);
    });
  }

  /// UTC to julianDay (TT and UT1)
  double swe_utc_to_jd(int year, int month, int day, int hour, int min,
      double sec, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Double> julianDay = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_utc_to_jd(
          year, month, day, hour, min, sec, calType.value, julianDay, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDay.value;
    });
  }

  /// TT (ET1) to UTC
  DateTime swe_jdet_to_utc(double tjd_et, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Int> year = arena<Int>();
      Pointer<Int> mon = arena<Int>();
      Pointer<Int> day = arena<Int>();
      Pointer<Int> hour = arena<Int>();
      Pointer<Int> min = arena<Int>();
      Pointer<Double> sec = arena<Double>();
      _bindings.swe_jdet_to_utc(
          tjd_et, calType.value, year, mon, day, hour, min, sec);
      return _toDateTime(
          year.value, mon.value, day.value, hour.value, min.value, sec.value);
    });
  }

  /// UTC to TT (ET1)
  DateTime swe_jdut1_to_utc(double tjd_ut, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Int> year = arena<Int>();
      Pointer<Int> mon = arena<Int>();
      Pointer<Int> day = arena<Int>();
      Pointer<Int> hour = arena<Int>();
      Pointer<Int> min = arena<Int>();
      Pointer<Double> sec = arena<Double>();
      _bindings.swe_jdut1_to_utc(
          tjd_ut, calType.value, year, mon, day, hour, min, sec);
      return _toDateTime(
          year.value, mon.value, day.value, hour.value, min.value, sec.value);
    });
  }

  /// Get tidal acceleration used in swe_deltat()
  double swe_get_tid_acc() {
    return _bindings.swe_get_tid_acc();
  }

  /// Set tidal acceleration to be used in swe_deltat()
  void swe_set_tid_acc(double tidalAcceleration) {
    _bindings.swe_set_tid_acc(tidalAcceleration);
  }

  // ----------------
  // Equation of time
  // ----------------

  /// function returns the difference between local apparent and local mean time. e = LAT – LMT. tjd_et is ephemeris time
  double swe_time_equ(double julianDay) {
    return using((Arena arena) {
      Pointer<Double> timeDiff = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_time_equ(julianDay, timeDiff, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return timeDiff.value;
    });
  }

  /// converts Local Mean Time (LMT) to Local Apparent Time (LAT)
  double swe_lmt_to_lat(double julianDayLmt, double geolon) {
    return using((Arena arena) {
      Pointer<Double> julianDayLat = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result =
          _bindings.swe_lmt_to_lat(julianDayLmt, geolon, julianDayLat, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayLat.value;
    });
  }

  /// converts Local Apparent Time (LAT) to Local Mean Time (LMT)
  double swe_lat_to_lmt(double julianDayLat, double geolon) {
    return using((Arena arena) {
      Pointer<Double> julianDayLmt = arena<Double>();
      Pointer<Char> error = arena<Char>(256);
      final result =
          _bindings.swe_lat_to_lmt(julianDayLat, geolon, julianDayLmt, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayLmt.value;
    });
  }

  // --------------------------------------------
  // Initialization, setup, and closing functions
  // --------------------------------------------

  /// Set directory path of ephemeris files
  void swe_set_ephe_path(String? ephePaths) {
    ephePaths ??= Platform.isWindows ? '\\sweph\\ephe' : '/users/ephe';
    return using((Arena arena) {
      _bindings.swe_set_ephe_path(ephePaths!.toNativeArray(arena));
    });
  }

  /// set file name of JPL file
  void swe_set_jpl_file(String filePath) {
    return using((Arena arena) {
      _bindings.swe_set_jpl_file(filePath.toNativeArray(arena));
    });
  }

  /// close Swiss Ephemeris
  void swe_close() {
    _bindings.swe_close();
  }

  /// find out version number of your Swiss Ephemeris
  String swe_version() {
    return using((Arena arena) {
      Pointer<Char> buffer = arena<Char>(256);
      _bindings.swe_version(buffer);
      final ver = buffer.toDartString();
      return ver;
    });
  }

  /// find out the library path of the DLL or executable
  String swe_get_library_path() {
    return using((Arena arena) {
      Pointer<Char> buffer = arena<Char>(256);
      _bindings.swe_get_library_path(buffer);
      final path = buffer.toDartString();
      return path;
    });
  }

  /// find out start and end date of *se1 ephemeris file after a call of swe_calc()
  FileData swe_get_current_file_data(int ifno) {
    return using((Arena arena) {
      Pointer<Double> tfstart = arena<Double>();
      Pointer<Double> tfend = arena<Double>();
      Pointer<Int> denum = arena<Int>();

      final path =
          _bindings.swe_get_current_file_data(ifno, tfstart, tfend, denum);
      return FileData(
        path.toDartString(),
        tfstart.value,
        tfend.value,
        denum.value,
      );
    });
  }

  // -----------------
  // House calculation
  // -----------------

  /// Sidereal time
  double swe_sidtime(double tjd_ut) {
    return _bindings.swe_sidtime(tjd_ut);
  }

  double swe_sidtime0(double tjd_ut, double eps, double nut) {
    return _bindings.swe_sidtime0(tjd_ut, eps, nut);
  }

  void swe_set_interpolate_nut(bool do_interpolate) {
    _bindings.swe_set_interpolate_nut(do_interpolate.value);
  }

  /// Get name of a house method
  String swe_house_name(Hsys hsys) {
    return using((Arena arena) {
      final result = _bindings.swe_house_name(hsys.value);
      return result.toDartString();
    });
  }

  /// Get house cusps, ascendant and MC
  HouseCuspData swe_houses(
      double tjd_ut, double geolat, double geolon, Hsys hsys) {
    final cuspsSize = hsys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      _bindings.swe_houses(tjd_ut, geolat, geolon, hsys.value, cusps, ascmc);
      return HouseCuspData(
        cusps.asTypedList(cuspsSize),
        ascmc.asTypedList(10),
      );
    });
  }

  /// compute tropical or sidereal positions
  HouseCuspData swe_houses_ex(
      double tjd_ut, SwephFlag flags, double geolat, double geolon, Hsys hsys) {
    final cuspsSize = hsys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      _bindings.swe_houses_ex(
          tjd_ut, flags.value, geolat, geolon, hsys.value, cusps, ascmc);
      return HouseCuspData(
        cusps.asTypedList(cuspsSize),
        ascmc.asTypedList(10),
      );
    });
  }

  /// compute tropical or sidereal positions with speeds
  HouseCuspData swe_houses_ex2(
      double tjd_ut, SwephFlag flags, double geolat, double geolon, Hsys hsys) {
    final cuspsSize = hsys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      Pointer<Double> cuspsSpeed = arena<Double>(cuspsSize);
      Pointer<Double> ascmcSpeed = arena<Double>(10);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_houses_ex2(tjd_ut, flags.value, geolat,
          geolon, hsys.value, cusps, ascmc, cuspsSpeed, ascmcSpeed, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return HouseCuspData(
        cusps.asTypedList(cuspsSize),
        ascmc.asTypedList(10),
        cuspsSpeed.asTypedList(cuspsSize),
        ascmcSpeed.asTypedList(10),
      );
    });
  }

  /// compute tropical or sidereal positions when a sidereal time [armc] is given but no actual date is known
  HouseCuspData swe_houses_armc(
      double armc, double geolat, double eps, Hsys hsys) {
    final cuspsSize = hsys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      _bindings.swe_houses_armc(armc, geolat, eps, hsys.value, cusps, ascmc);
      return HouseCuspData(
        cusps.asTypedList(cuspsSize),
        ascmc.asTypedList(10),
      );
    });
  }

  /// compute tropical or sidereal positions with speeds when a sidereal time [armc] is given but no actual date is known
  HouseCuspData swe_houses_armc_ex2(
      double armc, double geolat, double eps, Hsys hsys) {
    final cuspsSize = hsys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      Pointer<Double> cuspsSpeed = arena<Double>(cuspsSize);
      Pointer<Double> ascmcSpeed = arena<Double>(10);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_houses_armc_ex2(armc, geolat, eps,
          hsys.value, cusps, ascmc, cuspsSpeed, ascmcSpeed, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return HouseCuspData(
        cusps.asTypedList(cuspsSize),
        ascmc.asTypedList(10),
        cuspsSpeed.asTypedList(cuspsSize),
        ascmcSpeed.asTypedList(10),
      );
    });
  }

  /// Get the house position of a celestial point
  HousePosition swe_house_pos(
      double armc, double geolat, double eps, Hsys hsys) {
    return using((Arena arena) {
      Pointer<Double> position = arena<Double>(2);
      Pointer<Char> error = arena<Char>(256);
      final pos = _bindings.swe_house_pos(
          armc, geolat, eps, hsys.value, position, error);
      if (pos < 0) {
        throw Exception(error.toDartString());
      }
      return HousePosition(position[0], position[1], pos);
    });
  }

  /// Get the Gauquelin sector position for a body
  double swe_gauquelin_sector(
      double t_ut,
      int target,
      String starname,
      SwephFlag flags,
      int imeth,
      GeoPosition geopos,
      double atpress,
      double attemp) {
    return using((Arena arena) {
      Pointer<Double> gsect = arena<Double>(2);
      Pointer<Char> error = arena<Char>(256);
      final result = _bindings.swe_gauquelin_sector(
          t_ut,
          target,
          starname.toNativeArray(arena),
          flags.value,
          imeth,
          geopos.toNativeArray(arena),
          atpress,
          attemp,
          gsect,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return gsect.value;
    });
  }

  // -----------------------------------------------------
  // Functions to find crossings of planets over positions
  // -----------------------------------------------------

  /// find the crossing of the Sun over a given ecliptic position at [tjd_et] in ET
  double swe_solcross(double x2cross, double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      final julianDay =
          _bindings.swe_solcross(x2cross, tjd_et, flags.value, error);
      if (julianDay < tjd_et) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    });
  }

  /// find the crossing of the Sun over a given ecliptic position at [tjd_ut] in UT
  double swe_solcross_ut(double x2cross, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      final julianDay =
          _bindings.swe_solcross_ut(x2cross, tjd_ut, flags.value, error);
      if (julianDay < tjd_ut) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    });
  }

  /// find the crossing of the Moon over a given ecliptic position at [tjd_et] in ET
  double swe_mooncross(double x2cross, double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      final julianDay =
          _bindings.swe_mooncross(x2cross, tjd_et, flags.value, error);
      if (julianDay < tjd_et) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    });
  }

  /// find the crossing of the Moon over a given ecliptic position at [tjd_ut] in UT
  double swe_mooncross_ut(double x2cross, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      final julianDay =
          _bindings.swe_mooncross_ut(x2cross, tjd_ut, flags.value, error);
      if (julianDay < tjd_ut) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    });
  }

  /// find the crossing of the Moon over its true node, i.e. crossing through the ecliptic at [tjd_et] in ET
  CrossingInfo swe_mooncross_node(double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> xlon = arena<Double>();
      Pointer<Double> xlat = arena<Double>();
      final julianDay =
          _bindings.swe_mooncross_node(tjd_et, flags.value, xlon, xlat, error);
      if (julianDay < tjd_et) {
        throw Exception(error.toDartString());
      }
      return CrossingInfo(
        julianDay,
        xlon.value,
        xlat.value,
      );
    });
  }

  /// find the crossing of the Moon over its true node, i.e. crossing through the ecliptic at [tjd_ut] in UT
  CrossingInfo swe_mooncross_node_ut(double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> xlon = arena<Double>();
      Pointer<Double> xlat = arena<Double>();
      final julianDay = _bindings.swe_mooncross_node_ut(
          tjd_ut, flags.value, xlon, xlat, error);
      if (julianDay < tjd_ut) {
        throw Exception(error.toDartString());
      }
      return CrossingInfo(
        julianDay,
        xlon.value,
        xlat.value,
      );
    });
  }

  /// heliocentric crossings over a position [x2cross] at [tjd_et] in ET
  double swe_helio_cross(HeavenlyBody target, double x2cross, double tjd_et,
      SwephFlag flags, int dir) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> julianDay = arena<Double>();
      final result = _bindings.swe_helio_cross(
          target.value, x2cross, tjd_et, flags.value, dir, julianDay, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDay.value;
    });
  }

  /// heliocentric crossings over a position [x2cross] at [tjd_ut] in UT
  double swe_helio_cross_ut(HeavenlyBody target, double x2cross, double tjd_ut,
      SwephFlag flags, int dir) {
    return using((Arena arena) {
      Pointer<Char> error = arena<Char>(256);
      Pointer<Double> julianDay = arena<Double>();
      final result = _bindings.swe_helio_cross_ut(
          target.value, x2cross, tjd_ut, flags.value, dir, julianDay, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDay.value;
    });
  }

  // -------------------
  // Auxiliary functions
  // -------------------

  /// coordinate transformation, from ecliptic to equator or vice-versa
  Coordinates swe_cotrans(Coordinates coordinates, double eps) {
    return using((Arena arena) {
      Pointer<Double> xpn = arena<Double>(3);
      _bindings.swe_cotrans(coordinates.toNativeArray(arena), xpn, eps);
      return Coordinates(xpn[0], xpn[1], xpn[2]);
    });
  }

  /// coordinate transformation of position and speed, from ecliptic to equator or vice-versa
  CoordinatesWithSpeed swe_cotrans_sp(List<double> xpo, double eps) {
    return using((Arena arena) {
      Pointer<Double> xpn = arena<Double>(6);
      _bindings.swe_cotrans_sp(xpo.toNativeArray(arena), xpn, eps);
      return CoordinatesWithSpeed(
          xpn[0], xpn[1], xpn[2], xpn[3], xpn[4], xpn[5]);
    });
  }

  /// get the name of a planet
  String swe_get_planet_name(HeavenlyBody planet) {
    return using((Arena arena) {
      Pointer<Char> buffer = arena<Char>(256);
      _bindings.swe_get_planet_name(planet.value, buffer);
      final name = buffer.toDartString();
      return name;
    });
  }

  /// normalize degrees to the range 0 ... 360
  double swe_degnorm(double degrees) {
    return _bindings.swe_degnorm(degrees);
  }

  /// normalize radians to the range 0 ... 2 PI
  double swe_radnorm(double radians) {
    return _bindings.swe_radnorm(radians);
  }

  /// Radians midpoint
  double swe_rad_midp(double rad1, double rad2) {
    return _bindings.swe_rad_midp(rad1, rad2);
  }

  /// Degrees midpoint
  double swe_deg_midp(double deg1, double deg2) {
    return _bindings.swe_deg_midp(deg1, deg2);
  }

  /// split degrees in centiseconds to sign/nakshatra, degrees, minutes, seconds of arc
  DegreeSplitData swe_split_deg(double deg, SplitDegFlags roundflag) {
    return using((Arena arena) {
      Pointer<Int> splitDeg = arena<Int>();
      Pointer<Int> splitMin = arena<Int>();
      Pointer<Int> splitSec = arena<Int>();
      Pointer<Double> splitSecOfArc = arena<Double>();
      Pointer<Int> splitSgn = arena<Int>();
      _bindings.swe_split_deg(deg, roundflag.value, splitDeg, splitMin,
          splitSec, splitSecOfArc, splitSgn);
      return DegreeSplitData(splitDeg.value, splitMin.value, splitSec.value,
          splitSecOfArc.value, splitSgn.value);
    });
  }

  // ----------------------------------
  // Other functions that may be useful
  // ----------------------------------

  /// Normalize argument into interval [0..DEG360]
  Centisec swe_csnorm(Centisec deg) {
    return _bindings.swe_csnorm(deg);
  }

  /// Distance in centisecs p1 - p2 normalized to [0..360]
  Centisec swe_difcsn(Centisec p1, Centisec p2) {
    return _bindings.swe_difcsn(p1, p2);
  }

  /// Distance in degrees
  double swe_difdegn(double p1, double p2) {
    return _bindings.swe_difdegn(p1, p2);
  }

  /// Distance in centisecs p1 - p2 normalized to [-180..180]
  Centisec swe_difcs2n(Centisec p1, Centisec p2) {
    return _bindings.swe_difcs2n(p1, p2);
  }

  /// Distance in degrees
  double swe_difdeg2n(double p1, double p2) {
    return _bindings.swe_difdeg2n(p1, p2);
  }

  /// Round second, but at 29.5959 always down
  Centisec swe_csroundsec(Centisec deg) {
    return _bindings.swe_csroundsec(deg);
  }

  /// Double to long with rounding, no overflow check
  int swe_d2l(double x) {
    return _bindings.swe_d2l(x);
  }

  /// Day of week Monday = 0, ... Sunday = 6
  int swe_day_of_week(double julianDay) {
    return _bindings.swe_day_of_week(julianDay);
  }

  /// Centiseconds -> time string
  String swe_cs2timestr(Centisec deg, int sep, bool suppressZero) {
    return using((Arena arena) {
      Pointer<Char> buffer = arena<Char>(10);
      _bindings.swe_cs2timestr(deg, sep, suppressZero.value, buffer);
      return buffer.toDartString();
    });
  }

  /// Centiseconds -> longitude or latitude string
  String swe_cs2lonlatstr(Centisec deg, String pchar, String mchar) {
    return using((Arena arena) {
      Pointer<Char> buffer = arena<Char>(12);
      _bindings.swe_cs2lonlatstr(
          deg, pchar.firstChar(), mchar.firstChar(), buffer);
      return buffer.toDartString();
    });
  }

  /// Centiseconds -> degrees string
  String swe_cs2degstr(Centisec deg) {
    return using((Arena arena) {
      Pointer<Char> buffer = arena<Char>(10);
      _bindings.swe_cs2degstr(deg, buffer);
      return buffer.toDartString();
    });
  }
}
