import 'package:flutter/material.dart';
import 'package:tracking_app/app_navigation.dart';
import 'package:tracking_app/pages/login.dart';
import 'package:tracking_app/pages/register.dart';
import '../helper_methods/authentication/auth_helpers.dart';

class CredentialHomeScreen extends StatefulWidget {
  final AuthHelpers authHelpers;

  const CredentialHomeScreen({super.key, required this.authHelpers});

  @override
  State<CredentialHomeScreen> createState() => _CredentialHomeScreenState();
}

class _CredentialHomeScreenState extends State<CredentialHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScreen(key: const Key('credentialAppScreen'), pages: [
      LoginPage(authHelpers: widget.authHelpers),
      const RegisterPage()
    ], titles: const [
      "Login",
      "Register"
    ], navBarItems: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.login_rounded),
        label: "Login",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.app_registration_rounded),
        label: 'Register',
      )
    ], actions: const [],);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
