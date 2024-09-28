import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

import '../navigation.dart';
// import 'package:watchtower/translations/translations.dart';
// import 'package:watchtower/generated/l10n.dart';
// import 'package:watchtower/generated/intl/messages_all.dart';
import 'settings_controller.dart';

class ButtonX extends GetxController {
  RxInt selectedIndex = 0.obs;
  final options = [
    "Raw ADC Data",
    "Raw ADC Data / 2",
    "Raw ADC Data / 4",
    "PT High Pass Filter",
    "PT Low Pass Filter"
  ];

  void select(int index) => selectedIndex.value = index;
}

class SliderX extends GetxController {
  Rx<RangeValues> rangeValues = Rx<RangeValues>(const RangeValues(0.3, 0.7));

  void valuesUpdate(RangeValues values) => rangeValues.value = values;
}

class TextFieldX extends GetxController {
  Rx<TextEditingController> controller = TextEditingController().obs;

  void updateText(String newText) => controller.value.text = newText;
}

class CheckboxX extends GetxController {
  RxBool isChecked = false.obs;

  void toggle() => isChecked.value = !isChecked.value;
}

class PanelController extends GetxController {
  RxBool isExpanded = false.obs;

  void toggle() => isExpanded.value = !isExpanded.value;
}

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});
  final controller = Get.put(SettingsController());
  final Map<int, PanelController> panelControllers = {
    0: PanelController(),
    1: PanelController(),
    2: PanelController(),
    3: PanelController(),
    4: PanelController(),
  };

  @override
  Widget build(BuildContext context) {
    return makePage(
      "Settings Page".tr,
      Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
            child: Obx(() => ExpansionPanelList(
                  expansionCallback: (int index, bool isExpanded) {
                    panelControllers[index]?.toggle();
                  },
                  children: [
                    ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return SizedBox(
                          height: 50,
                          child: ListTile(
                            title: Text("ECG Data Selection".tr),
                          ),
                        );
                      },
                      body: Obx(() {
                        ButtonX bx = Get.put(ButtonX());
                        return Row(
                          children: [
                            const SizedBox(
                              width: 20,
                            ),
                            Text("ECG Data Type".tr),
                            const SizedBox(
                              width: 20,
                            ),
                            DropdownButton<int>(
                              value: bx.selectedIndex.value,
                              items: bx.options.map((String value) {
                                return DropdownMenuItem<int>(
                                  value: bx.options.indexOf(value),
                                  child: Text(value.tr),
                                );
                              }).toList(),
                              onChanged: (newValue) => bx.select(newValue!),
                            ),
                          ],
                        );
                      }),
                      isExpanded:
                          panelControllers[0]?.isExpanded.value ?? false,
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return SizedBox(
                          height: 50,
                          child: ListTile(
                            title: Text("Heart Rate Alert Range".tr),
                          ),
                        );
                      },
                      body: Obx(() {
                        SliderX sx = Get.put(SliderX());
                        return Row(
                          children: [
                            const SizedBox(
                              width: 20,
                            ),
                            Text((sx.rangeValues.value.start * 100)
                                .round()
                                .toString()),
                            Expanded(
                              child: RangeSlider(
                                values: sx.rangeValues.value,
                                onChanged: (RangeValues values) =>
                                    sx.valuesUpdate(values),
                              ),
                            ),
                            Text((sx.rangeValues.value.end * 100)
                                .round()
                                .toString()),
                            const SizedBox(
                              width: 20,
                            ),
                          ],
                        );
                      }),
                      isExpanded:
                          panelControllers[1]?.isExpanded.value ?? false,
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return SizedBox(
                          height: 50,
                          child: ListTile(
                            title: Text("Control Command".tr),
                          ),
                        );
                      },
                      body: Obx(() {
                        TextFieldX tx = Get.put(TextFieldX());
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: tx.controller.value,
                                onChanged: (newText) => tx.updateText(newText),
                                decoration: InputDecoration(
                                  hintText: "Please Enter Command".tr,
                                  border: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  contentPadding: const EdgeInsets.all(10.0),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                var textFieldX = Get.find<TextFieldX>();
                                var text = textFieldX.controller.value.text;
                                controller.sendCommand(text);
                              },
                            ),
                          ],
                        );
                      }),
                      isExpanded:
                          panelControllers[2]?.isExpanded.value ?? false,
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return SizedBox(
                          height: 50,
                          child: ListTile(
                            title: Text("Options".tr),
                          ),
                        );
                      },
                      body: Obx(() {
                        CheckboxX cx = Get.put(CheckboxX());
                        return CheckboxListTile(
                          title: const Text('选项1'),
                          value: cx.isChecked.value,
                          onChanged: (bool? value) => cx.toggle(),
                        );
                      }),
                      isExpanded:
                          panelControllers[3]?.isExpanded.value ?? false,
                    ),

                    /// Language Selection
                    // ExpansionPanel(
                    //   canTapOnHeader: true,
                    //   headerBuilder: (BuildContext context, bool isExpanded) {
                    //     return SizedBox(
                    //       height: 50,
                    //       child: ListTile(
                    //         title: Text("Language".tr),
                    //       ),
                    //     );
                    //   },
                    //   body: Column(
                    //     children: [
                    //       ListTile(
                    //         title: Text("English"),
                    //         onTap: () {
                    //           Get.updateLocale(const Locale('en', 'US'));
                    //         },
                    //       ),
                    //       ListTile(
                    //         title: Text("中文"),
                    //         onTap: () {
                    //           Get.updateLocale(const Locale('zh', 'CN'));
                    //         },
                    //       ),
                    //     ],
                    //   ),
                    //   isExpanded: false,
                    // )
                    ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return SizedBox(
                          height: 50,
                          child: ListTile(
                            title: Text("Language".tr),
                          ),
                        );
                      },
                      body: Column(
                        children: [
                          ListTile(
                            title: Text("English"),
                            onTap: () {
                              Get.updateLocale(const Locale('en', 'US'));
                            },
                          ),
                          ListTile(
                            title: Text("中文"),
                            onTap: () {
                              Get.updateLocale(const Locale('zh', 'CN'));
                            },
                          ),
                        ],
                      ),
                      // body:
                      // Obx(() {
                      //   return Column(
                      //     children: [
                      //       ListTile(
                      //         title: Text("English"),
                      //         onTap: () {
                      //           Get.updateLocale(const Locale('en', 'US'));
                      //         },
                      //       ),
                      //       ListTile(
                      //         title: Text("中文"),
                      //         onTap: () {
                      //           Get.updateLocale(const Locale('zh', 'CN'));
                      //         },
                      //       ),
                      //     ],
                      //   );
                      // }),
                      isExpanded:
                          panelControllers[4]?.isExpanded.value ?? false,
                    ),
                  ],
                )),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                child: Text("Apply".tr,
                    style: const TextStyle(color: Colors.blue)),
                onPressed: () {
                  var buttonX = Get.find<ButtonX>();
                  controller.setECGMode(buttonX.selectedIndex.value);
                },
              ),
              TextButton(
                child: Text("Reset".tr,
                    style: const TextStyle(color: Colors.blue)),
                onPressed: () {
                  null; // Reset all settings
                },
              ),
            ],
          ),
        ],
      ),
      showDrawerButton: false,
    );
  }
}
