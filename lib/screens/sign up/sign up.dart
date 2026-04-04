import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();

}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Future<void> signUpUser() async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Created Successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup Failed")),
      );
    }
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
                // 1. TOP GRADIENT SECTION
                Container(
                  height: screenHeight * 0.35,
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
                            UiHelper.CustomImage(imgurl: "hi.png"),
                            const SizedBox(height: 10),
                            const Text(
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
                      // Floating Lesson Bubbles
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

                // 2. DARK FORM SECTION (The "Sliding Up" Layer)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.28), // This creates the perfect overlap
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            "Sign up",
                            style: TextStyle(
                              color: Color(0xFF00C2FF),
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Create an account here",
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 40),

                          // TextFields
                          UiHelper.CustomTextField(
                            controller: _nameController,
                            text: "Name",
                            tohide: false,
                            textinputtype: TextInputType.name,
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 20),
                          UiHelper.CustomTextField(
                            controller: _phoneController,
                            text: "Phone Number",
                            tohide: false,
                            textinputtype: TextInputType.phone,
                            prefixIcon: Icons.phone_android_outlined,
                          ),
                          const SizedBox(height: 20),
                          UiHelper.CustomTextField(
                            controller: _emailController,
                            text: "Mail",
                            tohide: false,
                            textinputtype: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline,
                          ),
                          const SizedBox(height: 20),
                          UiHelper.CustomTextField(
                            controller: _passwordController,
                            text: "Passwords",
                            tohide: true,
                            textinputtype: TextInputType.text,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: const Icon(Icons.visibility_outlined, color: Colors.white60),
                          ),

                          const SizedBox(height: 40),

                          // Proceed Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                signUpUser();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C2FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Proceed",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already a member? ", style: TextStyle(color: Colors.white70)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  "Sign in",
                                  style: TextStyle(color: Color(0xFF00C2FF), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // THE LOGO (Fixed Visibility)
                          UiHelper.CustomImage(imgurl: "Cl.png"),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. THE GIRL (Layered on top of everything)
                Positioned(
                  top: screenHeight * 0.08, // Higher up to overlap the blue and dark sections
                  right: -10, // Slightly off-screen for that natural look
                  bottom: 630,
                  child: SizedBox(
                    height: 280, // Larger size to match the reference image
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