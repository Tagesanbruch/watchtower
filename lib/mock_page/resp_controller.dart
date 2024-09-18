import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

import '../constants.dart';
import '../algorithm/resp_algorithm.dart';

class RateData {
  /// timestamp, a simple incremental counter should do
  int timestamp;
  /// sample value
  double value;
  /// lead_off, indicating whether the lead is off
  // bool lead_off;
  /// calculated from timestamp, used in graph rendering
  late int index;

  RateData(this.timestamp, this.value) {
    index = timestamp % graphBufferLength;
  }
}
class RespPageController extends GetxController {
  int fs = 1000; //数据的采样率
  int fsDown = 10; //降采样后的RESP信号的采样率
  int timeLength = 300; //数据的时间长度（秒）
  int n = 9; //利用某时刻前n-1个"峰值间距"计算RESP

  List<int> rpeaks = [];
  List<double> ecgRate = [];
  List<double> edr = [];
  List<int> peaks = [];
  List<double> edrRate = [];

  RespAlgorithm respAlgorithm = RespAlgorithm(); // 创建RespAlgorithm的实例

  @override
  void onInit() {
    super.onInit();
    loadData();
    edrRate = processResp();
  }

  Future<void> loadData() async {
  final data = await rootBundle.loadString('assets/test/resp/rpeaks_buf.csv');
  List<String> lines = data.split('\n');

  // Convert each line to a double
  List<int> rpeaksBuffer = lines.map((line) => int.parse(line)).toList();

  // Process each item in rpeaksBuffer
  // print("test...");
  rpeaks = rpeaksBuffer.map((item) => (item / (fs / fsDown)).floor()).toList();
  // print("test...");
}

  List<double> processResp() {
    List<double> rr = respAlgorithm.intepol(rpeaks, timeLength * fsDown);
    ecgRate = rr.map((value) => 60 * fsDown / value).toList();
    edr = respAlgorithm.bandpassFilter(ecgRate);
    peaks = respAlgorithm.edrPeak(edr, fsDown);
    edrRate = respAlgorithm.respCalculate(peaks, fsDown, timeLength, n);
    return edrRate;
  }
}
