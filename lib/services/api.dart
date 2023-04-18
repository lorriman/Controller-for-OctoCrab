import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/testing.dart';
import 'dart:async';

import 'package:simple_octocrab/services/loggingInst.dart';

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

  OctoCrabApi() {
    if (kDebugMode) {
      log.fine('creating mock client');
      _client = MockClient((request) async {
        //final query=request.url.query;
        final params = request.url.queryParameters;
        final query = request.url.query;

        if (query.startsWith('action=login')) {
          await Future.delayed(Duration(milliseconds: 10000));
          if (params['password'] == '123') {
            return Response(
                json.encode({
                  'numbers': [1, 4, 15, 19, 214]
                }),
                200,
                headers: {'content-type': 'application/json'});
          } else {
            return Response(
                "bad username or password",
                reasonPhrase: "bad username or password",
                403);
          }
        }


        if (query.startsWith("action=on")) {
          return Response(
              json.encode({
                'numbers': [1, 4, 15, 19, 214]
              }),
              200,
              headers: {'content-type': 'application/json'});

        }

        if (query.startsWith("action=off")) {
          return Response(
              json.encode({
                'numbers': [1, 4, 15, 19, 214]
              }),
              200,
              headers: {'content-type': 'application/json'});

        }


        if (query.startsWith("brightness=")) {
          return Response(
              json.encode({
                'numbers': [1, 4, 15, 19, 214]
              }),
              200,
              headers: {'content-type': 'application/json'});

        }

        if (query.startsWith("action=shutdown")) {
          await Future.delayed(Duration(milliseconds: 2000));
          return Response(
              json.encode({
                'numbers': [1, 4, 15, 19, 214]
              }),
              200,
              headers: {'content-type': 'application/json'});

        }


        return Response("", 404);
      });
    } else {
      _client = http.Client();
    }
  }

  init({
    required String address,
    required String shutdown,
    required String login_url,
    required String password,
    required String on_url,
    required String off_url,
    required String next_url,
    required String prev_url,
    required String brightness_url,
/*    required String c1_url,
    required String c2_url,
    required String c3_url,
    required String c4_url,
    required String c5_url,
    required String c6_url,
    required String c7_url,
    required String c8_url,
    required String c9_url,
    required String c10_url, */

  }) {
    this._address = address;
    this._shutdown_url = shutdown;
    this._password = password;
    this._login_url = login_url;
    this._on_url = on_url;
    this._off_url = off_url;
    this._next_url = next_url;
    this._prev_url = prev_url;
    this._brightness_url = brightness_url;
/*    this._c1_url=c1_url;
    this._c2_url=c2_url;
    this._c3_url=c3_url;
    this._c4_url=c4_url;
    this._c5_url=c5_url;
    this._c6_url=c6_url;
    this._c7_url=c7_url;
    this._c8_url=c8_url;
    this._c9_url=c9_url;
    this._c10_url=c10_url; */
  }

  Future<void> dispose() async {
    _client.close();
  }

  String _address = '';
  String _shutdown_url = '';
  String _login_url = '';
  String _password = '';
  String _on_url = '';
  String _off_url = '';
  String _next_url = '';
  String _prev_url = '';
  String _brightness_url = '';
/*  String _c1_url='';
  String _c2_url='';
  String _c3_url='';
  String _c4_url='';
  String _c5_url='';
  String _c6_url='';
  String _c7_url='';
  String _c8_url='';
  String _c9_url='';
  String _c10_url=''; */

  Future<ApiCallResult> _call(
    String uri, {
    String param1 = '',
    String param2 = '',
    String param3 = '',
  }) async {
    String params = '';
    Response response=Response('dummy body',404, reasonPhrase: "dummy response object");

    final parsed=Uri.tryParse(uri);

    bool hasAddressAlready=false;
    if (parsed!=null) {
      try {
        //the get is redundant since when there's no origin it excepts, forcing us to catch
        //#annoyingAPI
        hasAddressAlready = parsed.origin != '';
      }catch(e) {};
    }

    if(!hasAddressAlready && _address==''){
      return ApiCallResult(false,
          errorCode: -1,
          errorString: 'no server configured: $uri');
    }

    params = uri.replaceFirst('%s', param1);
    params = params.replaceFirst('%s', param2);
    params = params.replaceFirst('%s', param3);

    final link = hasAddressAlready? params : '$_address$params';
    final url = Uri.tryParse(link);
    if (url==null){
      return ApiCallResult(false,
          errorCode: -1,
          errorString: 'bad url\n"$link"\ncheck your settings');
    }
    try {
      log.fine('_client.get initiated : $url');
      response = await _client
          .get(url, headers: {'Accept': 'application/json; charset=UTF-8'});
    } on ClientException catch ( e, stacktrace) {
      log.fine('OctoCrabApi._call exception: $e'); //we shouldn't need a stack trace; this is an 'expected' exception
      return ApiCallResult(false, errorCode: 0, errorString: e.toString());
    }

    if (response.statusCode != 200) {
      log.fine('OctoCrabApi._call: '+(response.reasonPhrase  ?? 'Error')+response.body);
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

  Future<ApiCallResult> shutdown() async {
    return await _call(_shutdown_url);
  }

  
  Future<ApiCallResult> brightness({int value = 125}) async {
    return await _call(_brightness_url, param1: value.toString());
  }

  Future<ApiCallResult> userDefined(String url, { String param1='',String param2='', String param3=''}) async {
    return await _call(url, param1 : param1, param2 : param2 , param3 : param3 );
  }
}
