import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';
import 'package:skill_swap/screens/Home%20Screens/Swapping%20Available.dart';
import 'package:skill_swap/screens/reset/Reset.dart';
import 'package:skill_swap/screens/sign%20up/sign%20up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

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

  void validateEmail(String value) {
    if (!value.contains("@") || !value.contains(".")) {
      setState(() => isEmailValid = null);
      return;
    }
    bool valid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+")
        .hasMatch(value);
    setState(() => isEmailValid = valid);
  }

  Future<void> signInUser() async {
    // Basic validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Sign in with Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Step 2: Check Firestore for any swap listings
      final snapshot =
      await _db.collection('swapListings').limit(1).get();

      if (!mounted) return;

      // Step 3: Route based on whether listings exist
      if (snapshot.docs.isNotEmpty) {
        // Listings exist → go to SwappingAvailable (3rd screen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SwappingAvailable(),
          ),
        );
      } else {
        // No listings → go to HomeScreen (2nd screen / empty state)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Login failed. Please try again.";
      if (e.code == 'wrong-password') {
        message = "Wrong password entered.";
      } else if (e.code == 'user-not-found') {
        message = "No account found with this email.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address.";
      } else if (e.code == 'too-many-requests') {
        message = "Too many attempts. Please try again later.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
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
                // ── Top Gradient ──────────────────────────────────
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
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Hi!",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Welcome\nBack!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
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
                          child:
                          UiHelper.CustomImage(imgurl: "messages.png"),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form Section ──────────────────────────────────
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
                        children: [
                          const Text(
                            "Sign in",
                            style: TextStyle(
                              color: Color(0xFF00C2FF),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // EMAIL FIELD
                          UiHelper.CustomTextField(
                            controller: _emailController,
                            text: "user@gmail.com",
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

                          const SizedBox(height: 25),

                          // PASSWORD FIELD
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
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 40),

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed:
                              _isLoading ? null : signInUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF00C2FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
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

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EmailVerificationScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                      color: Color(0xFF00C2FF)),
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    "New member? ",
                                    style:
                                    TextStyle(color: Colors.white70),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const SignUpScreen(),
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

                          const SizedBox(height: 140),

                          SizedBox(
                            height: 45,
                            child:
                            UiHelper.CustomImage(imgurl: "Cl.png"),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Girl Image ────────────────────────────────────
                Positioned(
                  top: screenHeight * 0.08,
                  right: -10,
                  child: SizedBox(
                    height: 280,
                    child: UiHelper.CustomImage(
                        imgurl: "skill girl.png"),
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
