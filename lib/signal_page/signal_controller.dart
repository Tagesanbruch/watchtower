// TODO: should probably move this to bluetooth-related directory

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import "package:get/get.dart";

import '../bluetooth_page/bluetooth_device.dart';
import '../ecg_data.dart';
import '../utils.dart';
import 'buffer_controller.dart';

/// listens and decodes BLE data notifications
class SignalController extends GetxController {
  final connectionState = false.obs;
  final Peripheral device;
  final BufferController bufferController;
  GattCharacteristic? targetMessageTX;
  SignalController(this.device, this.bufferController);

  late StreamSubscription connectionStateChangedSubscription;
  late StreamSubscription characteristicNotifiedSubscription;

  @override
  void onInit() {
    super.onInit();
    bufferController.reset();
    CentralManager.instance.connectionStateChanged.listen(
      (eventArgs) {
        if (eventArgs.peripheral != device) {
          return;
        }
        final connectionState = eventArgs.connectionState;
        this.connectionState.value = connectionState;
      },
    );
    characteristicNotifiedSubscription =
        CentralManager.instance.characteristicNotified.listen(
      (eventArgs) {
        if (eventArgs.characteristic.uuid != targetECGCharateristic &&
            eventArgs.characteristic.uuid != targetIMUCharateristic &&
            eventArgs.characteristic.uuid != targetBATCharateristic &&
            eventArgs.characteristic.uuid != targetHRCharateristic) {
          return;
        }
        final packet = eventArgs.value;
        if (eventArgs.characteristic.uuid == targetECGCharateristic) {
          /// ECG packet decode
          if (packet[0] == 0x06) {
            //0x06 -- lead on
            bufferController.leadIsOff.value = false;
          } else if (packet[0] == 0x01) {
            //0x01 -- lead off
            bufferController.leadIsOff.value = true;
          }
          final data = ECGData.fromPacket(packet);
          if (bufferController.leadIsOff == false) {
            bufferController.extend(data);
          }
        } else if (eventArgs.characteristic.uuid == targetBATCharateristic) {
          bufferController.batteryLevel.value = packet[0];
        } else if (eventArgs.characteristic.uuid == targetHRCharateristic) {
          bufferController.heartrateLevel.value = packet[1];
        }
      },
    );

    runZonedGuarded(connect, onCrashed);
  }

  @override
  void onClose() {
    bufferController.reset();
    super.onClose();
  }

  void onCrashed(Object error, StackTrace stackTrace) {
    Get.defaultDialog(
      title: "Error",
      barrierDismissible: false,
      middleText:
          "Critical error occurred during BLE connection: $error\nRestart app to retry.",
    );
  }

  void connect() async {
    // TODO: full screen cover while connecting

    await CentralManager.instance.connect(device).onError(
      (error, stackTrace) {
        snackbar("Error", "Failed to connect to device: $error");
      },
    );
    final services = await CentralManager.instance.discoverGATT(device);
    // TODO: better error management
    GattCharacteristic? target,
        targetECG,
        targetIMU,
        targetBAT,
        targetHR,
        targetMessageTX;
    // outer:
    for (var service in services) {
      // inner:
      if (service.uuid == targetECGService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetECGCharateristic) {
            targetECG = characteristic;
            target = targetECG;
          }
        }
      }
      if (service.uuid == targetIMUService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetIMUCharateristic) {
            targetIMU = characteristic;
          }
        }
      }
      if (service.uuid == targetBATService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetBATCharateristic) {
            targetBAT = characteristic;
          }
        }
      }
      if (service.uuid == targetHRService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetHRCharateristic) {
            targetHR = characteristic;
          }
        }
      }
      if (service.uuid == targetMessageTXService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetMessageTXCharateristic) {
            this.targetMessageTX = characteristic;
          }
        }
      }
    }

    if (target == null ||
        targetBAT == null ||
        targetHR == null ||
        this.targetMessageTX == null) {
      Get.defaultDialog(
          title: "Error",
          middleText: "Not a valid device.",
          textConfirm: "OK",
          onConfirm: () {
            Get.offAllNamed("/bluetooth");
          });
      return;
    }
    await CentralManager.instance
        .setCharacteristicNotifyState(target, state: true);
    await CentralManager.instance
        .setCharacteristicNotifyState(targetBAT, state: true);
    await CentralManager.instance
        .setCharacteristicNotifyState(targetHR, state: true);
  }

  Future<void> sendBLE(String message) async {
    final byteslen = Uint8List.fromList(utf8.encode(message));
    print(byteslen); 
    if (message.length > 32) {
      throw ArgumentError(
          'Message is too long. Maximum length is 32 characters.');
    }

    if (targetMessageTX == null) {
      throw StateError('targetMessageTX is null.');
    }

    final bytes = Uint8List.fromList(utf8.encode(message));
    await CentralManager.instance
        .writeCharacteristic(
      targetMessageTX!,
      value: bytes,
      type: GattCharacteristicWriteType.withResponse,
    )
        .onError(
      (error, stackTrace) {
        snackbar("Error", "Failed to send message: $error");
      },
    );
  }

  void disconnect() async {
    await CentralManager.instance.disconnect(device).onError(
      (error, stackTrace) {
        snackbar("Error", "Failed to connect to device: $error");
      },
    );
  }
}
