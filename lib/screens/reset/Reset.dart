import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';

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

      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: "https://skillswapapp.page.link/reset",
        handleCodeInApp: true,
        androidPackageName: "com.example.skill_swap",
        androidInstallApp: true,
        androidMinimumVersion: "21",
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      setState(() {
        emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent to your email"),
          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseAuthException catch(e){

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error sending email")),
      );

    }

    setState(() {
      loading = false;
    });
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

            /// CENTER CONTENT
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

                    const SizedBox(height: 25),

                    if(emailSent)
                      const Text(
                        "Check your email and click the reset link.",
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),

                  ],
                ),
              ),
            ),

            /// BOTTOM LOGO
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