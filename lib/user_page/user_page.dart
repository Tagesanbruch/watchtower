import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigation.dart';
import 'user_controller.dart';

class UserPage extends StatelessWidget {
  UserPage({super.key});
  final controller = Get.put(UserController());

  List menuTitles = [
    'reserve',
    'My Records',
    'test2',
    'test3',
    'test4',
    'Settings',
  ];

  List menuIcons = [
    Icons.man,
    Icons.health_and_safety_rounded,
    Icons.print,
    Icons.error,
    Icons.phone,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return makePage(
      "User Page",
      ListView.separated(
          itemBuilder: (context, i) {
            if (i == 0) {
              return SizedBox(
                  // color: Colors.white,
                  height: 150.0,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 90.0,
                          height: 90.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueGrey,
                              width: 2.0,
                            ),
                            image: const DecorationImage(
                              // TODO: change avatar_default image
                              image: AssetImage("assets/avatar_default.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Get.toNamed("/login");
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        const Text(
                          'Sign in',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ));
            }
            final name = menuTitles[i];
            final icon = menuIcons[i];
            final theme = Theme.of(context);
            return ListTile(
              onTap: () {
                if (i == 1) {
                  Get.toNamed("/record");
                  return;
                }
                if (i == 5) {
                  Get.toNamed("/settings");
                  return;
                }
                // return null;
              },
              title: Text(name ?? 'N/A'),
              leading: Icon(icon),
              trailing: const Icon(Icons.arrow_forward_ios),
            );
          },
          separatorBuilder: (context, i) {
            return const Divider();
          },
          itemCount: menuTitles.length),
    );
  }
}
