const sharedPrefKey_server = 'api_server';
const sharedPrefKey_shutdown = 'api_shutdown';

const sharedPrefKey_login = 'api_login';
const sharedPrefKey_password = 'api_password';
const sharedPrefKey_brightness = 'api_brightness';
const sharedPrefKey_on = 'api_on';
const sharedPrefKey_off = 'api_off';
const sharedPrefKey_next = 'api_next';
const sharedPrefKey_prev = 'api_prev';
const sharedPrefKey_rateLimitBrightness= 'api_restrict_brightness1';
const sharedPrefKey_c1='api_userdefined_1';
const sharedPrefKey_c2='api_userdefined_2';
const sharedPrefKey_c3='api_userdefined_3';
const sharedPrefKey_c4='api_userdefined_4';
const sharedPrefKey_c5='api_userdefined_5';
const sharedPrefKey_c6='api_userdefined_6';
const sharedPrefKey_c7='api_userdefined_7';
const sharedPrefKey_c8='api_userdefined_8';
const sharedPrefKey_c9='api_userdefined_9';
const sharedPrefKey_c10='api_userdefined_10';

/// login is disabled, see [ConfigEnum.login]
enum ConfigEnum {
  //the order of items is used to order the UI
  server( enabled: true,
      key: sharedPrefKey_server,
      label: 'default server',
      example: 'example http://192.168.1.100'),
  shutdown( enabled : true,
       key :sharedPrefKey_shutdown,
  label: 'shutdown',
  example: '?action=shutdown',),
  ///see [_MyHomePageState._connected] to re-enable login
  ///Set enabled to true, also see [ConfigEnum.password]
  login(enabled: false, key: sharedPrefKey_login,label: 'login',example: '?action=login&username=CaptainBonkers&password=%s'),
  password(enabled: false, key: sharedPrefKey_password, label: 'password', example: '',indent : 40),
  switchOn(enabled: true,key: sharedPrefKey_on, label: 'switch on', example: '?action=on'),
  switchOff(enabled: true,
      key: sharedPrefKey_off, label: 'switch off', example: '?action=off'),
  next(enabled: true,key: sharedPrefKey_next, label: 'next', example: '?action=next'),

  prev(enabled: true,key: sharedPrefKey_prev, label: 'prev', example: '?action=prev'),
  brightness(enabled: true,
      key: sharedPrefKey_brightness,
      label: 'brightness',
      example: '?brightness=%s'),
  rateLimitBrightness(enabled : true, key : sharedPrefKey_rateLimitBrightness, label: 'rate limit brightness', example : '',checkbox : true, indent : 40 ),
  c1(enabled : true, key : sharedPrefKey_c1, label: 'c1', example : 'custom button example: https://google.com/deletealluserdata'),
  c2(enabled : true, key : sharedPrefKey_c2, label: 'c2', example : ''),
  c3(enabled : true, key : sharedPrefKey_c3, label: 'c3', example : ''),
  c4(enabled : true, key : sharedPrefKey_c4, label: 'c4', example : ''),
  c5(enabled : true, key : sharedPrefKey_c5, label: 'c5', example : ''),
  c6(enabled : true, key : sharedPrefKey_c6, label: 'c6', example : ''),
  c7(enabled : true, key : sharedPrefKey_c7, label: 'c7', example : ''),
  c8(enabled : true, key  :sharedPrefKey_c8, label: 'c8', example : ''),
  c9(enabled : true, key : sharedPrefKey_c9, label: 'c9', example : ''),
  c10(enabled : true, key :sharedPrefKey_c10, label: 'c10', example : '')
  ;

  const ConfigEnum({
    required this.enabled,
    required this.key,
    required this.label,
    required this.example,
    this.checkbox = false,
    this.indent = 0,
  });

  final bool enabled;
  final String key;
  final String label;
  final String example;
  final bool checkbox;
  final int indent;
}

class ConfigItem {
  ConfigItem(this.itemEnum, this.value);

  final ConfigEnum itemEnum;
  final String value;
}

final configCustomSet={
  ConfigEnum.c1,
  ConfigEnum.c2,
  ConfigEnum.c3,
  ConfigEnum.c4,
  ConfigEnum.c5,
  ConfigEnum.c6,
  ConfigEnum.c7,
  ConfigEnum.c8,
  ConfigEnum.c9,
  ConfigEnum.c10,
};
