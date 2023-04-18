//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:simple_octocrab/services/api.dart';

import 'package:simple_octocrab/services/shared_preferences_service.dart';

import 'package:clipboard/clipboard.dart';

import 'config.dart';

import 'package:simple_octocrab/services/loggingInst.dart';

final darkModeProvider = StateProvider<bool>((ref) {
  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getBool('darkMode') ?? false;
});

final brightnessProvider = StateProvider<int>((ref) {
  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getInt('brightness') ?? 125;
});

final rateLimitBrightnessProvider = StateProvider<bool>((ref) {
  final prefService = ref.read(sharedPreferencesServiceProvider);
  return prefService.sharedPreferences.getString(SharedPrefKey_rateLimitBrightness)=='true' ?? false;
});


class MyHomePage extends ConsumerStatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final Map<ConfigEnum, TextEditingController> _textControllers = {};
  final ScrollController _scrollController = ScrollController();

  final Map<ConfigEnum, ConfigItem> _configItems = {};
  final OctoCrabApi _api = OctoCrabApi();

  String _status = '';
  bool _debug = false;
  bool _connected = true; //set to false to renable login, see [ConfigEnum] to re-enable options
  bool _is_on = false;
  double _brightness = 0;
  bool _rateLimitBrightness=false;

  //some paramters are redundant but indicate method behaviour
  @override
  void initState() {
    super.initState();
    _initLogger();
    _loadConfig(_configItems);
    _initTextControllers(_configItems, _textControllers);
    _initBrightness(ref);
    _configureApi(_configItems);
  }

  _initBrightness(ref) {
    _brightness = ref.read(brightnessProvider).toDouble();
    _rateLimitBrightness= ref.read(rateLimitBrightnessProvider);
  }


  _initLogger() {
    Logger.root.onRecord.listen((record) {
      setState(() {
        _scrollLogDown();
      }); //updates the log view if visible
    });
  }

  Future<void> _scrollLogDown() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
