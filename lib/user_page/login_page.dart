import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigation.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final controller = Get.put(LoginController());
  bool ShowPassword = false;
  TextEditingController _unameController = TextEditingController();
  TextEditingController _pwdController = TextEditingController();
  Function(String) usernameValidator = (String username) {
    if (username.isEmpty) {
      return 'Username empty';
    } else if (username.length < 3) {
      return 'Username short';
    }
    return null;
  };

  @override
  Widget build(BuildContext context) {
    return makePage(
      "Login",
      Form(
        // key: ?key,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: <Widget>[
            const SizedBox(
                height: 20,
              ),
            TextFormField(
                autofocus: true,
                controller: _unameController,
                decoration: InputDecoration(
                  labelText: "UserName",
                  hintText: "UserName",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) {
                  if (v == null) {
                    return "null";
                  }
                  if (v.trim().isEmpty) {
                    return "Please Enter Username";
                  }
                  ;
                  return null;
                }
                // validator: () {
                //   return true;
                // }
                ),
              const SizedBox(
                height: 20,
              ),
            TextFormField(
                autofocus: false,
                controller: _pwdController,
                decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(ShowPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        {
                          ShowPassword = !ShowPassword;
                          (context as Element).markNeedsBuild();
                        }
                        ;
                      },
                    )),
                obscureText: !ShowPassword,
                validator: (v) {
                  if (v == null) {
                    return "null";
                  }
                  if (v.trim().isEmpty) {
                    return "Please Enter Password";
                  }
                  ;
                  if (v.trim().length < 6) {
                    return "Password Too Short";
                  }
                  return null;
                }),
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Column(children: [
                const SizedBox(
                  height: 10,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: ElevatedButton(
                    // color: Theme.of(context).primaryColor,
                    onPressed: () {
                      return controller.onLogin(_unameController.text, _pwdController.text);
                    },
                    // textColor: Colors.white,
                    child: Text("Login"),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: ElevatedButton(
                    // color: Theme.of(context).primaryColor,
                    onPressed: (){
                      Get.toNamed("/register");
                    },
                    // textColor: Colors.white,
                    child: Text("Register"),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      showDrawerButton: false, 
    );
  }
  
}
