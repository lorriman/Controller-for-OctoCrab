import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_octocrab/services/loggingInst.dart';

import 'package:window_size/window_size.dart';

import 'package:simple_octocrab/services/shared_preferences_service.dart';

import 'app/appproviders.dart';
import 'app/homepage.dart';

void main() async {
  print('main started');
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name.padRight(8)}: ${record.time}: ${record.message}');
  });

  Logger.root.onRecord.listen((record) {
    final time = record.time;
    final timeStr = '${time.day}\\${time.hour}:${time.minute}:${time.second}';
    logLines.add(LogLine(record.level, '$timeStr ${record.message}'));
  });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logLines.add(LogLine(
        Level.SEVERE,
        'Flutter Exception "${details.exceptionAsString()}",' +
            (details.stack != null
                ? ' STARTTRACE:\n${details.stack} ENDTRACE'
                : '')));
  };
  PlatformDispatcher.instance.onError = (error, StackTrace stack) {
    logLines.add(LogLine(
        Level.SEVERE,
        'Platform or developer exception: "$error",' +
            (stack != null ? 'STARTTRACE:\n$stack ENDTRACE' : '')));
    return false;
  };
  print('main error handlers initialised');

  if (!kIsWeb) {
    //helps test as phone dimensions when debugging.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (kDebugMode) {
        //setWindowMaxSize(const Size(450, 900));
        //setWindowMinSize(const Size(384, 400));
      } else {
        //setWindowMaxSize(const Size(384, 700));
        //setWindowMinSize(const Size(384, 400));
      }
      //setWindowMaxSize(const Size(700, 384));
      //setWindowMinSize(const Size(700, 384));
      //Rect.fromLTRB(1502.0, 133.0, 1886.0, 933.0);
      //setWindowFrame(Rect frame)
    }
  }
  print('main windows size set');
  final sharedPreferences = await SharedPreferences.getInstance();
  print('main shared preferences instance fetched');
  /*
  //this is removed, but layout issues might require its return so left here
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  ).then((val) {  */
  runApp(ProviderScope(overrides: [
    sharedPreferencesServiceProvider.overrideWithValue(
      SharedPreferencesService(sharedPreferences),
    ),
  ], child: MyApp()));
  //});
//  runApp(const MyApp());
  print('main exiting main');
}

class MyApp extends ConsumerWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context, ref) {
    //return MaterialApp(
    final darkMode = ref.watch(darkModeProvider);
    final baseColor = ref.watch(colorProvider);

    Color colorBrighter(Color color, double brightness) {
      if (brightness == 0.0) return color;
      return Color.lerp(color, Colors.white, brightness) ?? color;
    }

    Color colorDarker(Color color, double darkness) {
      if (darkness == 0.0) return color;
      return Color.lerp(color, Colors.black, darkness) ?? color;
    }

    return NeumorphicApp(

      debugShowCheckedModeBanner: true,
      title: 'Flutter Demo',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: NeumorphicThemeData(
          intensity: 1,
          baseColor: baseColor,
          lightSource: LightSource.topLeft,
          shadowLightColor: baseColor.withOpacity(0.5),
          depth: 7,
          iconTheme: IconThemeData(color: colorDarker(baseColor, 0.5)),
          buttonStyle: NeumorphicStyle(
              shape: NeumorphicShape.concave,
              boxShape: NeumorphicBoxShape.roundRect(
                BorderRadius.circular(20),
              ))),
      darkTheme: NeumorphicThemeData(
        baseColor: colorDarker(baseColor, 0.65), //Color(0xFF3E3E3E),
        shadowDarkColor: colorBrighter(baseColor, 0.0), //Color(0xFFFFFFFF),
        shadowLightColor: colorDarker(baseColor, 0.0), // Color(0xBBBBBBBB),
        lightSource: LightSource.bottomRight,
        iconTheme: IconThemeData(color: colorBrighter(baseColor, 0.0)),
        intensity: .9,
        //variantColor: baseColor,
        accentColor: baseColor.withOpacity(0.7),
        buttonStyle: NeumorphicStyle(
            shape: NeumorphicShape.convex,
            boxShape: NeumorphicBoxShape.roundRect(
              BorderRadius.circular(20),
            )),
      ),

      /*
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),*/
      home: HomePage(title: "Robert's Controller"),
      onUnknownRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              HomePage(title: "Robert's Controller"),
        );
      },
    );
  }
}
