import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  RxBool isPasswordHidden = true.obs;

  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.toString(),
            password: passwordController.text.toString(),
          );

      String uid = userCredential.user!.uid;

      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      var data = snapshot.data();
      print("User name: ${data?['name']}");
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Login Failed",
        e.message ?? "Something went wrong",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.6),
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}
