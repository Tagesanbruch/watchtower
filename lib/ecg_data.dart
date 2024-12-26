import 'dart:ffi';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'constants.dart';

/// size in bytes for each packet
const packSize = 4 * 2; // 4 bytes for each int and float

class RRData{
  late int timestamp; 
  late int rrInterval;
  late int index;
}

int imuIndex = 0;

class IMUData{
  int timestamp;
  double accX;
  double accY;
  double accZ;
  bool fallDetected;
  late int index;

  IMUData(this.timestamp, this.accX, this.accY, this.accZ, this.fallDetected){
    index = timestamp % graphIMUBufferLength;
  }

  @override
  String toString() => "IMUData of $accX, $accY, $accZ at $timestamp.";

  static List<IMUData> fromPacket(Uint8List data){
    final bytesGet = ByteData.sublistView(data);
    /// switching bytes[0] <-> bytes[1] , bytes[2] <-> bytes[3] , bytes[4] <-> bytes[5] to adapt device
    
    final bytes = ByteData(bytesGet.lengthInBytes);
    bytes.setInt8(0, bytesGet.getInt8(1));
    bytes.setInt8(1, bytesGet.getInt8(0));
    bytes.setInt8(2, bytesGet.getInt8(3));
    bytes.setInt8(3, bytesGet.getInt8(2));
    bytes.setInt8(4, bytesGet.getInt8(5));
    bytes.setInt8(5, bytesGet.getInt8(4));
    bytes.setInt8(6, bytesGet.getInt8(6));

    
    List<IMUData> result = [];
    final count = (bytes.lengthInBytes / 16).floor() + 1;
    for (var i = 0; i < count; i++) {
      final timestamp = imuIndex++;
      final accX = bytes.getInt16(i * 16).toDouble();
      final accY = bytes.getInt16(i * 16 + 2).toDouble();
      final accZ = bytes.getInt16(i * 16 + 4).toDouble();
      final fallDetected = bytes.getInt8(i * 16 + 6) == 1;
      result.add(IMUData(timestamp, accX, accY, accZ, fallDetected));
    }
    return result;
  }

  static Uint8List serialize(List<IMUData> input) {
    final byteData = ByteData(input.length * 16);
    for (final (i, pack) in input.indexed) {
      byteData.setInt32(i * 16, pack.timestamp);
      byteData.setFloat32(i * 16 + 4, pack.accX);
      byteData.setFloat32(i * 16 + 8, pack.accY);
      byteData.setFloat32(i * 16 + 12, pack.accZ);
      byteData.setInt8(i * 16 + 16, pack.fallDetected ? 1 : 0);
    }
    return byteData.buffer.asUint8List();
  }

  static List<IMUData> deserialize(Uint8List data) {
    final List<IMUData> result = [];
    final byteData = ByteData.view(data.buffer);
    for (int i = 0; i < byteData.lengthInBytes ~/ 16; i++) {
      final timestamp = byteData.getInt32(i * 16);
      final accX = byteData.getFloat32(i * 16 + 4);
      final accY = byteData.getFloat32(i * 16 + 8);
      final accZ = byteData.getFloat32(i * 16 + 12);
      final fallDetected = byteData.getInt8(i * 16 + 16) == 1;
      result.add(IMUData(timestamp, accX, accY, accZ, fallDetected));
    }
    return result;
  }
}

/// internal struct that BLE transmissions decode to
class ECGData {
  /// timestamp, a simple incremental counter should do
  int timestamp;
  /// sample value
  double value;
  /// lead_off, indicating whether the lead is off
  // bool lead_off;
  /// calculated from timestamp, used in graph rendering
  late int index;

  ECGData(this.timestamp, this.value) {
    index = timestamp % graphBufferLength;
  }

  @override
  String toString() => "ECGData of $value at $timestamp.";

  /// decode packet
  static List<ECGData> fromPacket(Uint8List data) {
    final bytes = ByteData.sublistView(data);
    List<ECGData> result = [];
    final count = (bytes.lengthInBytes / 8).floor() + 1;
    for (var i = 0; i < count; i++) {
      final timestamp = bytes.getUint32(i * 6 + 1);//us to ms
      final value = bytes.getInt16(i * 6 + 1 + 4).toDouble() / 256;
      result.add(ECGData(timestamp, value));
    }
    return result;
  }

  /// serialize to bytes for writing to local database
  static Uint8List serialize(List<ECGData> input) {
    final byteData = ByteData(input.length * packSize);
    for (final (i, pack) in input.indexed) {
      byteData.setInt32(i * packSize, pack.timestamp);
      byteData.setFloat32(i * packSize + 4, pack.value);
    }
    return byteData.buffer.asUint8List();
  }

  /// deserialize from local database
  static List<ECGData> deserialize(Uint8List data) {
    final List<ECGData> result = [];
    final byteData = ByteData.view(data.buffer);
    // TODO: for some reason the following check won't pass on android
    // possibly due to SQLite3 libs
    // on Linux this works fine tho
    // if (byteData.lengthInBytes % packSize != 0) {
    //   throw FormatException(
    //       "Invalid format for data buffer, got byteData with length: ${byteData.lengthInBytes}");
    // }
    //
    // update: this should already be fixed after supplying our own libs, but haven't been tested
    // if (byteData.getInt8(0) == 0x06){
    //   lead_off = false;
    // }
    for (int i = 0; i < byteData.lengthInBytes ~/ packSize; i++) {
      final timestamp = byteData.getInt32(i * packSize);
      final value = byteData.getFloat32(i * packSize + 4);
      result.add(ECGData(timestamp, value));
    }
    return result;
  }
}

/// map a list of double to a list of `ECGData`
/// the timestamps of `originalData` is used
List<ECGData> mapArrayToData(
    List<ECGData> originalData, List<double> processedData) {
  return processedData
      .mapIndexed(
          (index, element) => ECGData(originalData[index].timestamp, element))
      .toList();
}


// TODO: push directly into buffer
