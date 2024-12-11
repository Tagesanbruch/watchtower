import 'dart:convert';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/index.dart';
import '../web_request/web_request.dart';

const _themes = <MaterialColor>[
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.red,
];

class Global {
  static late SharedPreferences _prefs;
  static Profile profile = Profile();
  // static NetCache netCache = NetCache();

  static List<MaterialColor> get themes => _themes;

  static bool get isRelease => const bool.fromEnvironment("dart.vm.product");
  final globalDio = Dio();
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();
    var _profile = _prefs.getString("profile");
    if (_profile != null) {
      try {
        profile = Profile.fromJson(jsonDecode(_profile));
      } catch (e) {
        print(e);
      }
    } else {
      profile = Profile()..theme = 0;
    }

    profile.cache = profile.cache ?? CacheConfig()
      ..enable = true
      ..maxAge = 36000
      ..maxCount = 1000;

    webinfo.init();
  }

  static saveProfile() => _prefs.setString("profile", jsonEncode(profile.toJson()));
}

class ProfileChangeNotifier extends ChangeNotifier {
  Profile get _profile => Global.profile;

  @override
  void notifyListeners() {
    Global.saveProfile();
    super.notifyListeners();
  }
}

class UserModel extends ProfileChangeNotifier {
  // User get user => _profile.user!;

  // bool get isLogin => user != null;

  User get user => _profile.user!;

  bool get isLogin => _profile.user != null;

  set user(User user) {
    if (user.username != _profile.user?.username) {
      _profile.lastLogin = _profile.user?.username;
      _profile.user = user;
      notifyListeners();
    }
  }
}

class ThemeModel extends ProfileChangeNotifier {
  ColorSwatch get theme => Global.themes
      .firstWhere((e) => e.value == _profile.theme, orElse: () => Colors.blue);

  set theme(ColorSwatch color) {
    if (color != theme) {
      _profile.theme = color[500]?.value as num;
      notifyListeners();
    }
  }
}

// class LocaleModel extends ProfileChangeNotifier {
//   Locale getLocale() {
//     if (_profile.locale == null) return null;
//     var t = _profile.locale.split("_");
//     return Locale(t[0], t[1]);
//   }

//   String get locale => _profile.locale;

//   set locale(String locale) {
//     if (locale != _profile.locale) {
//       _profile.locale = locale;
//       notifyListeners();
//     }
//   }
// }


class CacheObject {
  CacheObject(this.response)
      : timeStamp = DateTime.now().millisecondsSinceEpoch;
  Response response;
  int timeStamp;

  @override
  bool operator ==(other) {
    return response.hashCode == other.hashCode;
  }

  @override
  int get hashCode => response.realUri.hashCode;
}

class NetCache extends Interceptor {
  /// use LinkedHashMap to ensure the order
  var cache = LinkedHashMap<String, CacheObject>();
  @override
  onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!Global.profile.cache!.enable) {
      return handler.next(options);
    }
    
    /// manual refresh if pull down
    bool refresh = options.extra["refresh"] == true;
    if (refresh) {
      if (options.extra["list"] == true) {
        cache.removeWhere((key, v) => key.contains(options.path));
      } else {
        delete(options.uri.toString());
      }
      return handler.next(options);
    }
    if (options.extra["noCache"] != true &&
        options.method.toLowerCase() == 'get') {
      String key = options.extra["cacheKey"] ?? options.uri.toString();
      var ob = cache[key];
      if (ob != null) {
        /// return cache if not expired
        if ((DateTime.now().millisecondsSinceEpoch - ob.timeStamp) / 1000 <
            Global.profile.cache!.maxAge) {
          return handler.resolve(ob.response);
        } else {
          /// remove expired cache
          cache.remove(key);
        }
      }
    }
    handler.next(options);
  }

  @override
  onResponse(Response response, ResponseInterceptorHandler handler) async {
    /// save cache if enable
    if (Global.profile.cache!.enable) {
      _saveCache(response);
    }
    handler.next(response);
  }

  _saveCache(Response object) {
    RequestOptions options = object.requestOptions;
    if (options.extra["noCache"] != true &&
        options.method.toLowerCase() == "get") {
      /// remove old cache if exceed the maxCount
      if (cache.length == Global.profile.cache!.maxCount) {
        cache.remove(cache[cache.keys.first]);
      }
      String key = options.extra["cacheKey"] ?? options.uri.toString();
      cache[key] = CacheObject(object);
    }
  }

  void delete(String key) {
    cache.remove(key);
  }
}