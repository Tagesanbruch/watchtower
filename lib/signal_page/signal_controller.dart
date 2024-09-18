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
        if (eventArgs.characteristic.uuid != targetMessageRXCharacteristic &&
            eventArgs.characteristic.uuid != targetIMUCharacteristic &&
            eventArgs.characteristic.uuid != targetBATCharacteristic &&
            eventArgs.characteristic.uuid != targetHRCharacteristic) {
          return;
        }
        final packet = eventArgs.value;
        if (eventArgs.characteristic.uuid == targetMessageRXCharacteristic) {
          /// ECG packet decode
          if (packet[0] == 0x06 || packet[0] == 0x01) {
            if (packet[0] == 0x06) {
              //0x06 -- lead on
              bufferController.leadIsOff.value = false;
            } else if (packet[0] == 0x01) {
              //0x01 -- lead off
              bufferController.leadIsOff.value = true;
            }
            final data = ECGData.fromPacket(packet);
            if (!bufferController.leadIsOff.value) {
              bufferController.extend(data);
            }
          }else if(packet[0] == 23) {
            //0x17 -- RR interval
            final rrData = RRData();
            rrData.timestamp = DateTime.now().millisecondsSinceEpoch;
            rrData.rrInterval = (packet[1] * 256 * 256 * 256 + packet[2] * 256 * 256 + packet[3] * 256 + packet[4]) * 1000 ~/ 32768;
            rrData.index = bufferController.rrIntervalBuffer.length;
            if(bufferController.rrIntervalBuffer.isEmpty){
              bufferController.rrIntervalBufferStart.value = rrData.timestamp;
            }
            // bufferController.addRR(rrData);
            bufferController.rrIntervalBuffer.add(rrData);
            bufferController.averageOfLast50RRIntervalsCalc();
            print("RR interval: ${rrData.rrInterval}");
          }
          else{
            print("Unknown packet: $packet");
          }
        } else if (eventArgs.characteristic.uuid == targetBATCharacteristic) {
          bufferController.batteryLevel.value = packet[0];
        } else if (eventArgs.characteristic.uuid == targetHRCharacteristic) {
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
      if (service.uuid == targetMessageRXService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetMessageRXCharacteristic) {
            targetECG = characteristic;
            target = targetECG;
          }
        }
      }
      if (service.uuid == targetIMUService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetIMUCharacteristic) {
            targetIMU = characteristic;
          }
        }
      }
      if (service.uuid == targetBATService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetBATCharacteristic) {
            targetBAT = characteristic;
          }
        }
      }
      if (service.uuid == targetHRService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetHRCharacteristic) {
            targetHR = characteristic;
          }
        }
      }
      if (service.uuid == targetMessageTXService) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == targetMessageTXCharacteristic) {
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
    // final byteslen = Uint8List.fromList(utf8.encode(message));
    // print(byteslen);
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
