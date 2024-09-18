import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

final targetMessageRXCharacteristic = UUID.fromString("00002C92-0000-1000-8000-00805F9B34FB");
final targetHRCharacteristic = UUID.fromString("00002A37-0000-1000-8000-00805F9B34FB");
final targetIMUCharacteristic = UUID.fromString("00002B55-0000-1000-8000-00805F9B34FB");
final targetBATCharacteristic = UUID.fromString("00002A19-0000-1000-8000-00805F9B34FB");
final targetMessageTXCharacteristic = UUID.fromString("00002C93-0000-1000-8000-00805F9B34FB");

final targetMessageRXService = UUID.fromString("0000322D-0000-1000-8000-00805F9B34FB");
final targetHRService = UUID.fromString("0000180D-0000-1000-8000-00805F9B34FB");
final targetIMUService = UUID.fromString("00001204-0000-1000-8000-00805F9B34FB");
final targetBATService = UUID.fromString("0000180F-0000-1000-8000-00805F9B34FB");
final targetMessageTXService = UUID.fromString("0000322D-0000-1000-8000-00805F9B34FB");

final targetService = targetMessageRXService;
final targetCharacteristic = targetMessageRXCharacteristic;
