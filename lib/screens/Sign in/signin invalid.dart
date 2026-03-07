import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';

class SignInvalidScreen extends StatefulWidget {
  const SignInvalidScreen({Key? key}) : super(key: key);

  @override
  State<SignInvalidScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInvalidScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark blue background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section with Illustration
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00C2FF), Color(0xFF6B8AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 60,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("Hi!", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Welcome\nBack!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chat bubble messages
                  Positioned(
                    top: 90,
                    bottom: 10,
                    left: 170,
                    right: 30,
                    child: UiHelper.CustomImage(imgurl: "messages.png"),
                  ),
                  // The girl illustration
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: UiHelper.CustomImage(imgurl: "skill girl.png"),
                  ),
                ],
              ),
            ),

            // Bottom Section (Sign In Form)
            Padding(
              padding: const EdgeInsets.all(24.0),
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
                  const SizedBox(height: 8),

                  // ERROR MESSAGE FROM SCREENSHOT
                  const Text(
                    "Invalid email or password",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email Field (with Red Error Icon)
                  UiHelper.CustomTextField(
                    controller: _emailController,
                    text: "user@gmail.com",
                    tohide: false,
                    textinputtype: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    suffixIcon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                  ),

                  const SizedBox(height: 25),

                  // Password Field
                  UiHelper.CustomTextField(
                    controller: _passwordController,
                    text: "Password",
                    tohide: true,
                    textinputtype: TextInputType.text,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: const Icon(Icons.visibility_outlined, color: Colors.white24, size: 20),
                  ),

                  const SizedBox(height: 50),

                  // Proceed Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C2FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Proceed",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Color(0xFF00C2FF))
                        ),
                      ),
                      Row(
                        children: [
                          const Text("New member? ", style: TextStyle(color: Colors.white70)),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                                "Sign up",
                                style: TextStyle(
                                    color: Color(0xFF00C2FF),
                                    fontWeight: FontWeight.bold
                                )
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  UiHelper.CustomImage(imgurl: "Cl.png"),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}