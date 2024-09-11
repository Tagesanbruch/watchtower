import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigation.dart';
import 'register_controller.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});
  final controller = Get.put(RegisterController());
  final TextEditingController _unameController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool ShowPassword = false;

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
      "Register",
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
                decoration: const InputDecoration(
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
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(ShowPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        {
                          ShowPassword = !ShowPassword;
                          (context as Element).markNeedsBuild();
                        }
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
                  if (v.trim().length < 6) {
                    return "Password Too Short";
                  }
                  return null;
                }),
                const SizedBox(
                height: 20,
              ),
            TextFormField(
                autofocus: true,
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  hintText: "Email Address",
                  prefixIcon: Icon(Icons.mail),
                ),
                validator: (v) {
                  if (v == null) {
                    return "null";
                  }
                  if (v.trim().isEmpty) {
                    return "Please Enter Email Address";
                  }
                  return null;
                }
                // validator: () {
                //   return true;
                // }
                ),
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Column(children: [
                const SizedBox(
                  height: 10,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints.expand(height: 55.0),
                  child: ElevatedButton(
                    // color: Theme.of(context).primaryColor,
                    onPressed: (){
                      return controller.onRegister(_unameController.text, _pwdController.text);
                    },
                    // textColor: Colors.white,
                    child: const Text("Register"),
                  ),
                ),
                // const SizedBox(
                //   height: 20,
                // ),
                // ConstrainedBox(
                //   constraints: BoxConstraints.expand(height: 55.0),
                //   child: ElevatedButton(
                //     // color: Theme.of(context).primaryColor,
                //     onPressed: null,
                //     // textColor: Colors.white,
                //     child: Text("Register"),
                //   ),
                // ),
              ]),
            ),
          ],
        ),
      ),
      showDrawerButton: false, 
    );
  }

  
}
