import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../web_request/web_request.dart';
// TODO: timeout and stop

class LoginController extends GetxController
    with GetSingleTickerProviderStateMixin {

  late AnimationController spinnerController;

  late final StreamSubscription stateChangedSubscription;
  late final StreamSubscription discoveredSubscription;
  
  var webinfoInstance = webinfo();

  void onStartUp() async {
    WidgetsFlutterBinding.ensureInitialized();
    spinnerController.stop();
    EasyLoading.init();
  }

  void onCrashed(Object error, StackTrace stackTrace) {
    Get.defaultDialog(
      title: "Error",
      barrierDismissible: false,
      middleText: "Failed to initialize BLE: $error\nRestart app to retry.",
    );
  }

  void onLogin(String username, String password) async {
    //  if (pwState.validate()) {
    
      // EasyLoading.show(status: "Logining..."); //TODO: fix the EasyLoading Initial
      // User? user;
      // try {
      //   user = await Git(context)
      //       .login(_unameController.text, _pwdController.text);
      //   Provider.of<UserModel>(context, listen: false).user = user;
      // } on DioError catch( e) {
      //   if (e.response?.statusCode == 401) {
      //     showToast(GmLocalizations.of(context).userNameOrPasswordWrong);
      //   } else {
      //     showToast(e.toString());
      //   }
      // } finally {
      //   // Navigator.of(context).pop();
      // }
      // sleep(Duration(milliseconds: 3000));
      // EasyLoading.showSuccess('Success.');
      // if (user != null) {
      //   Navigator.of(context).pop();
      // }
    // }
    webinfoInstance.login(username, password);
  }

  
  @override
  void onInit() {
    spinnerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    // stateChangedSubscription = CentralManager.instance.stateChanged.listen(
    //   (eventArgs) {
    //     state.value = eventArgs.state;
    //   },
    // );
    // discoveredSubscription = CentralManager.instance.discovered.listen(
    //   (eventArgs) {
    //     final items = discoveredEventArgs;
    //     final i = items.indexWhere(
    //       (item) => item.peripheral == eventArgs.peripheral,
    //     );
    //     if (i < 0) {
    //       discoveredEventArgs.value = [...items, eventArgs];
    //     } else {
    //       items[i] = eventArgs;
    //       discoveredEventArgs.value = [...items];
    //     }
    //   },
    // );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runZonedGuarded(onStartUp, onCrashed);
    });
    super.onInit();
    
  }

  @override
  void dispose() {
    stateChangedSubscription.cancel();
    discoveredSubscription.cancel();
    super.dispose();
  }
}
