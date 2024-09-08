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
    'test5',
  ];

  List menuIcons = [
    Icons.man,
    Icons.health_and_safety_rounded,
    Icons.print,
    Icons.error,
    Icons.phone,
    Icons.send,
  ];

  @override
  Widget build(BuildContext context) {
    return makePage(
        "User Page",
        ListView.separated(
            itemBuilder: (context, i){
              if(i == 0){
                return Container(
                  // color: Colors.white,
                  height: 150.0,
                  
                  child: Center(
                    
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          child: InkWell(
                            onTap:(){
                              Get.toNamed("/login");
                            },
                          ),
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
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          'Sign in',
                          style: TextStyle(color: Colors.black),
                        ),
                        
                      ],
                    ),
                  )                  
                );
              }
              final name = menuTitles[i];
              final icon = menuIcons[i];
              final theme = Theme.of(context);
              return ListTile(
                onTap: (){
                  if (i == 1){
                    Get.toNamed("/record");
                    return;
                  }
                  // return null;
                },
                title: Text(name ?? 'N/A'),
                leading: Icon(icon),
                trailing: Icon(Icons.arrow_forward_ios),
              );
            },
            separatorBuilder: (context, i){
              return Divider();
            },
            itemCount: menuTitles.length
         ),
         
        // floatingActionButton: Obx(() => FloatingActionButton(
        //       onPressed: null,
        //           // ? () async {
        //           //     if (controller.discovering.value) {
        //           //       await controller.stopDiscovery();
        //           //     } else {
        //           //       await controller.startDiscovery();
        //           //     }
        //           //   }
        //           // : null,
        //       tooltip: 'Scan',
        //       child: Icon(
        //           controller.discovering.value ? Icons.stop : Icons.refresh),
        //     ))
            );
  }
}
