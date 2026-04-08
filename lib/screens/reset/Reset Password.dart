import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/Sign in/sign in.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool showConfirm = false;

  Future<void> resetPassword() async {
    final String password = passwordController.text.trim();
    final String confirm = confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }

    if (password.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }

    if (password != confirm) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => loading = true);

    try {
      // Send a fresh Firebase password reset email to the verified email.
      // After OTP verification, we use Firebase's built-in sendPasswordResetEmail
      // (without ActionCodeSettings — uses default Firebase hosted link).
      // For a fully custom flow (no Firebase link), use Admin SDK / Cloud Function.
      //
      // Here we use the simplest approach compatible with the existing Firebase setup:
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);

      if (!mounted) return;

      if (!mounted) return; // ✅ FIXED

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A password reset link has been sent to your email. '
            'Click the link to complete the reset.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );

    } on FirebaseAuthException catch(e){

      setState(() {
        loading = false; // ✅ FIXED — only stops loading on error
      });

      if (!mounted) return; // ✅ FIXED

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Reset failed")),
      );
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2FF).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          size: 46,
                          color: Color(0xFF00C2FF),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Create New Password',
                        style: TextStyle(
                          color: Color(0xFF00C2FF),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Your identity has been verified.\nSet your new password below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // New Password Field
                      UiHelper.CustomTextField(
                        controller: passwordController,
                        text: 'New Password',
                        tohide: !showPassword,
                        textinputtype: TextInputType.text,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => showPassword = !showPassword),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Confirm Password Field
                      UiHelper.CustomTextField(
                        controller: confirmController,
                        text: 'Confirm Password',
                        tohide: !showConfirm,
                        textinputtype: TextInputType.text,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => showConfirm = !showConfirm),
                        ),
                      ),

                      const SizedBox(height: 36),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C2FF),
                            disabledBackgroundColor:
                                const Color(0xFF00C2FF).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom logo
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                height: 45,
                child: UiHelper.CustomImage(imgurl: 'Cl.png'),
            const SizedBox(height: 30),

            UiHelper.CustomTextField(
              controller: passwordController,
              text: "New Password",
              tohide: true,
              textinputtype: TextInputType.text,
              prefixIcon: Icons.lock_outline,
            ),

            const SizedBox(height: 20),

            UiHelper.CustomTextField(
              controller: confirmController,
              text: "Confirm Password",
              tohide: true,
              textinputtype: TextInputType.text,
              prefixIcon: Icons.lock_outline,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: loading ? null : resetPassword,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C2FF),
                ),

                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Reset Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}