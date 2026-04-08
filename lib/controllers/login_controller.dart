import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_tracker_fyp/screens/main_navigation_screen.dart';

class LoginController extends GetxController {
  // Text Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form Key
  final formKey = GlobalKey<FormState>();

  // Loading States
  RxBool isLoading = false.obs;
  RxBool rememberMe = false.obs;

  // Password Visibility
  RxBool isPasswordHidden = true.obs;

  // Toggle Password Visibility
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  RxBool isGoogleLoading = false.obs;

  Future<void> signInWithGoogle() async {
    try {
      isGoogleLoading(true);

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // Get the signed-in user
      final User? user = userCredential.user;

      if (user != null) {
        // Success - navigate to main screen
        Get.offAll(() => const MainNavigationScreen());
        Get.snackbar(
          "Welcome ${user.displayName ?? 'User'}!",
          "Google sign-in successful",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Google Sign In Error: $e");
      Get.snackbar(
        "Google Sign In Failed",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isGoogleLoading(false);
    }
  }

  // 🔹 EMAIL/PASSWORD LOGIN
  Future<void> login() async {
    // Validate Form
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      // Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Success
      Get.snackbar(
        "Success ✅",
        "Login Successful",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to Home
      Get.offAll(() => const MainNavigationScreen());
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = e.message ?? "Login failed";
      }

      Get.snackbar(
        "Login Failed ❌",
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error ❌",
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
