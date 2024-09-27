import 'dart:math';
import 'package:collection/collection.dart';

class RespAlgorithm {

  /// function as numpy.argmax
  int argmax(List<double> list) {
    return list.indexOf(list.reduce(max));
  }

  /// function as numpy.median
  double median(List<double> list) {
    list.sort();
    int length = list.length;
    if (length % 2 == 0) {
      return (list[length ~/ 2 - 1] + list[length ~/ 2]) / 2;
    } else {
      return list[length ~/ 2];
    }
  }

  /// function as numpy.mean
  double mean(List<int> list) {
    return list.reduce((a, b) => a + b) / list.length;
  }

  double meanDouble(List<double> list) {
    return list.reduce((a, b) => a + b) / list.length;
  }
  /// function as numpy.diff
  List<int> diff(List<int> list) {
    List<int> diffList = [];
    for (int i = 0; i < list.length - 1; i++) {
      diffList.add(list[i + 1] - list[i]);
    }
    return diffList;
  }

  /// function as numpy.abs
  List<double> abs(List<double> list) {
    return list.map((e) => e.abs()).toList();
  }

  // 插值函数
  // 保持插值，返回插值后的RR间歇序列
  List<double> intepol(List<int> rpeaks, int dataLength) {
    List<double> rr = List<double>.filled(dataLength, 0);
    rr.fillRange(0, rpeaks[2], (rpeaks[1] - rpeaks[0]).toDouble());
    for (int i = 2; i < rpeaks.length - 1; i++) {
      rr.fillRange(rpeaks[i], rpeaks[i + 1], (rpeaks[i] - rpeaks[i - 1]).toDouble());
    }
    rr.fillRange(rpeaks.last, rr.length, (rpeaks.last - rpeaks[rpeaks.length - 2]).toDouble());
    return rr;
  }

  // 滤波函数
  // 0.1-0.4HZ 4 order IIR butter,fs=10Hz
  // 4096*y(n)=32x(n)-64x(n-2)+32x(n-4)+15176y(n-1)-21218y(n-2)+13274y(n-3)-3137y(n-4)
  // 暂时按照浮点计算，不用移位代替乘除
  List<double> bandpassFilter(List<double> ecgRate) {
    int dataLength = ecgRate.length;
    List<double> edr = List<double>.filled(dataLength, 0);
    edr.setRange(0, 4, ecgRate.getRange(0, 4).toList());
    for (int i = 4; i < dataLength; i++) {
      edr[i] = 32 * ecgRate[i] - 64 * ecgRate[i - 2] + 32 * ecgRate[i - 4]
          + 15176 * edr[i - 1] - 21218 * edr[i - 2] + 13274 * edr[i - 3] - 3137 * edr[i - 4];
      edr[i] = edr[i] / 4096;
    }
    return edr;
  }

  // 寻峰函数
  // 过零检测
  List<int> edrPeak(List<double> edr, int fs) {
    double micsFact = 0.5;
    double mdcsFact = 0.1;
    int maxBR = 60;
    double pminFact = 0.1;

    int dataLength = edr.length;
    List<int> zeroUp = [];
    List<int> zeroDown = [];
    List<int> peaks = [];

    for (int i = 1; i < dataLength; i++) {
      if (edr[i - 1] < 0 && edr[i] > 0) {
        zeroUp.add(i);
      }
      if (edr[i - 1] > 0 && edr[i] < 0) {
        zeroDown.add(i);
      }
    }

    if (zeroUp[0] > zeroDown[0]) {
      zeroDown.removeAt(0);
    }

    if (zeroUp.length != zeroDown.length) {
      zeroUp.removeLast();
    }

    // 找到两种zeros之间的最大值作为峰值，同时用MICS和MDCS排除距离相近的峰值（首个峰值不排除）
    // 论文中有用MICS和MDCS排除，但NK库函数省略了这步
    double mics = micsFact * 60 / maxBR * fs;
    double mdcs = mdcsFact * 60 / maxBR * fs;

    int peakInd = argmax(edr.getRange(zeroUp[0], zeroDown[0]).toList());
    peaks.add(peakInd + zeroUp[0]);

    for (int i = 1; i < zeroUp.length; i++) {
      double ics = (zeroDown[i] - zeroDown[i - 1]).toDouble();
      double dcs = (zeroDown[i] - zeroUp[i]).toDouble();
      if (ics > mics && dcs > mdcs) {
        peakInd = edr.getRange(zeroUp[i], zeroDown[i]).toList().indexOf(edr.getRange(zeroUp[i], zeroDown[i]).reduce(max));
        peaks.add(peakInd + zeroUp[i]);
      }
    }

    double peakMed = median(edr.where((element) => peaks.contains(edr.indexOf(element))).toList());
    double pmin = pminFact * peakMed;
    peaks = peaks.where((peak) => edr[peak] > pmin).toList();

    return peaks;
  }

  List<double> respCalculate(List<int> peaks, int fs, int timeLength, int n) {
    List<double> edrRate = List<double>.filled(timeLength, 0);
    for (int t = 0; t < timeLength; t++) {
      List<int> inds = peaks.where((peak) => peak <= (t + 1) * fs).toList();
      if(inds.length <= 2){
        edrRate[t] = 0;
      }
      else if (inds.length < n) {
        edrRate[t] = 60 * fs / mean(diff(inds));
      } else {
        List<int> indsDiff = diff(inds.reversed.toList());
        List<double> indsDiffDouble = indsDiff.map((e) => e.toDouble()).toList();
        List<double> edrPer = abs(indsDiffDouble);
        double edrPerMed = median(edrPer);
        edrPer = edrPer.where((per) => per < edrPerMed * 1.5 && per > edrPerMed * 0.6).toList();
        // edrRate[t] = round(60 * fs / mean(edrPer));
        edrRate[t] = 60 * fs / meanDouble(edrPer);
      }
    }
    return edrRate;
  }
}