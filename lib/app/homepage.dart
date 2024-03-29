import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:simple_octocrab/app/settings.dart';

import 'package:simple_octocrab/services/api.dart';

import 'package:clipboard/clipboard.dart';

import 'appproviders.dart';
import 'colorSettings.dart';
import 'config.dart';

import 'package:simple_octocrab/services/loggingInst.dart';

import 'customWidgets.dart';
import 'homepageAux.dart';


class HomePage extends ConsumerStatefulWidget {
  HomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  final OctoCrabApi _api = OctoCrabApi();
  final Map<ConfigEnum, ConfigItem> _configItems = {};

  String _statusStr = '';
  bool _showLog = false;
  bool _connected =
      true; //set to false to re-enable login logic, see [ConfigEnum] to re-enable options
  bool _is_on = false;
  double _brightness = 0;
  bool _rateLimitBrightness = false;

  //some parameters are redundant but indicate method behaviour
  @override
  void initState() {
    super.initState();
    print('homepage initState');
    _initLogger();
    loadConfig(ref, _configItems);
    _initBrightness(ref);
    configureApi(_api, _configItems);
  }

  _initBrightness(ref) {
    _brightness = ref.read(brightnessProvider).toDouble();
    _rateLimitBrightness = ref.read(rateLimitBrightnessProvider);
  }

  _initLogger() {
    Logger.root.onRecord.listen((record) {
      if (mounted)
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

  @override
  void dispose() {
    print('homepage dispose');
    _api.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _setStatus(String status) {
    setState(() {
      _statusStr = status;
    });
  }

  //determines if the user has configured one of the c1-c10 customisable buttons
  //Not a getter as the compute is relatively expensive
  //todo: cache result
  bool _hasConfiguredCustomItems() {
    int c = 0;
    _configItems.forEach((key, value) {
      if (configCustomSet.contains(key)) value.value != '' ? c++ : null;
    });
    return c > 0;
  }

  //determines if the custom item c1-c10 has been configured
  bool _isConfiguredCustomItemByIndex(int idx) {
    final enumItem = configCustomSet.elementAt(idx);
    return _isConfiguredCustomItem(enumItem);
  }

  bool _isConfiguredCustomItem(ConfigEnum enumItem) {
    return _configItems[enumItem]!.value != '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: !_showLog
          ? null
          : _logFloatingActionButton(context),
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
                onDoubleTap: () => aboutDialog(context),
              ),
            ],
          ),
        ),
        actions: [
            IconButton(
                icon: Icon(Icons.settings_outlined),
                onPressed: ()async  {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => SettingsPage()),
                  );
                  loadConfig(ref, _configItems);
                  configureApi(_api, _configItems);
                }),
        ],
      ),
      drawer: SafeArea(
        child: HomepageDrawer(),
      ),
      body: _showLog
          ? _logView()
          : CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Row(
                    children: [
                      Flexible(
                        flex: 3,
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
                                        _configItems[ConfigEnum.password]!
                                            .value;
                                    _setStatus('connecting...');
                                    result =
                                        await _api.connect(password: password);
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
                                      result = await _api.switchOn();
                                    if (!result.success)
                                      _setStatus(result.errorString);
                                  }
                                },
                              ),
                            ),
                            if (_statusStr != '')
                              Builder(builder: (context) {
                                final statusLines = _statusStr.split('\n');

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, right: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      FittedBox(
                                        child: Text( key: Key('status initial line'),
                                          statusLines[0].trim(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          textScaleFactor: 1.5,
                                        ),
                                      ),
                                      for (int i = 1;
                                          i < statusLines.length;
                                          i++)
                                        Text( key: Key('status line $i'),
                                          statusLines[i].trim(),
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                          textScaleFactor: 1.5,
                                        ),
                                      if (_statusStr == 'connecting...')
                                        CircularProgressIndicator(),
                                    ],
                                  ),
                                );
                              }),
                            FittedBox(
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    FittedBox(
                                      child: OctoButton('prev',
                                          key: Key('prev button'),
                                          fontSize: 40,
                                          onPressed: _connected
                                              ? () async {
                                                  _setStatus('');
                                                  final result =
                                                      await _api.previous();

                                                  _setStatus(
                                                      result.errorString);
                                                }
                                              : null),
                                    ),
                                    FittedBox(
                                      child: OctoButton('next',
                                          key: Key('next button'),
                                          fontSize: 40,
                                          onPressed: _connected
                                              ? () async {
                                                  _setStatus('');
                                                  final result =
                                                      await _api.next();
                                                  _setStatus(
                                                      result.errorString);
                                                }
                                              : null),
                                    )
                                  ]),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 12.0, right: 12),
                              child: OctoSlider(
                                  enabled: _connected,
                                  value: _brightness,
                                  onChange: (value) {
                                    _setStatus('');
                                    setState(() => _brightness = value);
                                  },
                                  onChangeEnd: (value) async {
                                    setState(() {
                                      ref
                                          .read(brightnessProvider.notifier)
                                          .state = value.toInt();
                                    });

                                    final result = await _api.brightness(
                                        value: value.toInt());
                                    _setStatus(result.errorString);
                                  }),
                            ),
                          ],
                        ),
                      ),
                      if (_hasConfiguredCustomItems())
                        Flexible(
                          flex: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FittedBox(
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 10),
                                    for (var i = 0; i < 10; i++)
                                      OctoButton(
                                        'c' + (i + 1).toString(),
                                        key: Key('c' + (i + 1).toString()+' button'),
                                        margin: 5,
                                        fontSize: 18,
                                        onPressed:
                                            !_isConfiguredCustomItemByIndex(i)
                                                ? null
                                                : () async {
                                                    final cLabel =
                                                        'c' + (i + 1).toString();
                                                    final enumItem =
                                                        configCustomSet
                                                            .elementAt(i);
                                                    final url =
                                                        _configItems[enumItem]!
                                                            .value;

                                                    ApiCallResult? result;
                                                    _setStatus(
                                                        'custom function $cLabel ...');
                                                    result = await _api
                                                        .userDefined(url);
                                                    if (!result.success)
                                                      _setStatus(cLabel +
                                                          ' ' +
                                                          result.errorString);
                                                  },
                                      ),
                                  ]),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  FloatingActionButton _logFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
            tooltip: 'copy the log to the clipboard',
            child: Icon(Icons.copy),
            onPressed: () {
              int idx = 0;
              FlutterClipboard.copy(logLines.fold<String>(
                      '', (prev, e) => '$prev\n${idx++} ${e.line}'))
                  .then(
                      (value) => snackBar(context, 'Log copied to clipboard'))
                  .catchError(
                      (err) => snackBar(context, 'Copy failed: $err'));
            });
  }


  _logView(){
    return //todo: refactor to _showLog
      Container(
        color: Color(0x11111111),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Log : ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                controller: _scrollController,
                interactive: true,
                child: ListView.builder(
                    controller: _scrollController, //shrinkWrap: true,
                    itemCount: logLines.length,
                    itemBuilder: (_, idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: SelectableText(
                            style: TextStyle(
                                fontFamily: Platform.isIOS
                                    ? "Courier"
                                    : "monospace"),
                            '${idx} ${logLines[idx].line}'),
                      );
                    }),
              ),
            ),
          ],
        ),
      );
  }
}

