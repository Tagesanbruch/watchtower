import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../web_request/web_request.dart';
import '../signal_page/signal_controller.dart';

class SettingsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // final BufferController bufferController = Get.find();

  late AnimationController spinnerController;

  var discovering = false.obs;
  var discoveredEventArgs = [].obs;

  late final StreamSubscription stateChangedSubscription;
  late final StreamSubscription discoveredSubscription;

  var webinfoInstance = webinfo();

  void onStartUp() async {
    WidgetsFlutterBinding.ensureInitialized();
    spinnerController.stop();
  }

  void onCrashed(Object error, StackTrace stackTrace) {
    Get.defaultDialog(
      title: "Error",
      barrierDismissible: false,
      middleText: "Failed to initialize BLE: $error\nRestart app to retry.",
    );
  }

  void setECGMode(int modeECG) async {
    final clearBuffer = Uint8List(32); // Creates a list of 32 zero bytes
    final command = "setECGmode $modeECG ";
    final signalController = Get.find<SignalController>();
    await signalController.sendBLE(String.fromCharCodes(clearBuffer));
    await signalController.sendBLE(command);
  }

  void sendCommand(String commandInput) async {
    final clearBuffer = Uint8List(32); // Creates a list of 32 zero bytes
    final signalController = Get.find<SignalController>();
    await signalController.sendBLE(String.fromCharCodes(clearBuffer));
    await signalController.sendBLE(commandInput);
  }

  @override
  void onInit() {
    spinnerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
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
