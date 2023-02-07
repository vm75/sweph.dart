import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final String moonPosition;
  final String starDistance;
  final String asteroidName;
  final String houseSystemAscmc;
  final String chironPosition;

  SwephTestData(Sweph sweph)
      : swephVersion = getVersion(sweph),
        moonPosition = getMoonLongitude(sweph),
        starDistance = getStarName(sweph),
        asteroidName = getAstroidName(sweph),
        houseSystemAscmc = getHouseSystemAscmc(sweph),
        chironPosition = getChironPosition(sweph);

  static String getVersion(Sweph sweph) {
    return sweph.swe_version();
  }

  static String getMoonLongitude(Sweph sweph) {
    final jd =
        sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    final pos =
        sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH);
    return "lat=${pos.latitude.toStringAsFixed(3)} lon=${pos.longitude.toStringAsFixed(3)}";
  }

  static String getStarName(Sweph sweph) {
    final jd =
        sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    try {
      return sweph
          .swe_fixstar2_ut('Rohini', jd, SwephFlag.SEFLG_SWIEPH)
          .coordinates
          .distance
          .toStringAsFixed(3);
    } catch (e) {
      return e.toString();
    }
  }

  static String getAstroidName(Sweph sweph) {
    return sweph.swe_get_planet_name(HeavenlyBody.SE_AST_OFFSET + 16);
  }

  static String getHouseSystemAscmc(Sweph sweph) {
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
    return result.ascmc[0].toStringAsFixed(3);
  }

  static String getChironPosition(Sweph sweph) {
    final now = DateTime.now();
    final jd = sweph.swe_julday(now.year, now.month, now.day,
        (now.hour + now.minute / 60), CalendarType.SE_GREG_CAL);
    sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    final pos =
        sweph.swe_calc_ut(jd, HeavenlyBody.SE_CHIRON, SwephFlag.SEFLG_SWIEPH);
    return "lat=${pos.latitude.toStringAsFixed(3)} lon=${pos.longitude.toStringAsFixed(3)}";
  }
}

class _MyAppState extends State<MyApp> {
  final Future<Sweph> swephFuture = Sweph.instance;
  late Future<SwephTestData> swephTestData;

  @override
  void initState() {
    super.initState();
    swephTestData = getTestData();
  }

  Future<SwephTestData> getTestData() async {
    final sweph = await swephFuture;
    return SwephTestData(sweph);
  }

  void _addText(List<Widget> children, String text) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);

    children.add(spacerSmall);
    children.add(Text(
      text,
      style: textStyle,
      textAlign: TextAlign.center,
    ));
  }

  Widget _getContent(BuildContext context, SwephTestData? swephTestData) {
    List<Widget> children = [
      const Text(
        'Swiss Ephemeris Exmaple',
        style: TextStyle(fontSize: 30),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10)
    ];

    if (swephTestData == null) {
      _addText(children, 'loading...');
    } else {
      _addText(children, 'Sweph Version: ${swephTestData.swephVersion}');
      _addText(children,
          'Moon position on 2022-06-29 02:52:00 UTC: ${swephTestData.moonPosition}');
      _addText(children,
          'Distance of star Rohini: ${swephTestData.starDistance} AU');
      _addText(children, 'Name of Asteroid 16: ${swephTestData.asteroidName}');
      _addText(children,
          'House System ASCMC[0] for custom time: ${swephTestData.houseSystemAscmc}');
      _addText(
          children, 'Chriron position now: ${swephTestData.chironPosition}');
    }

    return Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: FutureBuilder<SwephTestData>(
                future: swephTestData,
                builder:
                    (BuildContext context, AsyncSnapshot<SwephTestData> value) {
                  return _getContent(context, value.data);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
