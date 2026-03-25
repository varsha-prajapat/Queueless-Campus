import 'package:flutter/material.dart';
import "./app_status_message.dart";

class AppSuccessMessage extends StatelessWidget {
  final String message;

  const AppSuccessMessage(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppStatusMessage(
      message: message,
      type: StatusType.success,
    );
  }
}
