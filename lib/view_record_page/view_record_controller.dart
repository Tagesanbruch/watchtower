import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:share_extend/share_extend.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../common/global.dart';
import '../constants.dart';
import '../keys.dart';
import '../record_page/record_controller.dart';
import '../utils.dart';

class ViewRecordController extends GetxController {
  late final Record record;
  final Rx<List<int>?> correctAnnotations = null.obs;
  final DateTime startTime;
  final loading = true.obs;

  final RecordController recordController = Get.find();

  ViewRecordController(this.startTime);

  @override
  void onInit() {
    super.onInit();
    initRecord();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  Future<void> initRecord() async {
    final result = await recordController.getRecordByStartTime(startTime);
    record = result;
    loading.value = false;
  }

  Future<void> promptLoadCorrectAnnotations() async {
    try {
      final String? path = (await FilePicker.platform.pickFiles(
              allowMultiple: false,
              type: FileType.custom,
              allowedExtensions: ["txt"],
              dialogTitle: "Select annotation file"))
          ?.files[0]
          .path;
      if (path != null) {
        final file = File(path);
        final content = await file.readAsString();
        final result = <int>[];
        List<String> lines = content.trim().split("\n");

        // Assuming the header is always present and the format is consistent
        List<String> headers = lines.first
            .split(RegExp(r'\s+'))
            .map((header) => header.trim())
            .toList();
        int sampleIndex = headers.indexOf("Sample");

        for (String line in lines.skip(1)) {
          List<String> values =
              line.split(RegExp(r'\s+')).map((value) => value.trim()).toList();
          if (values.length > sampleIndex) {
            String sampleValue = values[sampleIndex];
            result.add(int.parse(sampleValue));
          }
        }

        correctAnnotations.value = result;
      } else {
        snackbar("Cancelled", "No file was selected.");
      }
    } on PlatformException catch (e) {
      snackbar("Error", "Failed to open file dialog: $e");
    }
  }

  Future<void> promptSaveCurrentRecord() async {
    try {
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
        // snackbar("Error", 'File upload failed: $e');
        EasyLoading.showError('Failed Upload: $e');
      }

      // await Share.shareXFiles([XFile(file.path)], text: 'record file');
      // snackbar("Success", "Record saved successfully.");
    } on PlatformException catch (e) {
      snackbar("Error", "Failed to open file dialog: $e");
    }
  }

  Future<void> uploadFile(File file) async {
    const url = "$serverurl/files/upload";
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
            sendTimeout: const Duration(seconds: 10),
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

  int get timestampStart => record.data.first.timestamp;
  int get timestampEnd => timestampStart + displayTimestampRange;
}

const displayTimestampRange = graphBufferLength;
