// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import 'src/bindings.dart';
import 'src/utils.dart';
import 'src/ffi_proxy.dart';
import 'src/types.dart';

export 'src/types.dart';

/// Wrapper class for Sweph native binding, providing easy input/output
class Sweph {
  static const bundledEpheAssets = [
    "packages/sweph/assets/ephe/seas_18.se1",
    "packages/sweph/assets/ephe/semo_18.se1",
    "packages/sweph/assets/ephe/sepl_18.se1",
    "packages/sweph/assets/ephe/seasnam.txt",
    "packages/sweph/assets/ephe/sefstars.txt",
    "packages/sweph/assets/ephe/seleapsec.txt",
    "packages/sweph/assets/ephe/seorbel.txt"
  ];

  /// Platform-specific helpers
  static late AbstractPlatformProvider _provider;

  /// The bindings to the native functions in [_provider].lib.
  static late SwephBindings _bindings;

  /// Memory allocator
  static late Allocator _allocator;

  /// Should be called before any use of Sweph
  static init({List<String>? epheAssets}) async {
    _provider = await SwephPlatformProvider.instance;
    _allocator = _provider.allocator;
    _bindings = SwephBindings(_provider.lib);
    await _provider.saveEpheAssets(epheAssets);
    return using((Arena arena) {
      _bindings
          .swe_set_ephe_path(_provider.epheFilesPath.toNativeString(arena));
    }, _allocator);
  }

  static void registerWith(registrar) {
    // Ignore for Web
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
  static CoordinatesWithSpeed swe_calc_ut(
      double julianDay, HeavenlyBody planet, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_calc_ut(
          julianDay, planet.value, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
          coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
    }, _allocator);
  }

