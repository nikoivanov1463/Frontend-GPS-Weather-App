import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String body;
  final List<Widget> actions;

  const CustomAlertDialog(this.title, this.body, this.actions, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        content: Text(body, style: Theme.of(context).textTheme.bodyMedium),
        actions: actions);
  }
}
