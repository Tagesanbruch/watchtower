import 'dart:math';

import 'package:collection/collection.dart';
import 'package:community_charts_common/src/chart/common/behavior/chart_behavior.dart';
import 'package:community_charts_flutter/src/behaviors/chart_behavior.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_counter/smooth_counter.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../ecg_data.dart';
import 'buffer_controller.dart';
import '../constants.dart';
import '../algorithm/resp_algorithm.dart';

/// Background Drawing
// class GridlineBackground extends charts.ChartBehavior<charts.NumericCartesianChart> {
//   @override
//   void paint(charts.ChartCanvas canvas, charts.ChartContext context, {required Rect drawBounds, required charts.ChartBehaviorPosition position}) {
//     final paint = charts.ChartCanvas.makePaint()
//       ..color = charts.ColorUtil.fromDartColor(Colors.orange)
//       ..strokeWidth = 1.0;

//     final stepX = drawBounds.width / 10;
//     final stepY = drawBounds.height / 10;

//     for (double x = drawBounds.left; x <= drawBounds.right; x += stepX) {
//       canvas.drawLine(
//         points: [charts.Point(x, drawBounds.top), charts.Point(x, drawBounds.bottom)],
//         paint: paint,
//       );
//     }

//     for (double y = drawBounds.top; y <= drawBounds.bottom; y += stepY) {
//       canvas.drawLine(
//         points: [charts.Point(drawBounds.left, y), charts.Point(drawBounds.right, y)],
//         paint: paint,
//       );
//     }
//   }

//   @override
//   String get role => 'gridlineBackground';

//   @override
//   ChartBehavior<charts.NumericCartesianChart> createCommonBehavior() {
//     // TODO: implement createCommonBehavior
//     throw UnimplementedError();
//   }

//   @override
//   // TODO: implement desiredGestures
//   Set<GestureType> get desiredGestures => throw UnimplementedError();

//   @override
//   void updateCommonBehavior(ChartBehavior<charts.NumericCartesianChart> commonBehavior) {
//     // TODO: implement updateCommonBehavior
//   }
// }

/// the length of the hidden segment
const hiddenLength = packLength;

List<charts.Series<SineWaveData, int>> _createSineWaveData() {
  final List<SineWaveData> sineWave1 = [];
  final List<SineWaveData> sineWave2 = [];
  final List<SineWaveData> sineWave3 = [];

  for (int i = 0; i < 100; i++) {
    sineWave1.add(SineWaveData(i, sin(i * 0.1)));
    sineWave2.add(SineWaveData(i, sin(i * 0.1 + pi / 3)));
    sineWave3.add(SineWaveData(i, sin(i * 0.1 + 2 * pi / 3)));
  }

  return [
    charts.Series<SineWaveData, int>(
      id: "SineWave1",
      domainFn: (SineWaveData item, _) => item.index,
      measureFn: (SineWaveData item, _) => item.value,
      data: sineWave1,
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
    ),
    charts.Series<SineWaveData, int>(
      id: "SineWave2",
      domainFn: (SineWaveData item, _) => item.index,
      measureFn: (SineWaveData item, _) => item.value,
      data: sineWave2,
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
    ),
    charts.Series<SineWaveData, int>(
      id: "SineWave3",
      domainFn: (SineWaveData item, _) => item.index,
      measureFn: (SineWaveData item, _) => item.value,
      data: sineWave3,
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
    ),
  ];
}

class SineWaveData {
  final int index;
  final double value;

  SineWaveData(this.index, this.value);
}