  /// planetary positions from TT
  static CoordinatesWithSpeed swe_calc(
      double julianDay, HeavenlyBody planet, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_calc(
          julianDay, planet.value, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
          coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
    }, _allocator);
  }

  /// planetary positions, planetocentric, from TT
  static CoordinatesWithSpeed swe_calc_pctr(double julianDay,
      HeavenlyBody target, HeavenlyBody center, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> coords = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_calc_pctr(
          julianDay, target.value, center.value, flags.value, coords, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return CoordinatesWithSpeed(
          coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
    }, _allocator);
  }

  /// positions of planetary nodes and aspides from UT
  static NodesAndAspides swe_nod_aps_ut(
      double tjd_ut, HeavenlyBody target, SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> nodesAsc = arena<Double>(6);
      Pointer<Double> nodesDesc = arena<Double>(6);
      Pointer<Double> perihelion = arena<Double>(6);
      Pointer<Double> aphelion = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_nod_aps_ut(tjd_ut, target.value, flags.value,
          method.value, nodesAsc, nodesDesc, perihelion, aphelion, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return NodesAndAspides(nodesAsc.toList(6), nodesDesc.toList(6),
          perihelion.toList(6), aphelion.toList(6));
    }, _allocator);
  }

  /// positions of planetary nodes and aspides from TT
  static NodesAndAspides swe_nod_aps(
      double tjd_et, HeavenlyBody target, SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> nodesAsc = arena<Double>(6);
      Pointer<Double> nodesDesc = arena<Double>(6);
      Pointer<Double> perihelion = arena<Double>(6);
      Pointer<Double> aphelion = arena<Double>(6);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_nod_aps(tjd_et, target.value, flags.value,
          method.value, nodesAsc, nodesDesc, perihelion, aphelion, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return NodesAndAspides(nodesAsc.toList(6), nodesDesc.toList(6),
          perihelion.toList(6), aphelion.toList(6));
    }, _allocator);
  }

  // -----------
  // Fixed stars
  // -----------

  /// positions of fixed stars from UT, faster function if many stars are calculated
  static StarInfo swe_fixstar2_ut(String star, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// positions of fixed stars from TT, faster function if many stars are calculated
  static StarInfo swe_fixstar2(String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// positions of fixed stars from UT, faster function if single stars are calculated
  static StarInfo swe_fixstar_ut(String star, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// positions of fixed stars from TT, faster function if single stars are calculated
  static StarInfo swe_fixstar(String star, double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> cstar = star.toNativeString(arena, 50);
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// get the magnitude of a fixed star
  static double swe_fixstar2_mag(String star) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> mag = arena<Double>(6);
      final result =
          _bindings.swe_fixstar2_mag(star.toNativeString(arena), mag, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return mag.value;
    }, _allocator);
  }

  /// get the magnitude of a fixed star (older method)
  static double swe_fixstar_mag(String star) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> mag = arena<Double>(6);
      final result =
          _bindings.swe_fixstar_mag(star.toNativeString(arena), mag, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return mag.value;
    }, _allocator);
  }

  /// Set the geographic location of observer for topocentric planet computation
  static void swe_set_topo(double geolon, double geolat, [double geoalt = 0]) {
    _bindings.swe_set_topo(geolon, geolat, geoalt);
  }

  // ----------------------------------------------
  // Set the sidereal mode and get ayanamsha values
  // ----------------------------------------------

  /// set sidereal mode
  static void swe_set_sid_mode(SiderealMode mode,
      [SiderealModeFlag flags = SiderealModeFlag.SE_SIDBIT_NONE,
      double t0 = 0,
      double ayan_t0 = 0]) {
    _bindings.swe_set_sid_mode((mode.value | flags.value), t0, ayan_t0);
  }

  /// get ayanamsha for a given date in UT.
  static double swe_get_ayanamsa_ex_ut(double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> ayanamsa = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_get_ayanamsa_ex_ut(
          tjd_ut, flags.value, ayanamsa, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return ayanamsa.value;
    }, _allocator);
  }

  /// get ayanamsha for a given date in ET/TT
  static double swe_get_ayanamsa_ex(double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> ayanamsa = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result =
          _bindings.swe_get_ayanamsa_ex(tjd_et, flags.value, ayanamsa, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return ayanamsa.value;
    }, _allocator);
  }

  /// get ayanamsha for a date in UT, old function, better use swe_get_ayanamsa_ex_ut
  static double swe_get_ayanamsa_ut(double tjd_ut) {
    return _bindings.swe_get_ayanamsa_ut(tjd_ut);
  }

  /// get ayanamsha for a date in ET/TT, old function, better use swe_get_ayanamsa_ex
  static double swe_get_ayanamsa(double tjd_et) {
    return _bindings.swe_get_ayanamsa(tjd_et);
  }

  /// get the name of an ayanamsha
  static String swe_get_ayanamsa_name(SiderealMode mode,
      [SiderealModeFlag flags = SiderealModeFlag.SE_SIDBIT_NONE]) {
    return _bindings
        .swe_get_ayanamsa_name(mode.value | flags.value)
        .toDartString();
  }

  // --------------------------------
  // Eclipses and planetary phenomena
  // --------------------------------

  /// Find the next solar eclipse for a given geographic position
  static EclipseInfo swe_sol_eclipse_when_loc(
      double tjd_start, SwephFlag flags, GeoPosition geopos, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attr = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_when_loc(tjd_start, flags.value,
          geopos.toNativeString(arena), times, attr, backward.value, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        times: times.toList(10),
        attributes: attr.toList(20),
      );
    }, _allocator);
  }

  /// Find the next solar eclipse globally
  static EclipseInfo swe_sol_eclipse_when_glob(
      double tjd_start, SwephFlag flags, EclipseFlag eclType, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_when_glob(
          tjd_start, flags.value, eclType.value, times, backward.value, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        times: times.toList(10),
      );
    }, _allocator);
  }

  /// Compute the attributes of a solar eclipse for a given julianDay, geographic long., latit. and height
  static EclipseInfo swe_sol_eclipse_how(
      double julianDay, SwephFlag flags, GeoPosition geopos) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_how(julianDay, flags.value,
          geopos.toNativeString(arena), attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
      );
    }, _allocator);
  }

  /// computes geographic location and attributes of solar eclipse at a given julianDay
  static EclipseInfo swe_sol_eclipse_where(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> geopos = arena<Double>(2);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_sol_eclipse_where(
          julianDay, flags.value, geopos, attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return EclipseInfo(
        attributes: attributes.toList(20),
        geoPosition: GeoPosition(geopos[0], geopos[1]),
      );
    }, _allocator);
  }

  /// computes geographic location and attributes of lunar eclipse at a given julianDay
  static EclipseInfo swe_lun_occult_where(
      double julianDay, HeavenlyBody target, String starname, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> geopos = arena<Double>(2);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_occult_where(
          julianDay,
          target.value,
          starname.toNativeString(arena),
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
    }, _allocator);
  }

  /// Find the next occultation of a body by the moon for a given geographic position
  /// (can also be used for solar eclipses)
  static EclipseInfo swe_lun_occult_when_loc(
      double tjd_start,
      HeavenlyBody target,
      String starname,
      SwephFlag flags,
      GeoPosition geopos,
      bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_occult_when_loc(
          tjd_start,
          target.value,
          starname.toNativeString(arena),
          flags.value,
          geopos.toNativeString(arena),
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
    }, _allocator);
  }

  /// Find the next occultation globally
  static EclipseInfo swe_lun_occult_when_glob(
      double tjd_start,
      HeavenlyBody target,
      String starname,
      SwephFlag flags,
      EclipseFlag eclType,
      bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_occult_when_glob(
          tjd_start,
          target.value,
          starname.toNativeString(arena),
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
    }, _allocator);
  }

  /// Find the next lunar eclipse observable from a geographic location
  static EclipseInfo swe_lun_eclipse_when_loc(
      double tjd_start, SwephFlag flags, GeoPosition geopos, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_eclipse_when_loc(
          tjd_start,
          flags.value,
          geopos.toNativeString(arena),
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
    }, _allocator);
  }

  /// Find the next lunar eclipse, global function
  static EclipseInfo swe_lun_eclipse_when(
      double tjd_start, SwephFlag flags, EclipseFlag eclType, bool backward) {
    return using((Arena arena) {
      Pointer<Double> times = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_eclipse_when(
          tjd_start, flags.value, eclType.value, times, backward.value, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        times: times.toList(10),
      );
    }, _allocator);
  }

  /// Compute the attributes of a lunar eclipse at a given time
  static EclipseInfo swe_lun_eclipse_how(
      double tjd_ut, SwephFlag flags, GeoPosition geopos) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_lun_eclipse_how(
          tjd_ut, flags.value, geopos.toNativeString(arena), attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return EclipseInfo(
        attributes: attributes.toList(20),
      );
    }, _allocator);
  }

  /// Compute risings, settings and meridian transits of a body
  static double swe_rise_trans(
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
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_rise_trans(
          tjd_ut,
          target.value,
          starname.toNativeString(arena),
          epheflag.value,
          rsmi.value,
          geopos.toNativeString(arena),
          atpress,
          attemp,
          times,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return times.value;
    }, _allocator);
  }

  static double swe_rise_trans_true_hor(
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
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_rise_trans_true_hor(
          tjd_ut,
          target.value,
          starname.toNativeString(arena),
          epheflag.value,
          rsmi.value,
          geopos.toNativeString(arena),
          atpress,
          attemp,
          horhgt,
          times,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return times.value;
    }, _allocator);
  }

  /// Compute heliacal risings and settings and related phenomena
  static List<double> swe_heliacal_ut(
      double tjdstart_ut,
      GeoPosition geopos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalEventType TypeEvent,
      HeliacalFlags helflag) {
    return using((Arena arena) {
      Arena arena = Arena(_allocator);
      Pointer<Double> values = arena<Double>(50);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_heliacal_ut(
          tjdstart_ut,
          geopos.toNativeString(arena),
          atm.toNativeString(arena),
          obs.toNativeString(arena),
          name.toNativeString(arena),
          TypeEvent.value,
          helflag.value,
          values,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(50);
    }, _allocator);
  }

  static List<double> swe_heliacal_pheno_ut(
      double tjdstart_ut,
      GeoPosition geopos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalEventType TypeEvent,
      HeliacalFlags helflag) {
    return using((Arena arena) {
      Arena arena = Arena(_allocator);
      Pointer<Double> values = arena<Double>(50);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_heliacal_pheno_ut(
          tjdstart_ut,
          geopos.toNativeString(arena),
          atm.toNativeString(arena),
          obs.toNativeString(arena),
          name.toNativeString(arena),
          TypeEvent.value,
          helflag.value,
          values,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(50);
    }, _allocator);
  }

  static List<double> swe_vis_limit_mag(
      double tjdstart_ut,
      GeoPosition geopos,
      AtmosphericConditions atm,
      ObserverConditions obs,
      String name,
      HeliacalFlags helflag) {
    return using((Arena arena) {
      Arena arena = Arena(_allocator);
      Pointer<Double> values = arena<Double>(8);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_vis_limit_mag(
          tjdstart_ut,
          geopos.toNativeString(arena),
          atm.toNativeString(arena),
          obs.toNativeString(arena),
          name.toNativeString(arena),
          helflag.value,
          values,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return values.toList(8);
    }, _allocator);
  }

  /// Compute planetary phenomena
  static List<double> swe_pheno_ut(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_pheno_ut(
          julianDay, target.value, flags.value, attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return attributes.toList(20);
    }, _allocator);
  }

  static List<double> swe_pheno(
      double julianDay, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> attributes = arena<Double>(20);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_pheno(
          julianDay, target.value, flags.value, attributes, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return attributes.toList(20);
    }, _allocator);
  }

  /// Compute azimuth/altitude from ecliptic or equator
  static AzimuthAltitudeInfo swe_azalt(double tjd_ut, AzAltMode calc_flag,
      GeoPosition geopos, double atpress, double attemp, Coordinates coord) {
    return using((Arena arena) {
      Pointer<Double> azAlt = arena<Double>(3);
      _bindings.swe_azalt(tjd_ut, calc_flag.value, geopos.toNativeString(arena),
          atpress, attemp, coord.toNativeString(arena), azAlt);
      return AzimuthAltitudeInfo(azAlt[0], azAlt[1], azAlt[2]);
    }, _allocator);
  }

  /// Compute ecliptic or equatorial positions from azimuth/altitude
  static Coordinates swe_azalt_rev(double tjd_ut, AzAltMode calc_flag,
      GeoPosition geopos, double azimuth, double trueAltitude) {
    return using((Arena arena) {
      Pointer<Double> azAlt = arena<Double>(2);
      Pointer<Double> coord = arena<Double>(2);
      azAlt[0] = azimuth;
      azAlt[1] = trueAltitude;
      _bindings.swe_azalt_rev(
          tjd_ut, calc_flag.value, geopos.toNativeString(arena), azAlt, coord);
      return Coordinates(coord[0], coord[1], 0);
    }, _allocator);
  }

  /// Compute refracted altitude from true altitude or reverse
  static double swe_refrac(double altOfObject, double atmPressure,
      double atmTemp, RefractionMode refracMode) {
    return _bindings.swe_refrac(
        altOfObject, atmPressure, atmTemp, refracMode.value);
  }

  static List<double> swe_refrac_extended(
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
    }, _allocator);
  }

  static void swe_set_lapse_rate(double lapseRate) {
    _bindings.swe_set_lapse_rate(lapseRate);
  }

  /// Compute Kepler orbital elements of a planet or asteroid
  static List<double> swe_get_orbital_elements(
      double tjd_et, HeavenlyBody target, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Double> dret = arena<Double>(50);
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_get_orbital_elements(
          tjd_et, target.value, flags.value, dret, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }

      return dret.toList(50);
    }, _allocator);
  }

  /// Compute maximum/minimum/current distance of a planet or asteroid
  static OrbitalDistance swe_orbit_max_min_true_distance(
      double tjd_et, HeavenlyBody target, SwephFlag flags, NodApsFlag method) {
    return using((Arena arena) {
      Pointer<Double> dmax = arena<Double>();
      Pointer<Double> dmin = arena<Double>();
      Pointer<Double> dtrue = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_orbit_max_min_true_distance(
          tjd_et, target.value, flags.value, dmax, dmin, dtrue, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return OrbitalDistance(dmax.value, dmin.value, dtrue.value);
    }, _allocator);
  }

  /// Date and time conversion
  /// Delta T from Julian day number
  static double swe_deltat_ex(double julianDay, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      double delta = _bindings.swe_deltat_ex(julianDay, flags.value, error);
      return delta;
    }, _allocator);
  }

  static double swe_deltat(double julianDay) {
    return _bindings.swe_deltat(julianDay);
  }

  /// set a user defined delta t to be returned by functions swe_deltat() and swe_deltat_ex()
  static void swe_set_delta_t_userdef(double dt) {
    _bindings.swe_set_delta_t_userdef(dt);
  }

  /// Julian day number from year, month, day, hour, with check whether date is legal
  static double swe_date_conversion(
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
    }, _allocator);
  }

  /// Julian day number from year, month, day, hour
  static double swe_julday(
      int year, int month, int day, double hours, CalendarType calType) {
    return _bindings.swe_julday(year, month, day, hours, calType.value);
  }

  /// Year, month, day, hour from Julian day number
  static DateTime swe_revjul(double julianDay, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Int> year = arena<Int>();
      Pointer<Int> month = arena<Int>();
      Pointer<Int> day = arena<Int>();
      Pointer<Double> hours = arena<Double>();
      _bindings.swe_revjul(julianDay, calType.value, year, month, day, hours);
      return _toDateTime2(year.value, month.value, day.value, hours.value);
    }, _allocator);
  }

  /// Local time to UTC and UTC to local time
  static DateTime swe_utc_time_zone(int year, int month, int day, int hour,
      int minute, double seconds, double timezone) {
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
    }, _allocator);
  }

  /// UTC to julianDay (TT and UT1)
  static double swe_utc_to_jd(int year, int month, int day, int hour, int min,
      double sec, CalendarType calType) {
    return using((Arena arena) {
      Pointer<Double> julianDay = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_utc_to_jd(
          year, month, day, hour, min, sec, calType.value, julianDay, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDay.value;
    }, _allocator);
  }

  /// TT (ET1) to UTC
  static DateTime swe_jdet_to_utc(double tjd_et, CalendarType calType) {
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
    }, _allocator);
  }

  /// UTC to TT (ET1)
  static DateTime swe_jdut1_to_utc(double tjd_ut, CalendarType calType) {
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
    }, _allocator);
  }

  /// Get tidal acceleration used in swe_deltat()
  static double swe_get_tid_acc() {
    return _bindings.swe_get_tid_acc();
  }

  /// Set tidal acceleration to be used in swe_deltat()
  static void swe_set_tid_acc(double tidalAcceleration) {
    _bindings.swe_set_tid_acc(tidalAcceleration);
  }

  // ----------------
  // Equation of time
  // ----------------

  /// function returns the difference between local apparent and local mean time. e = LAT – LMT. tjd_et is ephemeris time
  static double swe_time_equ(double julianDay) {
    return using((Arena arena) {
      Pointer<Double> timeDiff = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_time_equ(julianDay, timeDiff, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return timeDiff.value;
    }, _allocator);
  }

  /// converts Local Mean Time (LMT) to Local Apparent Time (LAT)
  static double swe_lmt_to_lat(double julianDayLmt, double geolon) {
    return using((Arena arena) {
      Pointer<Double> julianDayLat = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result =
          _bindings.swe_lmt_to_lat(julianDayLmt, geolon, julianDayLat, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayLat.value;
    }, _allocator);
  }

  /// converts Local Apparent Time (LAT) to Local Mean Time (LMT)
  static double swe_lat_to_lmt(double julianDayLat, double geolon) {
    return using((Arena arena) {
      Pointer<Double> julianDayLmt = arena<Double>();
      Pointer<Uint8> error = arena<Uint8>(256);
      final result =
          _bindings.swe_lat_to_lmt(julianDayLat, geolon, julianDayLmt, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDayLmt.value;
    }, _allocator);
  }

  // --------------------------------------------
  // Initialization, setup, and closing functions
  // --------------------------------------------

  /// Set directory path of ephemeris files
  static void swe_set_ephe_path(String? epheFilesDir,
      {bool forceOverwrite = false}) {
    if (kIsWeb || epheFilesDir == null) {
      return;
    }
    return using((Arena arena) {
      if (epheFilesDir != _provider.epheFilesPath) {
        _provider.copyEpheDir(epheFilesDir, forceOverwrite);
      }
    }, _allocator);
  }

  /// set file name of JPL file
  static void swe_set_jpl_file(String filePath, {bool forceOverwrite = false}) {
    return using((Arena arena) {
      if (!kIsWeb) {
        _provider.copyEpheFile(filePath, forceOverwrite);
      }
      _bindings.swe_set_jpl_file(basename(filePath).toNativeString(arena));
    }, _allocator);
  }

  /// close Swiss Ephemeris
  static void swe_close() {
    _bindings.swe_close();
  }

  /// find out version number of your Swiss Ephemeris
  static String swe_version() {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(256);
      _bindings.swe_version(buffer);
      final ver = buffer.toDartString();
      return ver;
    }, _allocator);
  }

  /// find out the library path of the DLL or executable
  static String swe_get_library_path() {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(256);
      _bindings.swe_get_library_path(buffer);
      final path = buffer.toDartString();
      return path;
    }, _allocator);
  }

  /// find out start and end date of *se1 ephemeris file after a call of swe_calc()
  static FileData swe_get_current_file_data(int ifno) {
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
    }, _allocator);
  }

  // -----------------
  // House calculation
  // -----------------

  /// Sidereal time
  static double swe_sidtime(double tjd_ut) {
    return _bindings.swe_sidtime(tjd_ut);
  }

  static double swe_sidtime0(double tjd_ut, double eps, double nut) {
    return _bindings.swe_sidtime0(tjd_ut, eps, nut);
  }

  static void swe_set_interpolate_nut(bool do_interpolate) {
    _bindings.swe_set_interpolate_nut(do_interpolate.value);
  }

  /// Get name of a house method
  static String swe_house_name(Hsys hsys) {
    return using((Arena arena) {
      final result = _bindings.swe_house_name(hsys.value);
      return result.toDartString();
    }, _allocator);
  }

  /// Get house cusps, ascendant and MC
  static HouseCuspData swe_houses(
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
    }, _allocator);
  }

  /// compute tropical or sidereal positions
  static HouseCuspData swe_houses_ex(
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
    }, _allocator);
  }

  /// compute tropical or sidereal positions with speeds
  static HouseCuspData swe_houses_ex2(
      double tjd_ut, SwephFlag flags, double geolat, double geolon, Hsys hsys) {
    final cuspsSize = hsys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      Pointer<Double> cuspsSpeed = arena<Double>(cuspsSize);
      Pointer<Double> ascmcSpeed = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// compute tropical or sidereal positions when a sidereal time [armc] is given but no actual date is known
  static HouseCuspData swe_houses_armc(
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
    }, _allocator);
  }

  /// compute tropical or sidereal positions with speeds when a sidereal time [armc] is given but no actual date is known
  static HouseCuspData swe_houses_armc_ex2(
      double armc, double geolat, double eps, Hsys hsys) {
    final cuspsSize = hsys == Hsys.G ? 37 : 13;
    return using((Arena arena) {
      Pointer<Double> cusps = arena<Double>(cuspsSize);
      Pointer<Double> ascmc = arena<Double>(10);
      Pointer<Double> cuspsSpeed = arena<Double>(cuspsSize);
      Pointer<Double> ascmcSpeed = arena<Double>(10);
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// Get the house position of a celestial point
  static HousePosition swe_house_pos(
      double armc, double geolat, double eps, Hsys hsys) {
    return using((Arena arena) {
      Pointer<Double> position = arena<Double>(2);
      Pointer<Uint8> error = arena<Uint8>(256);
      final pos = _bindings.swe_house_pos(
          armc, geolat, eps, hsys.value, position, error);
      if (pos < 0) {
        throw Exception(error.toDartString());
      }
      return HousePosition(position[0], position[1], pos);
    }, _allocator);
  }

  /// Get the Gauquelin sector position for a body
  static double swe_gauquelin_sector(
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
      Pointer<Uint8> error = arena<Uint8>(256);
      final result = _bindings.swe_gauquelin_sector(
          t_ut,
          target,
          starname.toNativeString(arena),
          flags.value,
          imeth,
          geopos.toNativeString(arena),
          atpress,
          attemp,
          gsect,
          error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return gsect.value;
    }, _allocator);
  }

  // -----------------------------------------------------
  // Functions to find crossings of planets over positions
  // -----------------------------------------------------

  /// find the crossing of the Sun over a given ecliptic position at [tjd_et] in ET
  static double swe_solcross(double x2cross, double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDay =
          _bindings.swe_solcross(x2cross, tjd_et, flags.value, error);
      if (julianDay < tjd_et) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    }, _allocator);
  }

  /// find the crossing of the Sun over a given ecliptic position at [tjd_ut] in UT
  static double swe_solcross_ut(
      double x2cross, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDay =
          _bindings.swe_solcross_ut(x2cross, tjd_ut, flags.value, error);
      if (julianDay < tjd_ut) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    }, _allocator);
  }

  /// find the crossing of the Moon over a given ecliptic position at [tjd_et] in ET
  static double swe_mooncross(double x2cross, double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDay =
          _bindings.swe_mooncross(x2cross, tjd_et, flags.value, error);
      if (julianDay < tjd_et) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    }, _allocator);
  }

  /// find the crossing of the Moon over a given ecliptic position at [tjd_ut] in UT
  static double swe_mooncross_ut(
      double x2cross, double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      final julianDay =
          _bindings.swe_mooncross_ut(x2cross, tjd_ut, flags.value, error);
      if (julianDay < tjd_ut) {
        throw Exception(error.toDartString());
      }
      return julianDay;
    }, _allocator);
  }

  /// find the crossing of the Moon over its true node, i.e. crossing through the ecliptic at [tjd_et] in ET
  static CrossingInfo swe_mooncross_node(double tjd_et, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// find the crossing of the Moon over its true node, i.e. crossing through the ecliptic at [tjd_ut] in UT
  static CrossingInfo swe_mooncross_node_ut(double tjd_ut, SwephFlag flags) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
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
    }, _allocator);
  }

  /// heliocentric crossings over a position [x2cross] at [tjd_et] in ET
  static double swe_helio_cross(HeavenlyBody target, double x2cross,
      double tjd_et, SwephFlag flags, int dir) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> julianDay = arena<Double>();
      final result = _bindings.swe_helio_cross(
          target.value, x2cross, tjd_et, flags.value, dir, julianDay, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDay.value;
    }, _allocator);
  }

  /// heliocentric crossings over a position [x2cross] at [tjd_ut] in UT
  static double swe_helio_cross_ut(HeavenlyBody target, double x2cross,
      double tjd_ut, SwephFlag flags, int dir) {
    return using((Arena arena) {
      Pointer<Uint8> error = arena<Uint8>(256);
      Pointer<Double> julianDay = arena<Double>();
      final result = _bindings.swe_helio_cross_ut(
          target.value, x2cross, tjd_ut, flags.value, dir, julianDay, error);
      if (result < 0) {
        throw Exception(error.toDartString());
      }
      return julianDay.value;
    }, _allocator);
  }

  // -------------------
  // Auxiliary functions
  // -------------------

  /// coordinate transformation, from ecliptic to equator or vice-versa
  static Coordinates swe_cotrans(Coordinates coordinates, double eps) {
    return using((Arena arena) {
      Pointer<Double> xpn = arena<Double>(3);
      _bindings.swe_cotrans(coordinates.toNativeString(arena), xpn, eps);
      return Coordinates(xpn[0], xpn[1], xpn[2]);
    }, _allocator);
  }

  /// coordinate transformation of position and speed, from ecliptic to equator or vice-versa
  static CoordinatesWithSpeed swe_cotrans_sp(List<double> xpo, double eps) {
    return using((Arena arena) {
      Pointer<Double> xpn = arena<Double>(6);
      _bindings.swe_cotrans_sp(xpo.toNativeString(arena), xpn, eps);
      return CoordinatesWithSpeed(
          xpn[0], xpn[1], xpn[2], xpn[3], xpn[4], xpn[5]);
    }, _allocator);
  }

  /// get the name of a planet
  static String swe_get_planet_name(HeavenlyBody planet) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(256);
      _bindings.swe_get_planet_name(planet.value, buffer);
      final name = buffer.toDartString();
      return name;
    }, _allocator);
  }

  /// normalize degrees to the range 0 ... 360
  static double swe_degnorm(double degrees) {
    return _bindings.swe_degnorm(degrees);
  }

  /// normalize radians to the range 0 ... 2 PI
  static double swe_radnorm(double radians) {
    return _bindings.swe_radnorm(radians);
  }

  /// Radians midpoint
  static double swe_rad_midp(double rad1, double rad2) {
    return _bindings.swe_rad_midp(rad1, rad2);
  }

  /// Degrees midpoint
  static double swe_deg_midp(double deg1, double deg2) {
    return _bindings.swe_deg_midp(deg1, deg2);
  }

  /// split degrees in centiseconds to sign/nakshatra, degrees, minutes, seconds of arc
  static DegreeSplitData swe_split_deg(double deg, SplitDegFlags roundflag) {
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
    }, _allocator);
  }

  // ----------------------------------
  // Other functions that may be useful
  // ----------------------------------

  /// Normalize argument into interval [0..DEG360]
  static Centisec swe_csnorm(Centisec deg) {
    return _bindings.swe_csnorm(deg);
  }

  /// Distance in centisecs p1 - p2 normalized to [0..360]
  static Centisec swe_difcsn(Centisec p1, Centisec p2) {
    return _bindings.swe_difcsn(p1, p2);
  }

  /// Distance in degrees
  double swe_difdegn(double p1, double p2) {
    return _bindings.swe_difdegn(p1, p2);
  }

  /// Distance in centisecs p1 - p2 normalized to [-180..180]
  static Centisec swe_difcs2n(Centisec p1, Centisec p2) {
    return _bindings.swe_difcs2n(p1, p2);
  }

  /// Distance in degrees
  double swe_difdeg2n(double p1, double p2) {
    return _bindings.swe_difdeg2n(p1, p2);
  }

  /// Round second, but at 29.5959 always down
  static Centisec swe_csroundsec(Centisec deg) {
    return _bindings.swe_csroundsec(deg);
  }

  /// Double to long with rounding, no overflow check
  static int swe_d2l(double x) {
    return _bindings.swe_d2l(x);
  }

  /// Day of week Monday = 0, ... Sunday = 6
  static int swe_day_of_week(double julianDay) {
    return _bindings.swe_day_of_week(julianDay);
  }

  /// Centiseconds -> time string
  static String swe_cs2timestr(Centisec deg, int sep, bool suppressZero) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(10);
      _bindings.swe_cs2timestr(deg, sep, suppressZero.value, buffer);
      return buffer.toDartString();
    }, _allocator);
  }

  /// Centiseconds -> longitude or latitude string
  static String swe_cs2lonlatstr(Centisec deg, String pchar, String mchar) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(12);
      _bindings.swe_cs2lonlatstr(
          deg, pchar.firstChar(), mchar.firstChar(), buffer);
      return buffer.toDartString();
    }, _allocator);
  }

  /// Centiseconds -> degrees string
  static String swe_cs2degstr(Centisec deg) {
    return using((Arena arena) {
      Pointer<Uint8> buffer = arena<Uint8>(10);
      _bindings.swe_cs2degstr(deg, buffer);
      return buffer.toDartString();
    }, _allocator);
  }
}
