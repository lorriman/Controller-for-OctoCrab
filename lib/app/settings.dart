import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:simple_octocrab/services/api.dart';

import '../services/shared_preferences_service.dart';
import 'config.dart';
import 'customWidgets.dart';

typedef SimpleEvent = void Function();

class SettingsView extends   ConsumerStatefulWidget {
  SettingsView({super.key, required this.api, this.update, this.onShutdown, this.title});

  final OctoCrabApi api;
  final SimpleEvent? update;
  final SimpleEvent? onShutdown;
  final Widget? title;


  @override
ConsumerState<SettingsView> createState() => _SettingsViewState();

}

class _SettingsViewState extends ConsumerState<SettingsView> {


  final Map<ConfigEnum, TextEditingController> _textControllers = {};
  final Map<ConfigEnum, ConfigItem> _configItems = {};
  final _scrollController=ScrollController();

  @override
  void initState() {
    super.initState();
    //_initLogger();
    _loadConfig(_configItems);
    _initTextControllers(_configItems, _textControllers);


  }

  @override
  void dispose() {
    _disposeTextControllers();
    _scrollController.dispose();
    if(widget.update!=null) widget.update!();
    super.dispose();
  }

  _disposeTextControllers() {
    _textControllers.forEach((key, value) => value.dispose());
    _textControllers.clear();
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
    widget.api.init(
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


  _initTextControllers(configItems, textControllers) {
    for (final enumItem in ConfigEnum.values) {
      final value = configItems[enumItem].value;
      textControllers[enumItem] = TextEditingController();
      textControllers[enumItem]!.text = value;
    }
  }


  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(thumbVisibility: true, controller: _scrollController,thickness: 10,
      child: ListView( shrinkWrap : true,controller: _scrollController,children: [
        if (widget.title!=null)
          widget.title!
        else
          ListTile(title: Text('Configuration',textScaleFactor: 1.4, style: TextStyle(fontWeight: FontWeight.bold)  ,),
           trailing: Icon(Icons.settings_outlined),
          ),
        Divider(),
        Row(
          children: [
            Container(  width : 80,
              child: IconButton(
                style: ButtonStyle(elevation: MaterialStateProperty.all(20.0),
                    shadowColor: MaterialStateProperty.all(Colors.red)),
                icon:
                Icon(Icons.power_settings_new, color: Colors.red.shade300),
                onPressed: widget.onShutdown,
                iconSize: 50,
                tooltip: 'shutdown device',
              ),
            ),
            Text('shutdown remote device',textScaleFactor: 1.2, style: TextStyle(color: Colors.red)),
          ],
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
                //brute-forcing the update because the Drawer doesn't have events like onUnShow
                // which means the c1-10 custom functions don't appear/disappear as they should
                //todo: optimise the setState
                setState((){
                  String str = value.trim();
                  if (str.length > 2040) {
                    /* max url length =2048, we subtract a few bytes */
                    str = str.substring(1, 2040);
                  }
                  sharedPreferencesService.sharedPreferences
                      .setString(item.itemEnum.key, str);
                  _configItems[item.itemEnum] =
                      ConfigItem(item.itemEnum, str);
                  _configureApi(_configItems);
                });
              },
            ); }(),

      ]),
    );
  }


  
}
