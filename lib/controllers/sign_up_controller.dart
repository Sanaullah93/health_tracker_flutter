import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_tracker_fyp/models/user_model.dart';
import 'package:health_tracker_fyp/screens/authentication/login_Screen.dart';
import 'package:health_tracker_fyp/screens/main_navigation_screen.dart';

class SignUpController extends GetxController {
  // Text Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  // Additional Fields
  RxString gender = 'Male'.obs;
  RxString activityLevel = 'Moderate'.obs;
  RxString healthGoals = 'Weight Loss'.obs;

  // Form Key
  final formKey = GlobalKey<FormState>();

  // Loading States
  RxBool isLoading = false.obs;
  RxBool isGoogleLoading = false.obs;
  RxBool agreeToTerms = false.obs;

  // Password Visibility
  RxBool isPasswordHidden = true.obs;
  RxBool isConfirmPasswordHidden = true.obs;

  // Google SignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Validation Patterns
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$',
  );
  final RegExp nameRegex = RegExp(r'^[a-zA-Z ]+$');

  // Toggle Password Visibility
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  // Validate Email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Validate Password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must contain letters and numbers';
    }
    return null;
  }

  // Validate Name
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (!nameRegex.hasMatch(value)) {
      return 'Enter a valid name (letters only)';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Validate Confirm Password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Validate Age
  String? validateAge(String? value) {
    if (value != null && value.isNotEmpty) {
      try {
        int age = int.parse(value);
        if (age < 1 || age > 120) {
          return 'Enter a valid age (1-120)';
        }
      } catch (e) {
        return 'Enter a valid number';
      }
    }
    return null;
  }

  // 🔹 Check if email exists in Firestore
  Future<bool> checkEmailExists(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }

  // 🔹 EMAIL/PASSWORD SIGN UP - IMPROVED
  Future<void> signUp() async {
    print('=== SIGN UP STARTED ===');

    try {
      // Basic validation
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        Get.snackbar('Error', 'Please fill all fields');
        return;
      }

      isLoading.value = true;

      // Debug prints
      print('1. FirebaseAuth instance: ${FirebaseAuth.instance}');
      print('2. Email: ${emailController.text.trim()}');
      print('3. Password length: ${passwordController.text.length}');

      // Create user - SIMPLE VERSION
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
        print('4. UserCredential created successfully');
      } catch (firebaseError) {
        print('Firebase Auth Error: $firebaseError');
        rethrow;
      }

      // Check user
      if (userCredential.user == null) {
        print('5. ERROR: userCredential.user is null!');
        throw Exception('User creation failed - user is null');
      }

      print('6. User UID: ${userCredential.user!.uid}');

      // Simple success
      Get.snackbar(
        'Success',
        'Account created!',
        backgroundColor: Colors.green,
      );

      // Navigate to login
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      print('=== SIGN UP ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: ${e.toString()}');

      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
      print('=== SIGN UP COMPLETED ===');
    }
  }

  // 🔹 GOOGLE SIGN IN - PROPER IMPLEMENTATION
  Future<void> signInWithGoogle() async {
    isGoogleLoading.value = true;

    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        barrierDismissible: false,
      );

      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Get.back();
        return; // User cancelled
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // New user - create full profile
          final newUser = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            photoURL: user.photoURL,
            signInMethod: 'google',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isEmailVerified: user.emailVerified,
            lastLogin: DateTime.now(),
            age: '',
            gender: 'Male',
            height: '',
            weight: '',
            activityLevel: 'Moderate',
            healthGoals: 'Weight Loss',
            phone: '',
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
        } else {
          // Existing user - update last login and photo
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'lastLogin': DateTime.now(),
                'updatedAt': DateTime.now(),
                'photoURL': user.photoURL,
              });
        }

        Get.back(); // Close loading dialog

        // Success animation
        Get.showSnackbar(
          GetSnackBar(
            title: "Welcome! 👋",
            message: "Signed in as ${user.displayName ?? 'User'}",
            backgroundColor: Colors.green,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.BOTTOM,
            borderRadius: 8,
            margin: const EdgeInsets.all(20),
          ),
        );

        // Navigate after delay
        await Future.delayed(const Duration(milliseconds: 1500));
        Get.offAll(() => const MainNavigationScreen());
      }
    } on FirebaseAuthException catch (e) {
      Get.back();

      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = "Account exists with different sign-in method.";
          break;
        case 'invalid-credential':
          errorMessage = "Invalid credentials. Please try again.";
          break;
        case 'operation-not-allowed':
          errorMessage = "Google sign-in is not enabled.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled.";
          break;
        case 'user-not-found':
          errorMessage = "Account not found.";
          break;
        case 'wrong-password':
          errorMessage = "Invalid password.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your connection.";
          break;
        default:
          errorMessage = e.message ?? "Google sign-in failed.";
      }

      Get.snackbar(
        "Google Sign-In Failed",
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();

      // Handle Google SignIn specific errors
      if (e is FirebaseAuthException) {
        Get.snackbar(
          "Authentication Error",
          e.message ?? "Authentication failed",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to sign in with Google. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // 🔹 RESET FORM
  void resetForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    phoneController.clear();
    ageController.clear();
    gender.value = 'Male';
    activityLevel.value = 'Moderate';
    healthGoals.value = 'Weight Loss';
    agreeToTerms.value = false;
    formKey.currentState?.reset();
  }

  // 🔹 LOGOUT FROM GOOGLE
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Sign out error: $e");
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    ageController.dispose();
    super.onClose();
  }
}
