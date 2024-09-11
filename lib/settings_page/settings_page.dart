import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigation.dart';
import 'settings_controller.dart';

class ButtonX extends GetxController {
  RxInt selectedIndex = 0.obs;
  final options = ['原始ADC数据', '原始ADC数据 / 2', '原始ADC数据 / 4', 'PT高通滤波', 'PT低通滤波'];

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
  };

  @override
  Widget build(BuildContext context) {
    return makePage(
      "Settings Page",
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
                          height: 50, // Set your desired height here
                          child: const ListTile(
                            title: Text('心电图绘制数据选择'),
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
                            const Text('心电数据类型：'),
                            const SizedBox(
                              width: 20,
                            ),
                            DropdownButton<int>(
                              value: bx.selectedIndex.value,
                              items: bx.options.map((String value) {
                                return DropdownMenuItem<int>(
                                  value: bx.options.indexOf(value),
                                  child: Text(value),
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
                          height: 50, // Set your desired height here
                          child: const ListTile(
                            title: Text('心率警报范围'),
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
                          height: 50, // Set your desired height here
                          child: const ListTile(
                            title: Text('控制指令'),
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
                                  hintText: '请输入命令',
                                  border: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  contentPadding: const EdgeInsets.all(10.0),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                // Handle send button press
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
                          height: 50, // Set your desired height here
                          child: const ListTile(
                            title: Text('选项'),
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
                  ],
                )),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                child: const Text('Apply', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  var buttonX = Get.find<ButtonX>();
                  controller.sendCommand(buttonX.selectedIndex.value);
                },
              ),
              TextButton(
                child: const Text('Reset', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  // Handle reset button press
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
