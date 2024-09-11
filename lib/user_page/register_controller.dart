import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../web_request/web_request.dart';

// TODO: timeout and stop

class RegisterController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // final BufferController bufferController = Get.find();

  late AnimationController spinnerController;

  var discovering = false.obs;
  var discoveredEventArgs = [].obs;
  
  late final StreamSubscription stateChangedSubscription;
  late final StreamSubscription discoveredSubscription;

  var webinfoInstance = webinfo();

  void onStartUp() async {
    // TODO: reduce logging level after debugging
    // CentralManager.instance.logLevel = Level.WARNING;
    WidgetsFlutterBinding.ensureInitialized();
    spinnerController.stop();
    // await CentralManager.instance.setUp();
    // state.value = await CentralManager.instance.getState();
    // await startDiscovery();
  }

  void onCrashed(Object error, StackTrace stackTrace) {
    Get.defaultDialog(
      title: "Error",
      barrierDismissible: false,
      middleText: "Failed to initialize BLE: $error\nRestart app to retry.",
    );
  }
  
  void onRegister(String username, String password) async {
    webinfoInstance.register(username, password);
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
