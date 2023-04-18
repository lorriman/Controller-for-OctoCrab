const sharedPrefKey_server = 'api_server';
const sharedPrefKey_shutdown = 'api_shutdown';

const sharedPrefKey_login = 'api_login';
const sharedPrefKey_password = 'api_password';
const sharedPrefKey_brightness = 'api_brightness';
const sharedPrefKey_on = 'api_on';
const sharedPrefKey_off = 'api_off';
const sharedPrefKey_next = 'api_next';
const sharedPrefKey_prev = 'api_prev';
const SharedPrefKey_rateLimitBrightness= 'api_restrict_brightness1';

/// login is disabled, see [ConfigEnum.login]
enum ConfigEnum {
  //the order of items is used to order the UI
  server( enabled: true,
      key: sharedPrefKey_server,
      label: 'server',
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
  rateLimitBrightness(enabled : true, key : SharedPrefKey_rateLimitBrightness, label: 'rate limit brightness', example : '',checkbox : true, indent : 40 )
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
