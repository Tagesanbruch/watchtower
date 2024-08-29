/// web interact packaging
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:dio/io.dart';
export 'package:dio/dio.dart' show DioError;

import '../constants.dart';

class webinfo {
    // webinfo([this.context]) {
    //     _options = Options(extra: {"context": context});
    // }

    // BuildContext? context;
    late Options _options;
    static Dio dio = new Dio(
        BaseOptions(
            baseUrl: serverurl,
        )
    );

    static void init(){
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

    Future<void> login(String username, String pwd) async{ //TODO: create a new data structure instead of void
        FormData formdata = FormData.fromMap({
          "username": "testuser",
          "password": "testpassword"
        });
        var r = await dio.post(
        "/login",
        data: formdata
        // options: _options.copyWith(headers: {
        //     HttpHeaders.authorizationHeader: basic
        // }, extra: {
        //     "noCache": true, //本接口禁用缓存
        // }),
        );
        //登录成功后更新公共头（authorization），此后的所有请求都会带上用户身份信息
        // dio.options.headers[HttpHeaders.authorizationHeader] = basic;
        // //清空所有缓存
        // Global.netCache.cache.clear();
        // //更新profile中的token信息
        // Global.profile.token = basic;
        // return User.fromJson(r.data);
    }
}
