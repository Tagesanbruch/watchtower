/// web interact packaging
library;
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:dio/io.dart';
export 'package:dio/dio.dart' show DioException;

import '../constants.dart';

class webinfo {
  // webinfo([this.context]) {
  //     _options = Options(extra: {"context": context});
  // }

  // BuildContext? context;
  late Options _options;
  static Dio dio = Dio(BaseOptions(
    baseUrl: serverurl,
  ));

  static void init() {
    //......
    if (!isRelease) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          // Config the client.
          client.findProxy = (uri) {
            // Forward all request to proxy "localhost:8888".
            // Be aware, the proxy should went through you running device,
            // not the host platform.
            return 'PROXY LOCALHOST:8888';
          };
          // You can also create a new HttpClient for Dio instead of returning,
          // but a client must being returned here.
          return client;
        },
      );
    }
  }

  Future<void> login(String username, String pwd) async {
    //TODO: create a new data structure instead of void
    try {
      EasyLoading.show(status: "Logining...");
      var response = await dio.post(
        "/login",
        data: {
          "username": username,
          "password": pwd,
        },
      );
      EasyLoading.showSuccess('Success.');
      // print("Response data: ${response.data}");
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        EasyLoading.showError("Incorrect name or password.");
      } else {
        EasyLoading.showError("${e.message}");
      }
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
