import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:http_parser/http_parser.dart';

import '../utils.dart';
import 'ser_de.dart';
import '../ecg_data.dart';
import '../common/global.dart';
import '../keys.dart';
import '../web_request/web_request.dart';

const String dbName = "watchtower.db";
const String tableName = "records";

DateFormat dateFormatter = DateFormat('yyyy-MM-dd kk:mm:ss');
DateFormat dateFormatterFile = DateFormat('yyyy_MM_dd_kk_mm_ss');

class Record {
  final DateTime startTime;
  final Duration duration;
  final List<ECGData> data;
  final List<IMUData> dataIMU;
  final List<int> annotations;

  Record(this.startTime, this.duration, this.data, this.dataIMU,
      {this.annotations = const []});

  Map<String, Object?> toMap() {
    return {
      'start': startTime.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'data': ECGData.serialize(data),
      'dataIMU': IMUData.serialize(dataIMU),
      'annotations': serializeListToInt32(annotations),
    };
  }

  @override
  String toString() =>
      "record from $startTime for $duration with ${data.length} samples, ${annotations.length} annotations";
}

class RecordController extends GetxController {
  late final Database db;
  final RxList<Record> records = <Record>[].obs;
  final refreshing = false.obs;

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runZonedGuarded(onStartUp, onCrashed);
    });
    super.onInit();
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  void onStartUp() async {
    WidgetsFlutterBinding.ensureInitialized();
    final docsDirectory = await getApplicationSupportDirectory();
    db = await openDatabase(
      join(docsDirectory.path, dbName),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $tableName(id INTEGER PRIMARY KEY, start INTEGER, duration INTEGER, data BLOB, dataIMU BLOB, annotations BLOB)',
        );
      },
      version: 3,
    );
    updateRecordList();
  }

  void onCrashed(Object error, StackTrace stackTrace) {
    print(error);
    Get.defaultDialog(
        title: "Error",
        barrierDismissible: false,
        middleText: "Failed to initialize local database.",
        actions: [
          FilledButton(
            child: const Text("Exit"),
            onPressed: () {
              Get.back(closeOverlays: true);
            },
          )
        ]);
  }

  Future<void> addRecord(Record record) async {
    await db.insert(
      tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    updateRecordList();
  }

  Future<void> updateRecordList() async {
    // TODO: lazy loading (pagination)
    refreshing.value = true;
    await awaitWithOverlay(() async {
      final List<Map<String, Object?>> recordMaps = await db.query(tableName,
          columns: [
            "start",
            "duration",
            "annotations"
          ]); // don't query data now to avoid long load time

      final result = [
        for (final {
              'start': startTime as int,
              'duration': duration as int,
              'annotations': annotations as Uint8List
            } in recordMaps)
          Record(DateTime.fromMillisecondsSinceEpoch(startTime),
              Duration(milliseconds: duration), [], [], 
              annotations: deserializeInt32ToList(annotations)),
      ];

      records.value = result;
    });
    refreshing.value = false;
  }

  Future<void> removeRecord(DateTime startTimeInput) async {
    await awaitWithOverlay(() async => db.delete(tableName,
        where: '"start" = ?',
        whereArgs: [startTimeInput.millisecondsSinceEpoch]));

    snackbar("Info", "Record successfully removed.");
    await updateRecordList();
  }

  Future<Record> getRecordByStartTime(DateTime startTimeInput) async {
    final resultMap = await db.query(tableName,
        where: '"start" = ?',
        whereArgs: [startTimeInput.millisecondsSinceEpoch]);
    final {
      'start': startTime as int,
      'duration': duration as int,
      'data': data as Uint8List,
      'dataIMU': dataIMU as Uint8List,
      'annotations': annotations as Uint8List,
    } = resultMap.first;
    return Record(DateTime.fromMillisecondsSinceEpoch(startTime),
        Duration(milliseconds: duration), ECGData.deserialize(data), IMUData.deserialize(dataIMU),
        annotations: deserializeInt32ToList(annotations));
  }

  Future<void> uploadRecord(DateTime startTimeInput) async {
    try {
      final record = await getRecordByStartTime(startTimeInput);
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String path = appDocDir.path;
      final startDisplay = dateFormatterFile.format(record.startTime);
      final fileEcg = File('$path/ECG_$startDisplay.csv');
      final fileImu = File('$path/IMU_$startDisplay.csv');
      
      final buffer = StringBuffer();
      buffer.writeln("timestamp,ECG");
      for (var data in record.data) {
        buffer.writeln("${data.timestamp}, ${data.value}");
      }
      await fileEcg.writeAsString(buffer.toString());

      final bufferImu = StringBuffer();
      bufferImu.writeln("timestamp,IMU");
      for (var data in record.dataIMU) {
        int value = (data.accX << 32 | data.accY << 16 | data.accZ);
        bufferImu.writeln("${data.timestamp}, $value");
      }
      await fileImu.writeAsString(bufferImu.toString());

      try {
        EasyLoading.show(status: "Uploading...");
        await uploadFile(fileEcg);
        await uploadFile(fileImu);
        EasyLoading.showSuccess('Success Upload.');
      } catch (e) {
        EasyLoading.showError('Failed Upload: $e');
      }
    } catch (e) {
      snackbar("Error", "Failed to upload record: $e");
    }
  }

  Future<void> uploadFile(File file) async {
    final webinfo webInfo = Get.find<webinfo>();
    String server = webInfo.serverECG.value;
    String url = "$server/files/upload";
    final username = "abc";
    String? token = Global.profile.token;
    final dio = dio_package.Dio();

    dio.options.headers[HttpHeaders.authorizationHeader] = "Bearer $token";
    dio_package.FormData formData = dio_package.FormData.fromMap({
      'username': username,
      'secretkey': secretKey,
      'file': await dio_package.MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last,
          contentType: MediaType('text', 'csv')),
      'authorization': Global.profile.token,
    });

    try {
      final response = await dio.post(url,
          data: formData,
          options: dio_package.Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
            sendTimeout: const Duration(seconds: 100),
          ));

      if (response.statusCode == 200) {
        snackbar("Success", 'File uploaded successfully');
      } else {
        snackbar("Network Error",
            'File upload failed with status: ${response.statusCode}');
      }
    } on dio_package.DioException catch (e) {
      if (e.type == dio_package.DioExceptionType.sendTimeout) {
        snackbar("Network Error", 'File upload failed: connection timeout');
      } else {
        snackbar("Network Error", 'File upload failed: ${e.message}');
      }
    }
  }
}
