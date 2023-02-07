import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stopwatch = Stopwatch()..start();
  // Only load the assets you need. By default will load none
  // Bundled assets are available in Sweph.bundledEpheAssets
  await Sweph.init(epheAssets: [
    "packages/sweph/assets/ephe/sefstars.txt",
  ]);

  runApp(MyApp(
    timeToLoad: stopwatch.elapsed,
  ));
}

class MyApp extends StatefulWidget {
  final Duration timeToLoad;
  const MyApp({Key? key, required this.timeToLoad}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String swephVersion;
  late String moonPosition;
  late String starDistance;
  late String asteroidName;
  late String houseSystemAscmc;
  late String chironPosition;

  @override
  void initState() {
    super.initState();

    swephVersion = getVersion();
    moonPosition = getMoonLongitude();
    starDistance = getStarName();
    asteroidName = getAstroidName();
    houseSystemAscmc = getHouseSystemAscmc();
    chironPosition = getChironPosition();
  }

  static String getVersion() {
    return Sweph.swe_version();
  }

  static String getMoonLongitude() {
    final jd =
        Sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    final pos =
        Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH);
    return "lat=${pos.latitude.toStringAsFixed(3)} lon=${pos.longitude.toStringAsFixed(3)}";
  }

  static String getStarName() {
    final jd =
        Sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    try {
      return Sweph.swe_fixstar2_ut('Rohini', jd, SwephFlag.SEFLG_SWIEPH)
          .coordinates
          .distance
          .toStringAsFixed(3);
    } catch (e) {
      return e.toString();
    }
  }

  static String getAstroidName() {
    return Sweph.swe_get_planet_name(HeavenlyBody.SE_AST_OFFSET + 16);
  }

  static String getHouseSystemAscmc() {
    const year = 1947;
    const month = 8;
    const day = 15;
    const hour = 16 + (0.0 / 60.0) - 5.5;

    const longitude = 81 + 50 / 60.0;
    const latitude = 25 + 57 / 60.0;
    final julday =
        Sweph.swe_julday(year, month, day, hour, CalendarType.SE_GREG_CAL);

    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI,
        SiderealModeFlag.SE_SIDBIT_NONE, 0.0 /* t0 */, 0.0 /* ayan_t0 */);
    final result = Sweph.swe_houses(julday, latitude, longitude, Hsys.P);
    return result.ascmc[0].toStringAsFixed(3);
  }

  static String getChironPosition() {
    final now = DateTime.now();
    final jd = Sweph.swe_julday(now.year, now.month, now.day,
        (now.hour + now.minute / 60), CalendarType.SE_GREG_CAL);
    Sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    final pos =
        Sweph.swe_calc_ut(jd, HeavenlyBody.SE_CHIRON, SwephFlag.SEFLG_SWIEPH);
    return "lat=${pos.latitude.toStringAsFixed(3)} lon=${pos.longitude.toStringAsFixed(3)}";
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

  Widget _getContent(BuildContext context) {
    List<Widget> children = [
      const Text(
        'Swiss Ephemeris Exmaple',
        style: TextStyle(fontSize: 30),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10)
    ];

    _addText(children,
        'Time taken to load Sweph: ${widget.timeToLoad.inMilliseconds} ms');
    _addText(children, 'Sweph Version: $swephVersion');
    _addText(
        children, 'Moon position on 2022-06-29 02:52:00 UTC: $moonPosition');
    _addText(children, 'Distance of star Rohini: $starDistance AU');
    _addText(children, 'Name of Asteroid 16: $asteroidName');
    _addText(
        children, 'House System ASCMC[0] for custom time: $houseSystemAscmc');
    _addText(children, 'Chriron position now: $chironPosition');

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
                padding: const EdgeInsets.all(10), child: _getContent(context)),
          ),
        ),
      ),
    );
  }
}
