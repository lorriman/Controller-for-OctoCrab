import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;


import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_octocrab/services/api.dart';
import 'package:window_size/window_size.dart';

import 'package:simple_octocrab/services/shared_preferences_service.dart';

import 'package:simple_octocrab/services/loggingInst.dart';
import 'package:clipboard/clipboard.dart';


final darkModeProvider = StateProvider<bool>((ref) {
  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getBool('darkMode') ?? false;
});

final brightnessProvider = StateProvider<int>((ref) {
  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getInt('brightness') ?? 125;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });


  //helps test as phone dimensions when debugging.
  if (kDebugMode && (Platform.isWindows || Platform.isLinux)) {
    setWindowMaxSize(const Size(384, 700));
    setWindowMinSize(const Size(384, 700));
    //setWindowMaxSize(const Size(700, 384));
    //setWindowMinSize(const Size(700, 384));
    Rect.fromLTRB(1502.0, 133.0, 1886.0, 933.0);
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
        depth: 40,
      ),
      /*
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),*/
      home: MyHomePage(title: "Robert's controller"),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

const sharedPrefKey_server = 'api_server';
const sharedPrefKey_login = 'api_login';
const sharedPrefKey_password = 'api_password';
const sharedPrefKey_brightness = 'api_brightness';
const sharedPrefKey_on = 'api_on';
const sharedPrefKey_off = 'api_off';
const sharedPrefKey_next = 'api_next';
const sharedPrefKey_prev = 'api_prev';

enum ConfigEnum {
  //the order of items is used to order the UI
  server(
      key: sharedPrefKey_server,
      label: 'server',
      example: 'example http://192.168.1.100'),
  login(key: sharedPrefKey_login,label: 'login',example: '?action=login&username=%s&password=%s'),
  password(key: sharedPrefKey_password, label: 'password', example: ''),
  brightness(
      key: sharedPrefKey_brightness,
      label: 'brightness',
      example: '?brightness=255'),
  switchOn(key: sharedPrefKey_on, label: 'switch on', example: '?action=on'),
  switchOff(
      key: sharedPrefKey_off, label: 'switch off', example: '?action=off'),
  next(key: sharedPrefKey_next, label: 'next', example: '?action=next'),
  prev(key: sharedPrefKey_prev, label: 'prev', example: '?action=prev');

  const ConfigEnum({
    required this.key,
    required this.label,
    required this.example,
  });

  final String key;
  final String label;
  final String example;
}

class ConfigItem {
  ConfigItem(this.itemEnum, this.value);

  final ConfigEnum itemEnum;
  final String value;
}

class _MyHomePageState extends ConsumerState<MyHomePage> {


  final Map<ConfigEnum, TextEditingController> textControllers = {};
  final Map<ConfigEnum,ConfigItem> configItems={};
  final OctoCrabApi api = OctoCrabApi(debug: true);
  final List<String> loglines=[];

  String _status='';
  bool _debug=false;
  bool _connected = false;
  bool _is_on=false;

  @override
  void initState() {
    super.initState();
    Logger.root.onRecord.listen((record) {
      loglines.add('${record.level.name}: ${record.time}: ${record.message}');
    });



    _loadConfig(configItems);
    _initTextControllers(configItems,textControllers);
    _configureApi(configItems);
  }

