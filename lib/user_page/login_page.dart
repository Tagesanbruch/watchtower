import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigation.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return makePage(
        "Login",
        Container(
          child: Text("aaa"),
        ),
        floatingActionButton: Obx(() => FloatingActionButton(
              onPressed: null,
                  // ? () async {
                  //     if (controller.discovering.value) {
                  //       await controller.stopDiscovery();
                  //     } else {
                  //       await controller.startDiscovery();
                  //     }
                  //   }
                  // : null,
              tooltip: 'Scan',
              child: Icon(
                  controller.discovering.value ? Icons.stop : Icons.refresh),
            )));
  }
}
