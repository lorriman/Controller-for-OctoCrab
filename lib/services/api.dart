import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/testing.dart';
import 'dart:async';

import 'package:http/http.dart';

class ApiCallResult<T> {
  /// 'success' does not represent a boolean API result but whether the call
  /// went through to the server. Repositorys can be expected to convert
  /// a success==false in to an exception, and then perhaps a snackbar.
  ///
  /// Rather 'data' represents an API result, so if you needed a boolean
  /// your API would do:
  ///
  ///     return ApiCallResult<bool>(true, data: yourBoolean  etc...)
  ///
  /// and then the caller of your API, after testing 'success', might
  /// do
  ///
  ///     if(callResult.data){ etc...}
  ///
  ApiCallResult(this.success,
      {this.data, this.errorCode, this.errorString = 'Error'});

  bool success;
  T? data;
  String errorString = 'Error';
  int? errorCode;
}

class OctoCrabApi {
  late http.Client _client;

  OctoCrabApi({bool debug = false}) {
    if (debug) {
      _client = MockClient((request) async {
        if (request.url.query.startsWith( "action=login")) {
          if (request.url.queryParameters['password'] == '123'){
            return Response(
                json.encode({
                  'numbers': [1, 4, 15, 19, 214]
                }),
                200,
                headers: {'content-type': 'application/json'});
        } else {
            return Response("bad username or password", reasonPhrase: "bad username or password", 403);
          }
        }
        return Response("", 404);
      });
    } else {
      _client = http.Client();
    }
  }

  init({
    required String address,
    required String login_url,
    required String password,
    required String on_url,
    required String off_url,
    required String next_url,
    required String prev_url,
    required String brightness_url,
  }) {
    this._address = address;
    this._password = password;
    this._login_url = login_url;
    this._on_url = on_url;
    this._off_url = off_url;
    this._next_url = next_url;
    this._prev_url = prev_url;
    this._brightness_url = brightness_url;
  }

  Future<void> dispose() async {
    _client.close();
  }

  String _address = '';
  String _login_url = '';
  String _password = '';
  String _on_url = '';
  String _off_url = '';
  String _next_url = '';
  String _prev_url = '';
  String _brightness_url = '';

  Future<ApiCallResult> _call(
    String uri, {
    String param1 = '',
    String param2 = '',
    String param3 = '',
  }) async {
    String params = '';
    Response? response;

    params = uri.replaceFirst('%s', param1);
    params = params.replaceFirst('%s', param2);
    params = params.replaceFirst('%s', param3);

    final link = '$_address?$params';
    final url = Uri.parse(link);
    try {
      response = await _client
          .get(url, headers: {'Accept': 'application/json; charset=UTF-8'});
    } catch (e) {
      return ApiCallResult(false, errorCode: 0, errorString: e.toString());
    }
    if (response.statusCode != 200) {
      return ApiCallResult(false,
          errorCode: response.statusCode,
          errorString: response.reasonPhrase ?? 'Error');
    }

    return ApiCallResult<String>(true, data: response.body);
  }

  Future<ApiCallResult> connect({String password = ''}) async {
    return await _call(_login_url, param1: _password);
  }

  Future<ApiCallResult> switchOn() async {
    return await _call(_on_url);
  }

  Future<ApiCallResult> switchOff() async {
    return await _call(_off_url);
  }

  Future<ApiCallResult> next() async {
    return await _call(_next_url);
  }

  Future<ApiCallResult> previous() async {
    return await _call(_prev_url);
  }

  Future<ApiCallResult> brightness({int value = 125}) async {
    return await _call(_brightness_url, param1: value.toString());
  }
}
