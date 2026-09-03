import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';

class _TestAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async {
    // Map packages/sweph/ to repo root
    final relativePath = assetPath.replaceFirst('packages/sweph/', '');
    final candidates = [
      File(relativePath),
      File('../$relativePath'),
      File('../../$relativePath'),
    ];
    for (final file in candidates) {
      if (file.existsSync()) {
        return file.readAsBytesSync();
      }
    }
    throw Exception('Asset not found: $assetPath');
  }
}

void main() {
  group('Sweph macOS & flutter_test validation', () {
    late Directory tempEpheDir;

    setUpAll(() async {
      tempEpheDir = Directory.systemTemp.createTempSync('sweph_test_ephe');
      await Sweph.init(
        epheAssets: ['packages/sweph/assets/ephe/sefstars.txt'],
        assetLoader: _TestAssetLoader(),
        epheFilesPath: tempEpheDir.path,
      );
    });

    tearDownAll(() {
      try {
        tempEpheDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('swe_version returns non-empty version', () {
      final version = Sweph.swe_version();
      expect(version, isNotEmpty);
      expect(version, startsWith('2.10'));
    });

    test('planetary calculation (Moshier & Swiss Ephemeris)', () {
      final jd = Sweph.swe_julday(2025, 1, 1, 12, CalendarType.SE_GREG_CAL);
      final moon = Sweph.swe_calc_ut(
        jd,
        HeavenlyBody.SE_MOON,
        SwephFlag.SEFLG_MOSEPH,
      );
      expect(moon.longitude, inInclusiveRange(0.0, 360.0));
      expect(moon.latitude, inInclusiveRange(-90.0, 90.0));

      final sun = Sweph.swe_calc_ut(
        jd,
        HeavenlyBody.SE_SUN,
        SwephFlag.SEFLG_MOSEPH,
      );
      expect(sun.longitude, inInclusiveRange(0.0, 360.0));
      expect(sun.latitude, inInclusiveRange(-90.0, 90.0));
    });

    test('houses and cusps calculation', () {
      final jd = Sweph.swe_julday(2025, 6, 21, 12, CalendarType.SE_GREG_CAL);
      const lat = 51.5074; // London
      const lon = -0.1278;

      final houses = Sweph.swe_houses(jd, lat, lon, Hsys.P);
      expect(houses.cusps.length, 13);
      expect(houses.ascmc.length, 10);
      expect(houses.ascmc[0], inInclusiveRange(0.0, 360.0)); // Ascendant
      expect(houses.ascmc[1], inInclusiveRange(0.0, 360.0)); // MC

      final housesEx = Sweph.swe_houses_ex2(
        jd,
        SwephFlag.SEFLG_TROPICAL,
        lat,
        lon,
        Hsys.B,
      );
      expect(housesEx.cusps.length, 13);
      expect(housesEx.ascmc.length, 10);
    });

    test('degree splitting and normalization', () {
      final split = Sweph.swe_split_deg(
        125.456,
        SplitDegFlags.SE_SPLIT_DEG_ZODIACAL |
            SplitDegFlags.SE_SPLIT_DEG_ROUND_SEC |
            SplitDegFlags.SE_SPLIT_DEG_KEEP_SIGN |
            SplitDegFlags.SE_SPLIT_DEG_KEEP_DEG,
      );
      expect(split.degrees, isNonNegative);
      expect(split.minutes, inInclusiveRange(0, 59));
      expect(split.seconds, inInclusiveRange(0, 59));

      final norm = Sweph.swe_degnorm(370.0);
      expect(norm, closeTo(10.0, 1e-6));
    });

    test('fixed-star calculation with loaded ephemeris asset', () {
      final jd = Sweph.swe_julday(2025, 1, 1, 12, CalendarType.SE_GREG_CAL);
      final star = Sweph.swe_fixstar2_ut('Rohini', jd, SwephFlag.SEFLG_SWIEPH);
      expect(star.name, contains('Rohini'));
      expect(star.coordinates.longitude, inInclusiveRange(0.0, 360.0));
      expect(star.coordinates.latitude, inInclusiveRange(-90.0, 90.0));
      expect(star.coordinates.distance, greaterThan(0.0));
    });
  });
}
