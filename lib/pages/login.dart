import 'package:flutter/material.dart';
import 'package:tracking_app/helper_methods/authentication/auth_helpers.dart';
import 'package:tracking_app/helper_methods/authentication/auth_service.dart';

class LoginPage extends StatefulWidget {
  final AuthService loginDio = AuthService();
  final AuthHelpers authHelpers;

  LoginPage({super.key, required this.authHelpers});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController changeEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initSessionCheck();
  }

  Future<void> initSessionCheck() async {
    final result = await widget.authHelpers.sessionCheck();

    if (result != null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    }

    return;
  }

  void changePassword() async {
    if (context.mounted) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                icon: const Icon(Icons.info_rounded,
                    color: Colors.blueAccent, size: 30.00),
                content: SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: changeEmailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a email';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                    ),
                  ),
                ),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Close")),
                  ElevatedButton(
                      onPressed: () async {
                        await widget.loginDio.changePassword(
                            context, changeEmailController.text);
                      },
                      child: const Text("Change"))
                ]);
          });
    }
  }

  void handleLogin() async {
    final result = await widget.loginDio.login(
        context,
        emailController.text.split('@').first,
        emailController.text,
        passwordController.text);

    final data = result[0];

    Map<int, String> formattedData = {};

    int count = 0;

    result.forEach((item) {
      formattedData[count] = item["defaultMessage"].toString();
      count++;
    });

    if (result != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Login Response"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var entry in formattedData.entries)
                  Text(
                    entry.value.trim(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Form(
                  key: formKey,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 4),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const Icon(
                            Icons.login,
                            size: 128,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: 200,
                          child: TextFormField(
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a email';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Email',
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: 200,
                          child: TextFormField(
                            controller: passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              return null;
                            },
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Password',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            handleLogin();
                          },
                          child: const Text("Login"),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            changePassword();
                          },
                          child: const Text("Change password"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