/*  animated scrolling doesn't keep up
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
      );*/
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _scrollLogUp() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  void _loadConfig(Map<ConfigEnum, ConfigItem> configItems) {
    configItems.clear();

    final sharedPrefs = ref.read(sharedPreferencesServiceProvider);

    for (final enumItem in ConfigEnum.values) {
      final value = sharedPrefs.sharedPreferences.getString(enumItem.key) ??
          enumItem.example;
      final item = ConfigItem(enumItem, value);
      configItems[enumItem] = item;
      //textControllers[enumItem] = TextEditingController();
      //textControllers[enumItem]!.text = value;
    }
  }

  _initTextControllers(configItems, textControllers) {
    for (final enumItem in ConfigEnum.values) {
      final value = configItems[enumItem].value;
      textControllers[enumItem] = TextEditingController();
      textControllers[enumItem]!.text = value;
    }
  }

  _configureApi(Map<ConfigEnum, ConfigItem> configItems) {
    _api.init(
      address: configItems[ConfigEnum.server]!.value,
      shutdown : configItems[ConfigEnum.shutdown]!.value,
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
    _disposeTextControllers();
    _api.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _disposeTextControllers() {
    _textControllers.forEach((key, value) => value.dispose());
    _textControllers.clear();
  }

  _snackBar(context, msg) {
    final snackBar = SnackBar(
      content: Text(msg),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _setStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  void _showAboutDialog(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    showAboutDialog(
      context: context,
      applicationName: 'Controller for Octocrab',
      applicationVersion: 'v. ${info.version.toString()} +${info.buildNumber}',
      applicationIcon: Icon(Icons.info_outline),
    );
  }

  Future<bool?> _shutdownDialogBuilder(BuildContext context) {
    return showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(icon:Icon(size: 70,Icons.power_settings_new,color : Colors.red) ,
          //title: const Text('Shutdown'),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
          content: const Text('Are you sure you wish to shutdown the remote device?',textScaleFactor: 1.3),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              )
              ,
              child: const Text('Yes',textScaleFactor: 2),
              onPressed: () {
                Navigator.of(context).pop(true);
              },

            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel ',textScaleFactor: 2),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    //final darkMode = ref.watch(darkModeProvider);
    return Scaffold(
        floatingActionButton: !_debug
            ? null
            : FloatingActionButton(
                tooltip: 'copy the log to the clipboard',
                child: Icon(Icons.copy),
                onPressed: () {
                  int idx = 0;
                  FlutterClipboard.copy(logLines.fold<String>(
                          '', (prev, e) => '$prev\n${idx++} ${e.line}'))
                      .then((value) =>
                          _snackBar(context, 'Log copied to clipboard'))
                      .catchError(
                          (err) => _snackBar(context, 'Copy failed: $err'));
                }),
        //backgroundColor: Colors.white70,
        appBar: NeumorphicAppBar(
          title: Row(
            children: [
              GestureDetector(
                child: OctoText("Robert's ", 25),
                onDoubleTap: () => setState(() => _debug = !_debug),
              ),
              GestureDetector(
                child: OctoText('controller', 25),
                onDoubleTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          actions: [
            IconButton( icon: Icon(Icons.power_settings_new,color : Colors.red),
            onPressed: () async {

              final shouldShutdown=await _shutdownDialogBuilder(context) ?? false;

              if(shouldShutdown) {
                _setStatus('sending shut down signal...');
                final result = await _api.shutdown();
                if (result.success) {
                  _setStatus('');
                  _snackBar(context, 'shutdown signal sent');
                  //_snackBar(context,result.errorString+' '+result.errorCode.toString());
                } else {
                  _setStatus(result.errorString);
                }
              }

            },iconSize: 50,
              tooltip: 'shutdown device',
            ),

          ],
        ),
        drawer: SafeArea(
          child: Drawer( width: 350,
              child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OctoText('Settings', 40),
              ),
              Divider(),
              for (final item in _configItems.values.where((e)=>e.itemEnum.enabled))
              (){

                final sharedPreferencesService =
                ref.read(sharedPreferencesServiceProvider);


                if (item.itemEnum.checkbox){
                  final value=sharedPreferencesService.sharedPreferences
                      .getString(item.itemEnum.key) ?? 'false';
                  return Row(
                    children: [
                      Checkbox(value:value=='true',onChanged: true ? null : (value){

                        sharedPreferencesService.sharedPreferences
                            .setString(item.itemEnum.key, value! ? 'true' : 'false' );
                      }
                        , ),
                      Text(item.itemEnum.label+' (tba)',style: TextStyle(color: Colors.grey)),
                    ],

                  );
                }

                return InputBox(
                  item.itemEnum.label,
                  _textControllers[item.itemEnum]!,
                  sharedPrefKey: item.itemEnum.key,
                  ref: ref,
                  password: item.itemEnum.key == sharedPrefKey_password,
                  onChanged: (value) {
                    String str = value.trim();
                    if (str.length > 2040) {
                      /* max url length =2048*/
                      str = str.substring(1, 2040);
                    }
                    sharedPreferencesService.sharedPreferences
                        .setString(item.itemEnum.key, str);
                    _configItems[item.itemEnum] =
                        ConfigItem(item.itemEnum, str);
                    _configureApi(_configItems);
                  },
                ); }(),
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
                            value: ref.read(darkModeProvider), //flicker?
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
            ]),
          )),
        ),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                //mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  //OctoText('TEST',100),
                  SizedBox(
                    width: 300,
                    height: 200,
                    child: OctoButton(
                      'on/off',
                      key: Key('on/off button'),
                      fontSize: 70,
                      onPressed: () async {
                        ApiCallResult? result;
                        _setStatus('');
                        if (!_connected) {
                          final password =
                              _configItems[ConfigEnum.password]!.value;
                          _setStatus('connecting...');
                           result = await _api.connect(password: password);
                          if (result.success) {
                            _setStatus('');
                            setState(() {
                              _connected = true;
                            });
                            //_snackBar(context,result.errorString+' '+result.errorCode.toString());
                          } else {
                            _setStatus(result.errorString);
                          }
                        }
                        if (_connected) {
                          _is_on = !_is_on;
                          if (_is_on)
                            result = await _api.switchOff();
                          else
                            result = await  _api.switchOn();
                          if (!result.success) _setStatus(result.errorString);
                        }
                      },
                    ),
                  ),
                  if (_status != '')
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: 300),
                            height: 100,
                            child: Center(
                              child: Text(
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                _status,
                                textScaleFactor: 1.5,
                              ),
                            ),
                          ),
                          if (_status == 'connecting...')
                            CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 100,
                          child: OctoButton('prev',
                              fontSize: 40,
                              onPressed: _connected
                                  ? () async {
                                _setStatus('');
                                      final result= await _api.previous();
                                     _setStatus(result.errorString);
                                    }
                                  : null),
                        ),
                        SizedBox(
                          width: 150,
                          height: 100,
                          child: OctoButton('next',
                              fontSize: 40,
                              onPressed: _connected
                                  ? () async {
                                _setStatus('');
                                final result= await _api.next();
                                _setStatus(result.errorString);
                                    }
                                  : null),
                        )
                      ]),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0, right: 32),
                    child: OctoSlider(
                        enabled: _connected,
                        value: _brightness,
                        onChange: (value) {
                          _setStatus('');
                          setState(() => _brightness = value);
                        },
                        onChangeEnd: (value) async {
                          setState(() {
                            ref.read(brightnessProvider.notifier).state =
                                value.toInt();
                          });
                          final sharedPreferencesService =
                              ref.read(sharedPreferencesServiceProvider);
                          sharedPreferencesService.sharedPreferences
                              .setInt('brightness', value.toInt());
                          final result=await _api.brightness(value: value.toInt());
                          _setStatus(result.errorString);

                        }),
                  ),
                  if (_debug) //todo: refactor to _showLog
                    Container(
                      color: Color(0x11111111),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('Log : ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                  icon: Icon(Icons.keyboard_double_arrow_down),
                                  onPressed: () => _scrollLogDown()),
                              IconButton(
                                  icon: Icon(Icons.keyboard_double_arrow_up),
                                  onPressed: () => _scrollLogUp()),
                            ],
                          ),
                          SizedBox(
                            height: 140,
                            child: Scrollbar(
                              trackVisibility: true,
                              thickness: 10,
                              thumbVisibility: true,
                              controller: _scrollController,
                              child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: logLines.length,
                                  itemBuilder: (_, idx) {
                                    return SelectableText(
                                        '${idx} ${logLines[idx].line}');
                                  }),
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            )
          ],
        ));
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
          //depth: 2,
          intensity: 0.3,
          //lightSource: LightSource.topRight,
        ),
        textStyle:
            NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else if (darkMode) {
      return NeumorphicText(
        text,
        /* style: NeumorphicStyle(
          //shadowLightColor: Colors.black,
          //depth: 2,
          //intensity: 0.4,
          color: Colors.grey,
          //lightSource: LightSource.topRight,
        ), */
        textStyle:
            NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else if (disabled) {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          //shadowLightColor: Colors.black,
          depth: 0.5,
          intensity: 0.9,
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                onChanged: onChanged,
                controller: controller,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.only(left: 8, right: 8), // Removes padding
                  //isDense: true,                   // Centers the text
                  //border: InputBorder.none,
                  //hintText: placeholder,
                  //hintStyle: TextStyle(color: Theme.of(context).hintColor),
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
    this.onChange,
    this.onChangeEnd,
    required this.value,
    super.key,
  });

  final double value;
  final bool enabled;
  final NeumorphicSliderListener? onChange;
  final NeumorphicSliderListener? onChangeEnd;

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
                  border: NeumorphicBorder(
                      isEnabled: true, width: 2, color: Color(0x11111111)),
                  disableDepth: true,
                  accent: Colors.black26,
                  variant: Colors.black26,
                  lightSource: LightSource.bottomLeft,
                  depth: 4)
              : SliderStyle(
                  border: NeumorphicBorder(
                      isEnabled: true, width: 2, color: Color(0xEEEEEEEE)),
                  disableDepth: true,
                  accent: Colors.white,
                  variant: Colors.white,
                  lightSource: LightSource.bottomLeft,
                  depth: 4)),
      max: 255,
      min: 1,
      value: value,
      onChanged: onChange,
      onChangeEnd: onChangeEnd,
    );
  }
}
