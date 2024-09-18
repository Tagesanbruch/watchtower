import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import '../constants.dart';

import '../navigation.dart';
import 'resp_controller.dart';

class RespPage extends StatelessWidget {
  RespPage({super.key});

  final controller = Get.put(RespPageController());

  @override
  Widget build(BuildContext context) {
    return makePage(
      "Setup Resp Device",
      ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          // Widget _buildChart() {
          //   List<charts.Series<num, num>> seriesList = [
          //     charts.Series<num, num>(
          //       id: 'ecg_rate',
          //       domainFn: (num value, num index) => index,
          //       measureFn: (num value, int index) => value,
          //       data: controller.ecgRate,
          //     ),
          //     charts.Series<num, num>(
          //       id: 'edr',
          //       domainFn: (num value, int index) => index,
          //       measureFn: (num value, int index) => value,
          //       data: controller.edr,
          //     ),
          //   ];
          Card(
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  SizedBox(
                      height: 300,
                      child:
                          GetBuilder<RespPageController>(builder: (controller) {
                        final ecgRate = controller.ecgRate;
                        final List<charts.Series<double, int>> data = [];
                        data.add(charts.Series<double, int>(
                          id: 'ecg_rate',
                          domainFn: (double datum, int? index) => index ?? 0,
                          measureFn: (double datum, int? index) => datum,
                          data: ecgRate,
                          colorFn: (_, __) =>
                              const charts.Color(r: 0x12, g: 0xff, b: 0x59),
                        ));
                        return charts.LineChart(
                          data,
                          animate: false,
                          domainAxis: const charts.NumericAxisSpec(
                            viewport:
                                charts.NumericExtents(0, graphBufferLength - 1),
                            renderSpec: charts.NoneRenderSpec(),
                          ),
                          primaryMeasureAxis: const charts.NumericAxisSpec(
                            renderSpec: charts.NoneRenderSpec(),
                            viewport:
                                charts.NumericExtents(lowerLimit, upperLimit),
                          ),
                          // behaviors: [charts.RangeAnnotation(rangeAnnotations)],
                        );
                      }))
                ],
              )),
          Card(
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  SizedBox(
                      height: 300,
                      child:
                          GetBuilder<RespPageController>(builder: (controller) {
                        final edrRate = controller.processResp();
                        print("edrRate: $edrRate");
                        final List<charts.Series<double, int>> data = [];
                        data.add(charts.Series<double, int>(
                          id: 'edr_rate',
                          domainFn: (double datum, int? index) => index ?? 0,
                          measureFn: (double datum, int? index) => datum,
                          data: edrRate,
                          colorFn: (_, __) =>
                              const charts.Color(r: 0x12, g: 0xff, b: 0x59),
                        ));
                        return charts.LineChart(
                          data,
                          animate: false,
                          domainAxis: const charts.NumericAxisSpec(
                            viewport: charts.NumericExtents(0, 300),
                            renderSpec: charts.NoneRenderSpec(),
                          ),
                          primaryMeasureAxis: const charts.NumericAxisSpec(
                            renderSpec: charts.NoneRenderSpec(),
                            viewport: charts.NumericExtents(
                                -1.0, 20.0), // TODO: set in constants.dart
                          ),
                          // behaviors: [charts.RangeAnnotation(rangeAnnotations)],
                        );
                      }))
                ],
              )),
        ],
      ),
      showDrawerButton: false,
    );
  }

  // return charts.LineChart(seriesList);
  // }
}
