import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';
import 'package:skill_swap/screens/Home%20Screens/swapping%20Available.dart';
import 'package:skill_swap/screens/reset/Reset.dart';
import 'package:skill_swap/screens/sign%20up/sign%20up.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool? isEmailValid;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  void validateEmail(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        isEmailValid = null;
        _emailError = null;
      });
      return;
    }
    bool valid = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(value.trim());
    setState(() {
      isEmailValid = valid;
      _emailError = valid ? null : "Please enter a valid email address.";
    });
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
  }

  Future<void> signInUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    _clearErrors();

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = "Email is required.");
      hasError = true;
    } else if (isEmailValid == false) {
      setState(() => _emailError = "Please enter a valid email address.");
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = "Password is required.");
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = "Password must be at least 6 characters.");
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    // ── STEP 1: Check if email exists using dummy password ──
    bool emailExists = false;

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: '________dummy________',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() => _emailError = "No account found with this email.");
        setState(() => _isLoading = false);
        return;
      } else if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-email') {
        // Email exists but dummy password was wrong — expected
        emailExists = true;
      } else if (e.code == 'user-disabled') {
        setState(() => _emailError = "This account has been disabled. Contact support.");
        setState(() => _isLoading = false);
        return;
      } else if (e.code == 'too-many-requests') {
        setState(() => _generalError = "Too many failed attempts. Please try again later.");
        setState(() => _isLoading = false);
        return;
      } else if (e.code == 'network-request-failed') {
        setState(() => _generalError = "No internet connection. Please check your network.");
        setState(() => _isLoading = false);
        return;
      }
    }

    if (!emailExists) {
      setState(() => _emailError = "No account found with this email.");
      setState(() => _isLoading = false);
      return;
    }

    // ── STEP 2: Email exists, now try with real password ──
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final snapshot = await _db.collection('swapListings').limit(1).get();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => snapshot.docs.isNotEmpty
              ? const SwappingAvailable()
              : const HomeScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          setState(() => _passwordError = "Incorrect password. Please try again.");
          break;

        case 'user-disabled':
          setState(() => _emailError = "This account has been disabled. Contact support.");
          break;

        case 'too-many-requests':
          setState(() => _generalError = "Too many failed attempts. Please try again later.");
          break;

        case 'network-request-failed':
          setState(() => _generalError = "No internet connection. Please check your network.");
          break;

        case 'operation-not-allowed':
          setState(() => _generalError = "Email sign-in is not enabled. Contact support.");
          break;

        case 'account-exists-with-different-credential':
          setState(() => _emailError = "An account already exists with a different sign-in method.");
          break;

        case 'requires-recent-login':
          setState(() => _generalError = "Please sign in again to continue.");
          break;

        case 'weak-password':
          setState(() => _passwordError = "Password is too weak. Use at least 6 characters.");
          break;

        case 'expired-action-code':
          setState(() => _generalError = "This link has expired. Please request a new one.");
          break;

        case 'invalid-action-code':
          setState(() => _generalError = "This link is invalid. Please request a new one.");
          break;

        case 'session-cookie-expired':
          setState(() => _generalError = "Your session has expired. Please sign in again.");
          break;

        case 'internal-error':
          setState(() => _generalError = "An internal error occurred. Please try again.");
          break;

        default:
          setState(() => _generalError = e.message ?? "Something went wrong. Please try again.");
      }

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [

                // ── TOP GRADIENT ──
                Container(
                  height: screenHeight * 0.4,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 80,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Hi!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Welcome\nBack!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 90,
                        right: 80,
                        child: SizedBox(
                          height: 140,
                          child: UiHelper.CustomImage(imgurl: "messages.png"),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── FORM ──
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.32),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── TITLE ──
                          const Center(
                            child: Text(
                              "Sign in",
                              style: TextStyle(
                                color: Color(0xFF00C2FF),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── EMAIL FIELD ──
                          UiHelper.CustomTextField(
                            controller: _emailController,
                            text: "Email",
                            tohide: false,
                            textinputtype: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline,
                            onChanged: validateEmail,
                            suffixIcon: isEmailValid == null
                                ? null
                                : Icon(
                              isEmailValid!
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: isEmailValid!
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),

                          // ── EMAIL ERROR ──
                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _emailError!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // ── PASSWORD FIELD ──
                          UiHelper.CustomTextField(
                            controller: _passwordController,
                            text: "Password",
                            tohide: !isPasswordVisible,
                            textinputtype: TextInputType.text,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white60,
                              ),
                              onPressed: () => setState(
                                      () => isPasswordVisible = !isPasswordVisible),
                            ),
                          ),

                          // ── PASSWORD ERROR ──
                          if (_passwordError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _passwordError!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // ── GENERAL ERROR BOX ──
                          if (_generalError != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                // ── FIXED: withOpacity → withValues ──
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  // ── FIXED: withOpacity → withValues ──
                                  color: Colors.redAccent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orangeAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _generalError!,
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ── SIGN IN BUTTON ──
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : signInUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C2FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                                  : const Text(
                                "Proceed",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // ── FORGOT PASSWORD + SIGN UP ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EmailVerificationScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Color(0xFF00C2FF)),
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    "New member? ",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignUpScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Sign up",
                                      style: TextStyle(
                                        color: Color(0xFF00C2FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 100),

                          Center(
                            child: UiHelper.CustomImage(imgurl: "Cl.png"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── HERO IMAGE ──
                Positioned(
                  top: screenHeight * 0.08,
                  right: -10,
                  child: SizedBox(
                    height: 280,
                    child: UiHelper.CustomImage(imgurl: "skill girl.png"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}