import 'package:flutter/material.dart';

import 'package:sweph/sweph.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final sweph = Sweph();
  late String swephVersion;
  late double moonLongitude;
  late Future<double> starDistance;
  late Future<String> heavenlyBodyName;

  @override
  void initState() {
    super.initState();
    swephVersion = sweph.swe_version();
    final jd = sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    moonLongitude = sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH).longitude;
    starDistance = getStarName();
    heavenlyBodyName = getAstroidName();
  }

  Future<double> getStarName() async {
    await sweph.ensureInit;
    final jd = sweph.swe_julday(2022, 6, 29, (2 + 52 / 60), CalendarType.SE_GREG_CAL);
    return sweph.swe_fixstar2_ut('Rohini', jd, SwephFlag.SEFLG_SWIEPH).coordinates.distance;
  }

  Future<String> getAstroidName() async {
    await sweph.ensureInit;
    return sweph.swe_get_planet_name(HeavenlyBody.SE_AST_OFFSET + 5);
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
                  const Text(
                    'Dart binding for Swiss Ephemeris',
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                  spacerSmall,
                  Text(
                    'sweph.swe_version = $swephVersion',
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                  spacerSmall,
                  Text(
                    'Moon longitude on 2022-06-29 02:52:00 UTC = $moonLongitude',
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                  spacerSmall,
                  FutureBuilder<double>(
                    future: starDistance,
                    builder: (BuildContext context, AsyncSnapshot<double> value) {
                      final displayValue = (value.hasData) ? value.data : 'loading';
                      return Text(
                        'Distance of star Rohini = $displayValue AU',
                        style: textStyle,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  spacerSmall,
                  FutureBuilder<String>(
                    future: heavenlyBodyName,
                    builder: (BuildContext context, AsyncSnapshot<String> value) {
                      final displayValue = (value.hasData) ? value.data : 'loading';
                      return Text(
                        'Name of 5th asteroid = $displayValue',
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