  _snackBar(context,msg){
    final snackBar = SnackBar(
      content: Text(msg),
    );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _setStatus(String status){
    setState((){_status=status;});
  }

  void _loadConfig(configItems ) {

    configItems.clear();

    final sharedPrefs = ref.read(sharedPreferencesServiceProvider);
    
    for (final enumItem in ConfigEnum.values) {
      final value = sharedPrefs.sharedPreferences.getString(enumItem.key) ??
          enumItem.example;
      final item=ConfigItem(enumItem, value);
      configItems[enumItem]=item;
      //textControllers[enumItem] = TextEditingController();
      //textControllers[enumItem]!.text = value;
    }
  }

  _initTextControllers(configItems, textControllers){
    for (final enumItem in ConfigEnum.values) {
      final value=configItems[enumItem].value;
      textControllers[enumItem] = TextEditingController();
      textControllers[enumItem]!.text = value;
    }

  }

  _configureApi(Map<ConfigEnum,ConfigItem> configItems){

    api.init(
      address: configItems[ConfigEnum.server]!.value,
      password: configItems[ConfigEnum.password]!.value,
      login_url: configItems[ConfigEnum.login]!.value,
      on_url: configItems[ConfigEnum.switchOn]!.value,
      off_url: configItems[ConfigEnum.switchOff]!.value,
      brightness_url: configItems[ConfigEnum.brightness]!.value,
      next_url: configItems[ConfigEnum.next]!.value,
      prev_url: configItems[ConfigEnum.prev]!.value,
    );

  }

  @override
  void dispose() {
    textControllers.forEach((key, value) => value.dispose());
    textControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider);
    return Scaffold(
      floatingActionButton: !_debug ? null : FloatingActionButton(child : Icon(Icons.copy), onPressed : (){
        FlutterClipboard.copy(loglines.join('\n')).then(( value ) =>
            print('copied'));
      }),
      //backgroundColor: Colors.white70,
      appBar: NeumorphicAppBar(
        title: Row(
          children: [
            GestureDetector(child: OctoText("Robert's ",25),
            onDoubleTap: ()=>setState(()=>_debug=!_debug),),
            OctoText('controller', 25),
          ],
        ),
      ),
      drawer: Drawer(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OctoText('Settings', 40),
        ),
        Divider(),
        for (final item in configItems.values)
          InputBox(item.itemEnum.label, textControllers[item.itemEnum]!,
              sharedPrefKey: item.itemEnum.key, ref: ref,
              onChanged: (value) {
                String str = value;
                if (str.length > 2040) {
                  /* max url length =2048*/
                  str = str.substring(1, 2040);
                }
                final sharedPreferencesService =
                ref.read(sharedPreferencesServiceProvider);
                sharedPreferencesService.sharedPreferences
                    .setString(item.itemEnum.key, str);
                configItems[item.itemEnum]=ConfigItem(item.itemEnum, str);
                _configureApi(configItems);

              },



          ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                width: 120,
                child: SizedBox(
                  width: 100,
                  child: OctoSwitch(
                      value: ref.watch(darkModeProvider),
                      onChanged: (value) {
                        ref.read(darkModeProvider.notifier).state = value;
                        final sharedPreferencesService =
                            ref.read(sharedPreferencesServiceProvider);
                        sharedPreferencesService.sharedPreferences
                            .setBool('darkMode', value);
                      }),
                ),
              ),
              OctoText('Dark mode', 20),
            ],
          ),
        ),
      ])),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //OctoText('TEST',100),
            SizedBox(
              width: 300,
              height: 200,
              child: OctoButton('on/off', fontSize: 70, onPressed: () async {
                final password=configItems[ConfigEnum.password]!.value;
                _setStatus('connecting...');
                final result=await api.connect(password: password);
                if(!result.success){
                    _setStatus(result.errorString+' '+result.errorCode.toString());
                   //_snackBar(context,result.errorString+' '+result.errorCode.toString());
                } else {
                _setStatus('');
                  setState(() {
                    _connected = true;
                  });
                  if (_is_on)
                    api.switchOff();
                  else
                    api.switchOn();
                  _is_on=!_is_on;

                }


              }),
            ),
            if(_status!='') SizedBox(height:70,child:Text(_status)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              SizedBox(
                width: 150,
                height: 100,
                child: OctoButton('prev',
                    fontSize: 40,
                    onPressed: _connected ? () {
                      api.previous();
                    } : null),
              ),
              SizedBox(
                width: 150,
                height: 100,
                child: OctoButton('next',
                    fontSize: 40,
                    onPressed: _connected ? () {
                  api.next();
                    } : null),
              )
            ]),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OctoSlider(
                  enabled: _connected,

                  onChanged: _connected
                      ? (value) {
                          setState(() {
                            ref.read(brightnessProvider.notifier).state =
                                value.toInt();
                          });
                          final sharedPreferencesService =
                              ref.read(sharedPreferencesServiceProvider);
                          sharedPreferencesService.sharedPreferences
                              .setInt('brightness', value.toInt());
                          api.brightness(value: value.toInt());
                        }
                      : null),
            ),
            if (_debug) SizedBox( height : 150,
              child : ListView.builder(itemCount: loglines.length,itemBuilder: (_,idx){

                return SelectableText(loglines[idx]);

              }),
            )
          ],
        ),
      ),
    );
  }
}

