import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      Get.snackbar(
        "Success",
        "Password reset link sent to $email",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.6),
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Failed to send reset email",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.6),
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();

    super.onClose();
  }
}