class HomepageDrawer extends ConsumerWidget {
  const HomepageDrawer({
    super.key,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
        backgroundColor: NeumorphicTheme.of(context)?.current?.baseColor ?? null,
        width: 350,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OctoText('Options', 40),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              //color: Colors.red,
                              alignment: Alignment.centerLeft,
                              width: 120,
                              child: SizedBox(
                                width: 100,
                                child: OctoSwitch(
                                    value: ref
                                        .read(darkModeProvider), //flicker?
                                    onChanged: (value) {
                                      ref
                                          .read(darkModeProvider.notifier)
                                          .state = value;

                                    }),
                              ),
                            ),
                            OctoText('dark mode', 20),
                          ],
                        ),
                      ),

                      /* Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            NeumorphicCheckbox(value: true, onChanged: (value) {}),
                            SizedBox(width: 20),
                            OctoText('Neumorphic',20),
                          ],
                        ),
                      ),*/
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OctoButton(
                          'color',
                          rounding: 10,
                          onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(40.0),
                                      topRight: Radius.circular(40.0)),
                                ),
                                isScrollControlled: true,
                                builder: (context) {
                                  return ColorSettingsView();
                                });
                          },
                        ),
                      ),
                    ]),
              ),
            ),
Divider(),
            Center(
              child: OctoButton(
                'about', rounding : 10,
                onPressed: () => aboutDialog(context),
              ),
            ),
            Divider(),
          ],
        ));
  }
}