class OctoSwitch extends ConsumerWidget {
  const OctoSwitch({
    required this.value,
    this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, ref) {
    return NeumorphicSwitch(
      value: value,
      onChanged: onChanged,
    );
  }
}

class OctoButton extends StatelessWidget {
  const OctoButton(
    String this.label, {
    this.fontSize = 20,
    this.onPressed,
    super.key,
  });

  final double fontSize;
  final String label;
  final NeumorphicButtonClickListener? onPressed;

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
        margin: EdgeInsets.all(10),
        pressed: null,
        onPressed: onPressed,
        style: NeumorphicStyle(
          shape: onPressed == null
              ? NeumorphicShape.flat
              : NeumorphicShape.concave,
          lightSource: LightSource.topRight,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          intensity: 3,
          depth: 4,
          disableDepth: false,
        ),
        child: Center(
          child: OctoText(
            label,
            fontSize,
            disabled: onPressed == null,
          ),
        ));
  }
}

class OctoText extends ConsumerWidget {
  const OctoText(
    this.text,
    this.size, {
    this.disabled = false,
    super.key,
  });

  final String text;
  final double size;
  final bool disabled;

  @override
  Widget build(BuildContext context, ref) {
    final darkMode = ref.watch(darkModeProvider);

    if (disabled & darkMode) {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          //shadowLightColor: Colors.black,
          depth: 2,
          intensity: 0.4,
          //lightSource: LightSource.topRight,
        ),
        textStyle:
            NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else if (darkMode) {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          //shadowLightColor: Colors.black,
          //depth: 2,
          //intensity: 0.4,
          color: Colors.grey,
          //lightSource: LightSource.topRight,
        ),
        textStyle:
            NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else if (disabled) {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          //shadowLightColor: Colors.black,
          depth: 0.5,
          intensity: 0.6,
//          color: Colors.grey,
          //lightSource: LightSource.topRight,
        ),
        textStyle:
            NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          depth: 4,
          intensity: 1,
          //shadowDarkColor: Colors.black26,
          //lightSource: LightSource.topRight,
          //shape: NeumorphicShape.convex,
          surfaceIntensity: .01,
          color: Colors.white,
          //oppositeShadowLightSource: true,
        ),
        textStyle:
            NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    }
  }
}

class InputBox extends StatelessWidget {
  const InputBox(this.label, this.controller,
      {required this.sharedPrefKey,
      required this.ref,
      this.password = false,
      this.maxLength,
        this.onChanged,
      super.key});

  final String label;
  final int? maxLength;
  final sharedPrefKey;
  final TextEditingController controller;
  final WidgetRef ref;
  final bool password;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Flexible(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16,8,16,8),
          child: SizedBox(
            //flex: 1,
              //fit: FlexFit.tight,
              height: 50,
              //width: 250,
              child: TextField(
                maxLength: maxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                maxLines: 1,
                obscureText: password,
                onChanged : onChanged,
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1),
                  ),
                ),
              )),
        ),
      ),
    ]);
  }
}

class OctoSlider extends ConsumerWidget {
  const OctoSlider({
    bool this.enabled = true,
    this.onChanged,
    super.key,
  });

  final bool enabled;
  final NeumorphicSliderListener? onChanged;

  @override
  Widget build(BuildContext context, ref) {
    return NeumorphicSlider(
        style: enabled
            ? (ref.watch(darkModeProvider)
                ? SliderStyle(
                    accent: Colors.black,
                    variant: Colors.black,
                    lightSource: LightSource.bottomLeft,
                    depth: 4)
                : SliderStyle(
                    accent: Colors.white,
                    variant: Colors.grey,
                    lightSource: LightSource.bottomLeft,
                    depth: 4))
            : (ref.watch(darkModeProvider)
                ? SliderStyle(
                    disableDepth: true,
                    accent: Colors.black26,
                    variant: Colors.black26,
                    lightSource: LightSource.bottomLeft,
                    depth: 4)
                : SliderStyle(
                    disableDepth: true,
                    accent: Colors.white,
                    variant: Colors.white,
                    lightSource: LightSource.bottomLeft,
                    depth: 4)),
        max: 255,
        min: 1,
        value: ref.watch(brightnessProvider.notifier).state.toDouble(),
        onChanged: onChanged);
  }
}

