import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_tracker_fyp/models/user_model.dart';
import 'package:health_tracker_fyp/screens/profileScreen.dart';

class SignUpController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  RxBool isPasswordHidden = true.obs;
  void setIsPasswordHindden(bool val) {
    isPasswordHidden = val.obs;
    update();
  }

  RxBool isConfirmPasswordHidden = true.obs;
  void setIsConfirmPasswordHidden(bool val) {
    isConfirmPasswordHidden.value = val;
    update();
  }

  /// 🔹 Sign Up + Firestore initial data
  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        "Password",
        "Passwords do not match",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.6),
        colorText: Colors.white,
      );
      return;
    }

    try {
      // 1️⃣ Firebase Auth signup
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      // 2️⃣ UserModel object create karo
      HealthTracker user = HealthTracker(
        uid: uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        createdAt: DateTime.now(),
        age: '',
        gender: '',
        height: '',
        weight: '',
        activityLevel: '',
        healthGoals: '',
      );

      // 3️⃣ Firestore me save karo
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(user.toMap());

      Get.snackbar(
        "Success",
        "Account Created Successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.6),
        colorText: Colors.white,
      );
      Get.offAll(() => const ProfileScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Something went wrong",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.6),
        colorText: Colors.white,
      );
    }
  }

  // /// 🔹 Google Sign-In
  Future<User?> signInWithGoogle() async {
    return null;

    //   try {
    //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    //     if (googleUser == null) return null; // user cancelled

    //     final GoogleSignInAuthentication googleAuth =
    //         await googleUser.authentication;

    //     final credential = GoogleAuthProvider.credential(
    //       accessToken: googleAuth.idToken,
    //       idToken: googleAuth.idToken,
    //     );

    //     final userCredential = await FirebaseAuth.instance.signInWithCredential(
    //       credential,
    //     );

    //     Get.snackbar(
    //       "Success",
    //       "Signed in as ${userCredential.user?.displayName}",
    //       snackPosition: SnackPosition.TOP,
    //       backgroundColor: Colors.green.withOpacity(0.6),
    //       colorText: Colors.white,
    //     );

    //     return userCredential.user;
    //   } catch (e) {
    //     Get.snackbar(
    //       "Google Sign-In Error",
    //       e.toString(),
    //       snackPosition: SnackPosition.TOP,
    //       backgroundColor: Colors.red.withOpacity(0.6),
    //       colorText: Colors.white,
    //     );
    //     return null;
    //   }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
