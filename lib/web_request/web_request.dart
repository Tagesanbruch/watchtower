/// web interact packaging
library;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:dio/io.dart';
import 'package:watchtower/models/index.dart';
export 'package:dio/dio.dart' show DioException;

import '../common/global.dart';
import '../constants.dart';
import '../keys.dart';

class webinfo {
  webinfo([this.context]) {
    _options = Options(extra: {"context": context});
  }
  BuildContext? context;
  late Options _options;
  static Dio dio = Dio(BaseOptions(
    baseUrl: serverurl,
  ));

  static void init() {
    dio.interceptors.add(NetCache as Interceptor);
    dio.options.headers[HttpHeaders.authorizationHeader] = Global.profile.token;
    
    if (!isRelease) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) {
            return 'PROXY LOCALHOST:8888';
          };
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }
  }

  Future<User> login(String username, String pwd) async {
    String? token = Global.profile.token;
    String header = base64.encode(utf8.encode("token:$token"));
    try {
      EasyLoading.show(status: "Logining...");
      var response = await dio.get(
        "/login",
        data: {
          "username": username,
          "password": pwd,
        }, 
        options: _options.copyWith(
        headers: {
          HttpHeaders.authorizationHeader: header,
        },
        extra: {
          "noCache": true,
        }),
      );

      dio.options.headers[HttpHeaders.authorizationHeader] = response.data["token"];
      NetCache().cache.clear();
      Global.profile.token = response.data["token"];
      EasyLoading.showSuccess('Success.');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        EasyLoading.showError("Incorrect name or password.");
      } else {
        EasyLoading.showError("${e.message}");
      }
      return Future.error(e);
    }
  }

  Future<void> register(String username, String pwd) async {
    //TODO: create a new data structure instead of void
    try {
      EasyLoading.show(status: "Registering...");
      var response = await dio.post(
        "/register",
        data: {
          "username": username,
          "password": pwd,
        },
      );
      EasyLoading.showSuccess('Success.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        EasyLoading.showError("Username is already registered.");
      } else {
        EasyLoading.showError("${e.message}");
      }
    }
  }
}