class Graph extends StatelessWidget {
  final BufferController controller = Get.find();
  Graph({super.key});

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
        Obx(() {
          final int batLevel = controller.batteryLevel.value;
          return ListTile(
            leading: const Icon(Icons.battery_0_bar),
            title: const Text("Battery"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // BatteryWidget(batLevel),
                Text('$batLevel%'),
              ],
            ),
          );
        }),
        Card(
            clipBehavior: Clip.hardEdge,
            child: Stack(children: [
              SizedBox(
                  height: 300,
                  child: GetBuilder<BufferController>(builder: (controller) {
                    final buffer = controller.buffer;

                    int freshStart, freshEnd;
                    if (controller.cursorIndex > graphBufferLength) {
                      freshStart = controller.cursorIndex - graphBufferLength;
                      freshEnd = graphBufferLength;
                    } else {
                      freshStart = 0;
                      freshEnd = controller.cursorIndex;
                    }

                    final staleStart = controller.cursorIndex + hiddenLength;

                    final List<charts.Series<ECGData, int>> data = [];

                    /// for hidden segment
                    final List<charts.RangeAnnotationSegment<int>>
                        rangeAnnotations = [];
                    if (staleStart < graphBufferLength) {
                      rangeAnnotations.add(charts.RangeAnnotationSegment(
                          freshEnd,
                          staleStart,
                          charts.RangeAnnotationAxisType.domain,
                          color: hiddenColor));
                    } else {
                      rangeAnnotations.add(charts.RangeAnnotationSegment(
                          freshEnd,
                          graphBufferLength - 1,
                          charts.RangeAnnotationAxisType.domain,
                          color: hiddenColor));
                    }
                    if (freshStart > 0) {
                      rangeAnnotations.add(charts.RangeAnnotationSegment(
                          0, freshStart, charts.RangeAnnotationAxisType.domain,
                          color: hiddenColor));
                    }

                    /// debug view (unimplemented)
                    if (controller.debug.value) {
                      final List<ECGData> processData =
                          controller.processData.isNotEmpty
                              ? ListSlice(
                                  controller.processData,
                                  graphBufferLength - controller.lastFreshIndex,
                                  graphBufferLength - 1)
                              : [];
                      data.add(charts.Series<ECGData, int>(
                          id: "debug",
                          domainFn: (ECGData item, _) => item.index,
                          measureFn: (ECGData item, _) =>
                              item.value - 1, // added offset
                          data: processData,
                          colorFn: (_, __) =>
                              const charts.Color(r: 0x12, g: 0xff, b: 0x59)));

                      final List<ECGData> preprocessedData =
                          controller.preprocessedData.isNotEmpty
                              ? ListSlice(
                                  controller.preprocessedData,
                                  graphBufferLength - controller.lastFreshIndex,
                                  graphBufferLength - 1)
                              : [];

                      data.add(charts.Series<ECGData, int>(
                          id: "debug-preprocessed",
                          domainFn: (ECGData item, _) => item.index,
                          measureFn: (ECGData item, _) =>
                              item.value - 2, // added offset
                          data: preprocessedData,
                          colorFn: (_, __) =>
                              const charts.Color(r: 0x12, g: 0x16, b: 0xff)));
                    }

                    /// for annotations
                    // final finalAnnotation = controller.finalAnnotation;
                    // for (final timestamp in finalAnnotation) {
                    //   if (timestamp < controller.frameStartTimestamp) {
                    //     continue;
                    //   }
                    //   final index = timestamp % graphBufferLength;
                    //   final lowerIndex = index - markLength;
                    //   final upperIndex = index + markLength;
                    //   if (lowerIndex < controller.cursorIndex &&
                    //       upperIndex > 0) {
                    //     rangeAnnotations.add(charts.RangeAnnotationSegment(
                    //         lowerIndex,
                    //         upperIndex,
                    //         charts.RangeAnnotationAxisType.domain,
                    //         color: markColor));
                    //   }
                    // }

                    /// stale frames
                    // if (staleStart < graphBufferLength) {
                    //   data.add(charts.Series<ECGData, int>(
                    //       id: "stale",
                    //       domainFn: (ECGData item, _) => item.index,
                    //       measureFn: (ECGData item, _) => item.value,
                    //       data:
                    //           ListSlice(buffer, staleStart, graphBufferLength),
                    //       colorFn: (_, __) => staleColor));
                    // }

                    /// fresh frames
                    if (buffer.length > graphBufferLength * 2 ~/ 3) {
                      List<ECGData> bufferList = ListSlice(
                          buffer.toList(),
                          0,
                          (graphBufferLength *
                              2 ~/
                              3)); //Slice to adapted index

                      List<ECGData> firstPart = [];
                      List<ECGData> secondPart = [];
                      int splitIndex = bufferList.indexWhere((item) {
                        int currentIndex = bufferList.indexOf(item);
                        return currentIndex < bufferList.length - 1 &&
                            bufferList[currentIndex + 1].index < item.index;
                      });

                      if (splitIndex != -1) {
                        firstPart = bufferList.sublist(0, splitIndex + 1);
                        secondPart = bufferList.sublist(splitIndex + 1);
                      } else {
                        firstPart = bufferList;
                      }

                      data.add(charts.Series<ECGData, int>(
                        id: "firstFresh",
                        domainFn: (ECGData item, _) => item.index,
                        measureFn: (ECGData item, _) => item.value,
                        data: firstPart,
                        colorFn: (_, __) => freshColor,
                      ));

                      if (secondPart.isNotEmpty) {
                        data.add(charts.Series<ECGData, int>(
                          id: "secondFresh",
                          domainFn: (ECGData item, _) => item.index,
                          measureFn: (ECGData item, _) => item.value,
                          data: secondPart,
                          colorFn: (_, __) => freshColor,
                        ));
                      }
                    } else{
                      data.add(charts.Series<ECGData, int>(
                        id: "fresh",
                        domainFn: (ECGData item, _) => item.index,
                        measureFn: (ECGData item, _) => item.value,
                        data: buffer.toList(),
                        colorFn: (_, __) => freshColor,
                      ));
                    }

                    return charts.LineChart(
                      data,
                      animate: false,
                      domainAxis: charts.NumericAxisSpec(
                        viewport: const charts.NumericExtents(
                            0, graphBufferLength - 1),
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: const charts.TextStyleSpec(
                            fontSize: 4,
                            color: charts.MaterialPalette.black,
                          ),
                          lineStyle: charts.LineStyleSpec(
                            color: charts.MaterialPalette.green.shadeDefault,
                          ),
                        ),
                        tickProviderSpec:
                            const charts.BasicNumericTickProviderSpec(
                          desiredTickCount: 100, // 设置X轴的线距
                        ),
                        // tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
                        //   (num value) {
                        //     if (value % 1000 == 0) {
                        //       return value.toString(); // 每1000格标注
                        //     }
                        //     return ''; // 中间不标注
                        //   } as charts.MeasureFormatter?,
                        // ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: const charts.TextStyleSpec(
                            fontSize: 12,
                            color: charts.MaterialPalette.black,
                          ),
                          lineStyle: charts.LineStyleSpec(
                            color: charts.MaterialPalette.green.shadeDefault,
                          ),
                        ),
                        tickProviderSpec:
                            const charts.StaticNumericTickProviderSpec(
                          <charts.TickSpec<num>>[
                            /// Tick => 1.0 -- 5.0 mV
                            charts.TickSpec(-1.0),
                            charts.TickSpec(-0.9),
                            charts.TickSpec(-0.8),
                            charts.TickSpec(-0.7),
                            charts.TickSpec(-0.6),
                            charts.TickSpec(-0.5),
                            charts.TickSpec(-0.4),
                            charts.TickSpec(-0.3),
                            charts.TickSpec(-0.2),
                            charts.TickSpec(-0.1),
                            charts.TickSpec(0),
                            charts.TickSpec(0.1),
                            charts.TickSpec(0.2),
                            charts.TickSpec(0.3),
                            charts.TickSpec(0.4),
                            charts.TickSpec(0.5),
                            charts.TickSpec(0.6),
                            charts.TickSpec(0.7),
                            charts.TickSpec(0.8),
                            charts.TickSpec(0.9),
                            charts.TickSpec(1.0),
                          ],
                        ),
                        viewport:
                            const charts.NumericExtents(lowerLimit, upperLimit),
                      ),
                      behaviors: [charts.RangeAnnotation(rangeAnnotations)],
                    );
                  })),
              Container(
                  padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Obx(() =>
                          controller.state() == BufferControllerState.recording
                              ? const SizedBox(
                                  height: 24,
                                  child: SpinKitDoubleBounce(
                                      color: Colors.redAccent, size: 24))
                              : const SizedBox.shrink()),
                      const SizedBox(width: 6),
                      Obx(() => controller.heartRate.value != null
                          ? SmoothCounter(
                              count: controller.heartrateLevel(),
                              // count: controller.heartRate.value!.toInt(),
                              textStyle: const TextStyle(
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5))
                          : const Text("--",
                              style: TextStyle(
                                  fontSize: 30, letterSpacing: 4, height: 1))),
                      const SizedBox(width: 3),
                      const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text("bpm",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black87)))
                    ],
                  ))
            ])),
        Card(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text("IMU Data", style: Theme.of(context).textTheme.titleMedium),
              SizedBox(
                height: 300,
                child: GetBuilder<BufferController>(builder: (controller) {
                  final imuBuffer = controller.imuBuffer;
                  final imuList = imuBuffer.toList();
                  final List<IMUData> accData = [];

                  accData.addAll(imuList);

                  List<IMUData> bufferList =
                      ListSlice(imuList, 0, (imuBuffer.length));
                  List<IMUData> firstPart = [];
                  List<IMUData> secondPart = [];
                  int splitIndex = bufferList.indexWhere((item) {
                    int currentIndex = bufferList.indexOf(item);
                    return currentIndex < bufferList.length - 1 &&
                        bufferList[currentIndex + 1].index < item.index;
                  });

                  if (splitIndex != -1) {
                    firstPart = bufferList.sublist(0, splitIndex + 1);
                    secondPart = bufferList.sublist(splitIndex + 1);
                  } else {
                    firstPart = bufferList;
                  }
                  final List<charts.Series<IMUData, int>> data = [
                    charts.Series<IMUData, int>(
                      id: "AccXFirst",
                      domainFn: (IMUData item, _) => item.index,
                      measureFn: (IMUData item, _) => item.accX,
                      data: firstPart,
                      colorFn: (_, __) =>
                          charts.MaterialPalette.blue.shadeDefault,
                    ),
                    charts.Series<IMUData, int>(
                      id: "AccXSecond",
                      domainFn: (IMUData item, _) => item.index,
                      measureFn: (IMUData item, _) => item.accX,
                      data: secondPart,
                      colorFn: (_, __) =>
                          charts.MaterialPalette.blue.shadeDefault,
                    ),
                    charts.Series<IMUData, int>(
                      id: "AccYFirst",
                      domainFn: (IMUData item, _) => item.index,
                      measureFn: (IMUData item, _) => item.accY,
                      data: firstPart,
                      colorFn: (_, __) =>
                          charts.MaterialPalette.red.shadeDefault,
                    ),
                    charts.Series<IMUData, int>(
                      id: "AccYSecond",
                      domainFn: (IMUData item, _) => item.index,
                      measureFn: (IMUData item, _) => item.accY,
                      data: secondPart,
                      colorFn: (_, __) =>
                          charts.MaterialPalette.red.shadeDefault,
                    ),
                    charts.Series<IMUData, int>(
                      id: "AccZFirst",
                      domainFn: (IMUData item, _) => item.index,
                      measureFn: (IMUData item, _) => item.accZ,
                      data: firstPart,
                      colorFn: (_, __) =>
                          charts.MaterialPalette.green.shadeDefault,
                    ),
                    charts.Series<IMUData, int>(
                      id: "AccZSecond",
                      domainFn: (IMUData item, _) => item.index,
                      measureFn: (IMUData item, _) => item.accZ,
                      data: secondPart,
                      colorFn: (_, __) =>
                          charts.MaterialPalette.green.shadeDefault,
                    ),
                  ];

                  return charts.LineChart(
                    data,
                    animate: false,
                    defaultRenderer:
                        charts.LineRendererConfig(includePoints: true),
                    domainAxis: charts.NumericAxisSpec(
                      viewport: charts.NumericExtents(0, imuBuffer.length),
                      renderSpec: charts.GridlineRendererSpec(
                        labelStyle: const charts.TextStyleSpec(
                          fontSize: 12,
                          color: charts.MaterialPalette.black,
                        ),
                        lineStyle: charts.LineStyleSpec(
                          color: charts.MaterialPalette.gray.shadeDefault,
                        ),
                      ),
                    ),
                    primaryMeasureAxis: charts.NumericAxisSpec(
                      viewport: const charts.NumericExtents(-1000, 1000),
                      renderSpec: charts.GridlineRendererSpec(
                        labelStyle: const charts.TextStyleSpec(
                          fontSize: 12,
                          color: charts.MaterialPalette.black,
                        ),
                        lineStyle: charts.LineStyleSpec(
                          color: charts.MaterialPalette.gray.shadeDefault,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Card(
            child: Column(children: [
          const SizedBox(
            height: 10,
          ),
          Text("Interval History",
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(
              height: 200,
              child: Obx(() {
                // final intervalHistoryData = [
                //   charts.Series<(int, int), int>(
                //       id: "interval",
                //       domainFn: (data, _) => data.$1,
                //       measureFn: (data, _) => data.$2,
                //       data: controller.intervalHistory())
                // ];
                final List<charts.Series<RRData, int>> data = [];
                final intervalHistoryData =
                    controller.rrIntervalBuffer.toList();
                data.add(charts.Series<RRData, int>(
                  id: "rrInterval",
                  domainFn: (RRData item, _) => item.index,
                  measureFn: (RRData item, _) => item.rrInterval,
                  data: intervalHistoryData,
                  colorFn: (_, __) => freshColor,
                ));
                final viewportStart = intervalHistoryData.isNotEmpty
                    ? max(0,
                        intervalHistoryData.last.index - peakBufferCapacity + 2)
                    : 0;
                final viewportEnd = intervalHistoryData.isNotEmpty
                    ? controller.rrIntervalBufferEnd - 2
                    : peakBufferCapacity - 2;

                return charts.LineChart(
                  data,
                  animate: false, //TODO: animate
                  defaultRenderer:
                      charts.LineRendererConfig(includePoints: true),
                  domainAxis: charts.NumericAxisSpec(
                    viewport: charts.NumericExtents(viewportStart, viewportEnd),
                    renderSpec: charts.NoneRenderSpec(),
                  ),
                  primaryMeasureAxis: const charts.NumericAxisSpec(
                      viewport: charts.NumericExtents(250, 1200)),
                  behaviors: [
                    if (controller.heartRate.value != null)
                      charts.RangeAnnotation([
                        charts.LineAnnotationSegment(
                            60 * 1000 / controller.heartRate.value!,
                            charts.RangeAnnotationAxisType.measure,
                            endLabel: "Average",
                            color: averageLineColor)
                      ])
                  ],
                  layoutConfig: charts.LayoutConfig(
                      leftMarginSpec: charts.MarginSpec.fixedPixel(45),
                      rightMarginSpec: charts.MarginSpec.fixedPixel(30),
                      topMarginSpec: charts.MarginSpec.fixedPixel(15),
                      bottomMarginSpec: charts.MarginSpec.fixedPixel(10)),
                );
              }))
        ])),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text("Debug"),
          trailing: Obx(() => Switch(
                value: controller.debug.value,
                onChanged: (bool value) {
                  controller.debug.value = value;
                },
              )),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("Settings"),
          onTap: () {
            Get.toNamed("/settings");
          },
        ),
        Obx(() => ListTile(
              leading: const Icon(Icons.heat_pump_rounded),
              title: const Text("Respiratory Rate"),
              trailing: Text(
                controller.respiratoryRate.value.toString(),
                style: const TextStyle(fontSize: 20),
              ),
              onTap: () {
                try {
                  final rrInterval = controller.rrIntervalBuffer.toList();
                  List<int> rrPeaksList = [];
                  rrPeaksList.add(0);
                  for (int i = 1; i < rrInterval.length; i++) {
                    rrPeaksList
                        .add(rrInterval[i].rrInterval + rrPeaksList.last);
                  }
                  final timeLength =
                      (rrPeaksList.last - rrPeaksList.first) ~/ 1000;
                  final respRate = RespAlgorithm()
                      .processResp(rrPeaksList, 1000, 10, timeLength, 9);
                  print(respRate);
                  controller.respiratoryRate.value = respRate[-1].toInt();
                } catch (e) {
                  print('Error calculating respRate: $e');
                }
              },
            )),
        ListTile(
          leading: const Icon(Icons.clear_all),
          title: const Text("Clear RRInterval(Debug)"),
          onTap: () {
            controller.rrIntervalBuffer.clear();
            controller.imuBuffer.clear();
          },
        ),
        const SizedBox(
          height: 80.0,
        ),
      ]);
}

// TODO: stale color tween
