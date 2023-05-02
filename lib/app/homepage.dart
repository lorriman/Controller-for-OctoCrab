import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_octocrab/app/settings.dart';

import 'package:simple_octocrab/services/api.dart';

import 'package:simple_octocrab/services/shared_preferences_service.dart';

import 'package:clipboard/clipboard.dart';

import 'appproviders.dart';
import 'config.dart';

import 'package:simple_octocrab/services/loggingInst.dart';

import 'customWidgets.dart';



class MyHomePage extends ConsumerStatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final ScrollController _scrollController = ScrollController();


  final OctoCrabApi _api = OctoCrabApi();
  final Map<ConfigEnum, ConfigItem> _configItems = {};



  String _status = '';
  bool _showLog = false;
  bool _connected = true; //set to false to re-enable login, see [ConfigEnum] to re-enable options
  bool _is_on = false;
  double _brightness = 0;
  bool _rateLimitBrightness=false;

  //some parameters are redundant but indicate method behaviour
  @override
  void initState() {
    super.initState();
    _initLogger();
    _loadConfig(_configItems);
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
  }

  _snackBar(context, msg, {bool error=false}) {

    final snackBar = SnackBar(
      content: Row(children : [
        if(error) Icon(Icons.error_outline,color : Colors.red,size: 50, ),
        if (error) SizedBox(width:40),
        Text(msg,textScaleFactor: 1.4,)])
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

  //determines if the user has configured one of the c1-c10 customisable buttons
  //Not a getter as the compute is relatively expensive
  bool _hasConfiguredCustomItems(){
    int c=0;
    _configItems.forEach((key, value) {
      if (configCustomSet.contains(key))
        value.value!='' ? c++:null;
    });
    return c>0;
  }

  //determines if the custom item c1-c10 has been configured
  bool _isConfiguredCustomItemByIndex(int idx){
    final enumItem=configCustomSet.elementAt(idx);
    return _isConfiguredCustomItem(enumItem);
  }

  bool _isConfiguredCustomItem(ConfigEnum enumItem){
    return _configItems[enumItem]!.value!='';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        floatingActionButton: !_showLog
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
        appBar: NeumorphicAppBar(
          title: FittedBox(
            child: Row(
              children: [
                InkWell(
                  child: OctoText("Robert's ", 25),
                  onDoubleTap: () => setState(() => _showLog = !_showLog),
                ),
                InkWell(
                  child: OctoText('controller', 25),
                  onDoubleTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          actions: [
            FittedBox(
              child: IconButton( icon: Icon(Icons.power_settings_new,color : Colors.red.shade300),
              onPressed: () async {

                final shouldShutdown=await _shutdownDialogBuilder(context) ?? false;

                if(shouldShutdown) {
                  _setStatus('sending shut down signal...');
                  final result = await _api.shutdown();
                  if (result.success) {
                    _setStatus('');
                    _snackBar(context, 'shutdown signal sent');
                  } else {
                    _setStatus('shutdown error: ${result.errorString}');
                    _snackBar(context, 'shutdown signal failed', error: true);
                  }
                }

              },iconSize: 40,
                tooltip: 'shutdown device',
              ),
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
                        OctoText('dark mode', 20),
                      ],
                    ),
                  ),
              Divider(),
                  SettingsView(api: _api),

            ]),
          )),
        ),
        body: _showLog ?  //todo: refactor to _showLog
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
          Expanded(
            child: Scrollbar(
              trackVisibility: true,
              thickness: 10,
              thumbVisibility: true,
              controller: _scrollController,interactive: true,

              child: ListView.builder(
                  controller: _scrollController,//shrinkWrap: true,
                  itemCount: logLines.length,
                  itemBuilder: (_, idx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: SelectableText(style : TextStyle(fontFamily: Platform.isIOS ? "Courier" : "monospace"),
                          '${idx} ${logLines[idx].line}'),
                    );
                  }),
            ),
          ),
        ],
      ),
    )


        : CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: true,
              child: Row(
                children: [
                  Flexible(flex : 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        FittedBox(
                          child: OctoButton(
                            'on/off',
                            key: Key('on/off button'),
                            fontSize: 60,
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
                          Builder(
                            builder: (context) {
                              final statusLines=_status.split('\n');
                              
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    FittedBox(
                                      child: Text(
                                        statusLines[0].trim(),
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        textScaleFactor: 1.5,
                                      ),
                                    ),
                                    for(int i=1;i<statusLines.length;i++)
                                      Text(
                                        statusLines[i].trim(),
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                        textScaleFactor: 1.5,
                                      ),   
                                    if (_status == 'connecting...')
                                      CircularProgressIndicator(),
                                  ],
                                ),
                              );
                            }
                          ),
                        FittedBox(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                FittedBox(
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
                                FittedBox(
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
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, right: 12),
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

                      ],
                    ),
                  ),
                 if(_hasConfiguredCustomItems()) Flexible( flex : 0,
                  child: FittedBox(
                    child: Column( mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children : [ SizedBox(height: 10),
                      for (var i = 0; i < 10; i++)
                         OctoButton('c'+(i+1).toString(),margin: 5,fontSize: 18,
                          onPressed: !_isConfiguredCustomItemByIndex(i) ? null: ()async{
                            final cLabel='c'+(i+1).toString();
                            final enumItem=configCustomSet.elementAt(i);
                            final url=_configItems[enumItem]!.value;

                            ApiCallResult? result;
                            _setStatus('custom function $cLabel ...');
                            result = await _api.userDefined(url);
                            if (!result.success)
                              _setStatus(cLabel+' '+result.errorString);

                          },),
                        

                    ]),
                  ),
                ),
                ],
               ),
            )
          ],
        ));
  }
}

