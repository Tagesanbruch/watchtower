import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

final targetECGCharateristic = UUID.fromString("00002C92-0000-1000-8000-00805F9B34FB");
final targetHRCharateristic = UUID.fromString("00002A37-0000-1000-8000-00805F9B34FB");
final targetIMUCharateristic = UUID.fromString("00002B55-0000-1000-8000-00805F9B34FB");
final targetBATCharateristic = UUID.fromString("00002A19-0000-1000-8000-00805F9B34FB");
final targetMessageTXCharateristic = UUID.fromString("00002C93-0000-1000-8000-00805F9B34FB");

final targetECGService = UUID.fromString("0000322D-0000-1000-8000-00805F9B34FB");
final targetHRService = UUID.fromString("0000180D-0000-1000-8000-00805F9B34FB");
final targetIMUService = UUID.fromString("00001204-0000-1000-8000-00805F9B34FB");
final targetBATService = UUID.fromString("0000180F-0000-1000-8000-00805F9B34FB");
final targetMessageTXService = UUID.fromString("0000322D-0000-1000-8000-00805F9B34FB");

final targetService = targetECGService;
final targetCharateristic = targetECGCharateristic;
