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
  login(key: sharedPrefKey_login,label: 'login',example: '?action=login&username=CaptainBonkers&password=%s'),
  password(key: sharedPrefKey_password, label: 'password', example: ''),
  brightness(
      key: sharedPrefKey_brightness,
      label: 'brightness',
      example: '?brightness=%s'),
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
