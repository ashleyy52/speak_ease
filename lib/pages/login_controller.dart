import 'package:flutter/material.dart';

class LoginController {
  String username = 'luha';
  String password = 'luha123';
  final TextEditingController idController = TextEditingController();
  final TextEditingController passController = TextEditingController();
}

final LoginController loginController = LoginController();