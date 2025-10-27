import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sign_up_controller.dart' show SignUpController;

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextEditingController controller;
  final bool isPassword;
  final bool? isPasswordHidden;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.validator,
    required this.controller,
    this.isPassword = false,
    this.isPasswordHidden,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final SignUpController controllerSignup = Get.put(SignUpController());
  bool ishidden = false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? ishidden : false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  widget.isPassword
                      ? ishidden
                            ? Icons.visibility_off
                            : Icons.visibility
                      : null,
                ),
                onPressed: () => setState(() {
                  ishidden = !ishidden;
                }),
              )
            : Icon(widget.icon),
      ),
      validator: widget.validator,
    );
  }
}
