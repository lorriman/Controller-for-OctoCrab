import 'package:test/test.dart';
import 'package:simple_octocrab/services/api.dart';

void main() {
  group('Testing App Provider', () {
    var api = OctoCrabApi(test: true);



    test('a connection should be made', () async {
      api.init(
        address: 'http://192.168.1.1?',
        login_url : 'action=login&username=user&password=%s',
         prev_url: 'action=prev',
        next_url:  'action=next',
        brightness_url: 'brightness=%s',
        off_url: 'action=off',
        on_url : 'action=on',
        password: '123',
      );

      final res=await api.connect(password :'123');
      expect(res.success, true);
    });

  });
}