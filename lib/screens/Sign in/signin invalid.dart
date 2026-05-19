import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';

class SignInvalidScreen extends StatefulWidget {
  SignInvalidScreen({Key? key}) : super(key: key);

  @override
  State<SignInvalidScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInvalidScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dark blue background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section with Illustration
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
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
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("Hi!", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Welcome\nBack!",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    "Sign in",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // ERROR MESSAGE FROM SCREENSHOT
                  Text(
                    "Invalid email or password",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Email Field (with Red Error Icon)
                  UiHelper.CustomTextField(context: context,
                    controller: _emailController,
                    text: "user@gmail.com",
                    tohide: false,
                    textinputtype: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    suffixIcon: Icon(Icons.cancel, color: Colors.red, size: 20),
                  ),

                  SizedBox(height: 25),

                  // Password Field
                  UiHelper.CustomTextField(context: context,
                    controller: _passwordController,
                    text: "Password",
                    tohide: true,
                    textinputtype: TextInputType.text,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: Icon(Icons.visibility_outlined, color: Theme.of(context).colorScheme.outlineVariant, size: 20),
                  ),

                  SizedBox(height: 50),

                  // Proceed Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Proceed",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                            "Forgot Password?",
                            style: TextStyle(color: Theme.of(context).colorScheme.primary)
                        ),
                      ),
                      Row(
                        children: [
                          Text("New member? ", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                                "Sign up",
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold
                                )
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 60),
                  UiHelper.CustomImage(imgurl: "Cl.png"),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}