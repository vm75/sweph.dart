import 'package:flutter/material.dart';

import 'package:sweph/sweph.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class SwephTestData {
  final String swephVersion;
  final double moonLongitude;
  final double starDistance;
  final String heavenlyBodyName;
  final double houseSystemAscmc;
  final String chironPosition;

  SwephTestData(Sweph sweph)
      : swephVersion = getVersion(sweph),
        moonLongitude = getMoonLongitude(sweph),
        starDistance = getStarName(sweph),
        heavenlyBodyName = getAstroidName(sweph),
        houseSystemAscmc = getHouseSystemAscmc(sweph),
        chironPosition = getChironPosition(sweph);

  static String getVersion(Sweph sweph) {
    return sweph.swe_version();
  }

  static double getMoonLongitude(Sweph sweph) {
    final jd =
        sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    return sweph
        .swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH)
        .longitude;
  }

  static double getStarName(Sweph sweph) {
    final jd =
        sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    return sweph
        .swe_fixstar2_ut('Rohini', jd, SwephFlag.SEFLG_SWIEPH)
        .coordinates
        .distance;
  }

  static String getAstroidName(Sweph sweph) {
    return sweph.swe_get_planet_name(HeavenlyBody.SE_AST_OFFSET + 16);
  }

  static double getHouseSystemAscmc(Sweph sweph) {
    const year = 1947;
    const month = 8;
    const day = 15;
    const hour = 16 + (0.0 / 60.0) - 5.5;

    const longitude = 81 + 50 / 60.0;
    const latitude = 25 + 57 / 60.0;
    final julday =
        sweph.swe_julday(year, month, day, hour, CalendarType.SE_GREG_CAL);

    sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI,
        SiderealModeFlag.SE_SIDBIT_NONE, 0.0 /* t0 */, 0.0 /* ayan_t0 */);
    final result = sweph.swe_houses(julday, latitude, longitude, Hsys.P);
    return result.ascmc[0];
  }

  static String getChironPosition(Sweph sweph) {
    final now = DateTime.now();
    final jd = sweph.swe_julday(now.year, now.month, now.day,
        (now.hour + now.minute / 60), CalendarType.SE_GREG_CAL);
    sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    final pos =
        sweph.swe_calc_ut(jd, HeavenlyBody.SE_CHIRON, SwephFlag.SEFLG_SWIEPH);
    return "lat=${pos.latitude} lon=${pos.longitude}";
  }
}

class _MyAppState extends State<MyApp> {
  final sweph =
      Sweph.getInstance(ephePaths: 'assets${Platform.pathSeparator}ephe');
  late Future<SwephTestData> swephTestData;

  @override
  void initState() {
    super.initState();
    swephTestData = getTestData();
  }

  Future<SwephTestData> getTestData() async {
    // Extracts the resource 'assets/files/seas_18.se1' to 'assets/ephe/seas_18.se1'
    await ResourceUtils.extractAssets(
        'assets/files/seas_18.se1', 'assets/ephe/seas_18.se1');
    return SwephTestData(await sweph);
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    'Dart binding for Swiss Ephemeris (cwd = ${Directory.current})',
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                  spacerSmall,
                  FutureBuilder<SwephTestData>(
                    future: swephTestData,
                    builder: (BuildContext context,
                        AsyncSnapshot<SwephTestData> value) {
                      final sweVersion = (value.hasData)
                          ? value.data!.swephVersion
                          : 'loading';
                      return Text(
                        'sweph.swe_version = $sweVersion',
                        style: textStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  spacerSmall,
                  FutureBuilder<SwephTestData>(
                    future: swephTestData,
                    builder: (BuildContext context,
                        AsyncSnapshot<SwephTestData> value) {
                      final moonLongitude = (value.hasData)
                          ? value.data!.moonLongitude
                          : 'loading';
                      return Text(
                        'Moon longitude on 2022-06-29 02:52:00 UTC = $moonLongitude',
                        style: textStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  spacerSmall,
                  FutureBuilder<SwephTestData>(
                    future: swephTestData,
                    builder: (BuildContext context,
                        AsyncSnapshot<SwephTestData> value) {
                      final displayValue = (value.hasData)
                          ? value.data!.starDistance
                          : 'loading';
                      return Text(
                        'Distance of star Rohini = $displayValue AU',
                        style: textStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  spacerSmall,
                  FutureBuilder<SwephTestData>(
                    future: swephTestData,
                    builder: (BuildContext context,
                        AsyncSnapshot<SwephTestData> value) {
                      final displayValue = (value.hasData)
                          ? value.data!.heavenlyBodyName
                          : 'loading';
                      return Text(
                        'Name of custom planet = $displayValue',
                        style: textStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  spacerSmall,
                  FutureBuilder<SwephTestData>(
                    future: swephTestData,
                    builder: (BuildContext context,
                        AsyncSnapshot<SwephTestData> value) {
                      final displayValue = (value.hasData)
                          ? value.data!.houseSystemAscmc
                          : 'loading';
                      return Text(
                        'House System ASCMC[0] for custom time = $displayValue AU',
                        style: textStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  spacerSmall,
                  FutureBuilder<SwephTestData>(
                    future: swephTestData,
                    builder: (BuildContext context,
                        AsyncSnapshot<SwephTestData> value) {
                      final pos = (value.hasData)
                          ? value.data!.chironPosition
                          : 'loading';
                      return Text(
                        'Chriron position now = $pos',
                        style: textStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
