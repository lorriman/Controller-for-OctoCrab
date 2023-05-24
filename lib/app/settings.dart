import 'package:flutter/cupertino.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:simple_octocrab/services/api.dart';

import '../services/shared_preferences_service.dart';
import '../services/utils.dart';
import 'config.dart';
import 'customWidgets.dart';
import 'homepageAux.dart';

typedef SimpleEvent = void Function();

class SettingsPage extends ConsumerStatefulWidget {
  SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<SettingsPage> {
  final ScrollController _scrollController = ScrollController();

  final OctoCrabApi _api = OctoCrabApi();
  final Map<ConfigEnum, ConfigItem> _configItems = {};

  //some parameters are redundant but indicate method behaviour
  @override
  void initState() {
    super.initState();
    print('settingspage initState');
    loadConfig(ref, _configItems);
    configureApi(_api, _configItems);
  }

  @override
  void dispose() {
    print('settingsPage dispose');
    _api.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  //determines if the user has configured one of the c1-c10 customisable buttons
  //Not a getter as the compute is relatively expensive
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
      appBar: NeumorphicAppBar(
        //  automaticallyImplyLeading: true,
        title: FittedBox(
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 10),
              Text(
                'Configuration',
                textScaleFactor: 1.4,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: //todo: refactor to _showLog
          Container(
              color: Color(0x11111111),
              child: SettingsView(
                  api: _api,
                  configItems: _configItems,
                  update: () {
                    loadConfig(ref, _configItems);
                  },
                  onShutdown: () async {
                    final shouldShutdown =
                        await shutdownDialogBuilder(context) ?? false;
                    if (shouldShutdown) {
                      final result = await _api.shutdown();
                      if (result.success) {
                        snackBar(context, 'shutdown signal sent');
                      } else {
                        snackBar(context, 'shutdown signal failed',
                            error: true);
                      }
                    }
                  })),
    );
  }
}

class SettingsView extends ConsumerStatefulWidget {
  SettingsView(
      {super.key,
      required this.api,
      this.update,
      this.onShutdown,
      required this.configItems});

  final OctoCrabApi api;
  final SimpleEvent? update;
  final SimpleEvent? onShutdown;
  final Map<ConfigEnum, ConfigItem> configItems;

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final Map<ConfigEnum, TextEditingController> _textControllers = {};

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initTextControllers(widget.configItems, _textControllers);
  }

  @override
  void dispose() {
    print('settings dispose');
    _disposeTextControllers();
    _scrollController.dispose();
    //if(widget.update!=null) widget.update!();
    super.dispose();
  }

  _disposeTextControllers() {
    _textControllers.forEach((key, value) => value.dispose());
    _textControllers.clear();
  }

  _initTextControllers(configItems, textControllers) {
    for (final enumItem in ConfigEnum.values) {
      final value = configItems[enumItem].value;
      textControllers[enumItem] = TextEditingController();
      textControllers[enumItem]!.text = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final boldStyle = TextStyle(fontWeight: FontWeight.bold);

    return CupertinoScrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      thickness: 10,
      child:
          ListView(shrinkWrap: true, controller: _scrollController, children: [
        ListTile(
            title: Text('commands :', textScaleFactor: 1.2, style: boldStyle)),
        ListTile(
            title: Center(
          child: OutlinedButton(
            onPressed: widget.onShutdown,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(20),
              shape: StadiumBorder(),
              side: BorderSide(
                  width: 1, color: NeumorphicTheme.of(context)?.current?.buttonStyle?.color?.withOpacity(0.5) ?? Colors.grey),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  child: Icon(Icons.power_settings_new,
                      color: Colors.red.shade300),
                ),
                Text('shutdown remote device',
                    textScaleFactor: 1.5, style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        )),
        Divider(),
        ListTile(
            title: Text(
          'buttons:',
          textScaleFactor: 1.2,
          style: boldStyle,
        )),
        for (final item
            in widget.configItems.values.where((e) => e.itemEnum.enabled))
          () {
            final sharedPreferencesService =
                ref.read(sharedPreferencesServiceProvider);

            if (item.itemEnum.checkbox) {
              final value = sharedPreferencesService.sharedPreferences
                      .getString(item.itemEnum.key) ??
                  'false';
              return Row(
                children: [
                  Checkbox(
                    value: value == 'true',
                    onChanged: true
                        ? null
                        : (value) {
                            sharedPreferencesService.sharedPreferences
                                .setString(item.itemEnum.key,
                                    value! ? 'true' : 'false');
                          },
                  ),
                  Text(item.itemEnum.label + ' (tba)',
                      style: TextStyle(color: Colors.grey)),
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
                //brute-forcing the update because the Drawer doesn't have events like onUnShow
                // which means the c1-10 custom functions don't appear/disappear as they should
                //todo: optimise the setState
                setState(() {
                  String str = value.trim();
                  if (str.length > 2040) {
                    /* max url length =2048, we subtract a few bytes */
                    str = str.substring(1, 2040);
                  }
                  sharedPreferencesService.sharedPreferences
                      .setString(item.itemEnum.key, str);
                  widget.configItems[item.itemEnum] =
                      ConfigItem(item.itemEnum, str);
                  configureApi(widget.api, widget.configItems);
                });
              },
            );
          }(),
      ]),
    );
  }
}
