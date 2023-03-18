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


import 'app/homepage.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  Logger.root.onRecord.listen((record) {
    logLines.add(LogLine(record.level,'${record.level.name}: ${record.time}: ${record.message}'));
  });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logLines.add(LogLine(Level.SEVERE,'Flutter Exception "${details.exceptionAsString()}", STARTTRACE:\n${details.stack} ENDTRACE'));

  };
  PlatformDispatcher.instance.onError = (error, StackTrace stack) {
    logLines.add(LogLine(Level.SEVERE,'Platform or developer exception: "$error", STARTTRACE:\n$stack ENDTRACE'));
    return false;
  };

  //helps test as phone dimensions when debugging.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {

    if(kDebugMode) {
      setWindowMaxSize(const Size(384, 700));
      setWindowMinSize(const Size(384, 700));
    } else {
      //setWindowMaxSize(const Size(384, 700));
      setWindowMinSize(const Size(384, 700));

    }
    //setWindowMaxSize(const Size(700, 384));
    //setWindowMinSize(const Size(700, 384));
    //Rect.fromLTRB(1502.0, 133.0, 1886.0, 933.0);
    //setWindowFrame(Rect frame)
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(ProviderScope(overrides: [
    sharedPreferencesServiceProvider.overrideWithValue(
      SharedPreferencesService(sharedPreferences),
    ),
  ], child: MyApp()));

//  runApp(const MyApp());
}

class MyApp extends ConsumerWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context, ref) {
    //return MaterialApp(
    final darkMode = ref.watch(darkModeProvider);

    return NeumorphicApp(
      debugShowCheckedModeBanner: true,
      title: 'Flutter Demo',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: NeumorphicThemeData(
        baseColor: Colors.white70, //(0xFFFFFFFF),
        appBarTheme: NeumorphicAppBarThemeData(color: Colors.white60),
        lightSource: LightSource.topLeft,
        depth: 20,
      ),
      /*
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),*/
      home: MyHomePage(title: "Robert's controller"),
    );
  }
}



