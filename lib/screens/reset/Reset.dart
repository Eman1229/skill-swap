import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/Sign in/sign in.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {

  final TextEditingController emailController = TextEditingController();
  bool loading = false;
  bool emailSent = false;

  Future<void> sendResetEmail() async {

    String email = emailController.text.trim();

    if(email.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      setState(() {
        emailSent = true;
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent to your email"),
          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseAuthException catch(e){
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error sending email")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),

        child: Column(
          children: [

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Text(
                      "Reset Password",
                      style: TextStyle(
                        color: Color(0xFF00C2FF),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Show email field only if email not sent yet
                    if(!emailSent) ...[

                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : sendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C2FF),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Send Reset Link"),
                        ),
                      ),

                    ],

                    // ✅ Show instructions + button after email is sent
                    if(emailSent) ...[

                      const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF00C2FF),
                        size: 80,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Email Sent!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Step 1: Open your email\nStep 2: Click the reset link\nStep 3: Reset your password in the browser\nStep 4: Come back and press the button below",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      // This button takes user to SignIn after resetting in browser
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                                  (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "I've Reset My Password → Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    ],

                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                height: 45,
                child: UiHelper.CustomImage(imgurl: "Cl.png"),
              ),
            )

          ],
        ),
      ),
    );
  }
}